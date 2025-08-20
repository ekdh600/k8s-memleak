#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/resource.h>
#include <signal.h>
#include <time.h>
#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#include "fake_metrics.h"

#define CHUNK_SIZE (1024 * 1024)  // 1MB
#define MAX_CHUNKS 2000
#define LEAK_INTERVAL 8  // 8초마다 (더 은밀하게)
#define HTTP_PORT 8080
#define MAX_CONNECTIONS 100

// 전역 변수들
void* leaked_chunks[MAX_CHUNKS];
int chunk_count = 0;
int running = 1;
int healthy_responses = 0;
pthread_mutex_t leak_mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_mutex_t stats_mutex = PTHREAD_MUTEX_INITIALIZER;

// 시그널 핸들러
void signal_handler(int sig) {
    printf("\n🛑 시그널 %d 수신, 정리 중...\n", sig);
    running = 0;
}

// 은밀한 메모리 누수 (백그라운드에서)
void* memory_leak_thread(void* arg) {
    printf("🔄 백그라운드 메모리 누수 스레드 시작\n");
    printf("💧 8초마다 1MB씩 은밀하게 누수 발생\n");
    
    time_t start_time = time(NULL);
    
    while (running && chunk_count < MAX_CHUNKS) {
        sleep(LEAK_INTERVAL);
        
        pthread_mutex_lock(&leak_mutex);
        
        // 1MB 메모리 할당 (은밀하게)
        void* chunk = malloc(CHUNK_SIZE);
        if (chunk) {
            // 메모리 초기화 (실제 사용으로 인식)
            memset(chunk, 'x', CHUNK_SIZE);
            leaked_chunks[chunk_count++] = chunk;
            
            time_t current_time = time(NULL);
            int elapsed = (int)(current_time - start_time);
            
            // 로그는 최소화 (은밀하게)
            if (chunk_count % 20 == 0) {  // 20개마다만 로그
                printf("💧 메모리 누수 진행 중... (누적: %d MB, 경과: %d초)\n", 
                       chunk_count, elapsed);
            }
        }
        
        pthread_mutex_unlock(&leak_mutex);
    }
    
    printf("🔄 메모리 누수 스레드 종료\n");
    return NULL;
}

// HTTP 응답 생성 (항상 "정상" 표시)
void generate_healthy_response(int client_socket) {
    struct rusage rusage;
    getrusage(RUSAGE_SELF, &rusage);
    
    // 표면적으로는 정상인 메트릭 생성
    long rss_kb = rusage.ru_maxrss;
    int memory_percent = (rss_kb * 100) / 1000000;  // 1GB 기준 퍼센트
    
    // 메모리 사용량을 "정상" 범위로 표시
    if (memory_percent > 80) memory_percent = 75;  // 80% 초과시 75%로 표시
    
    char response[2048];
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: application/json\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "\r\n"
        "{\n"
        "  \"status\": \"healthy\",\n"
        "  \"timestamp\": \"%s\",\n"
        "  \"metrics\": {\n"
        "    \"memory_usage_percent\": %d,\n"
        "    \"memory_rss_kb\": %ld,\n"
        "    \"total_requests\": %d,\n"
        "    \"healthy_responses\": %d,\n"
        "    \"uptime_seconds\": %ld\n"
        "  },\n"
        "  \"health_checks\": {\n"
        "    \"liveness\": \"passing\",\n"
        "    \"readiness\": \"passing\",\n"
        "    \"memory\": \"normal\",\n"
        "    \"gc\": \"healthy\",\n"
        "    \"response_time\": \"fast\"\n"
        "  },\n"
        "    \"message\": \"서비스가 정상적으로 작동하고 있습니다.\"\n"
        "}",
        "2024-01-20T10:30:00Z",
        memory_percent,
        rss_kb,
        healthy_responses,
        healthy_responses,
        time(NULL)
    );
    
    write(client_socket, response, strlen(response));
}

// HTTP 서버 처리
void* http_server_thread(void* arg) {
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        perror("소켓 생성 실패");
        return NULL;
    }
    
    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(HTTP_PORT);
    
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("HTTP 서버 바인드 실패");
        close(server_socket);
        return NULL;
    }
    
    if (listen(server_socket, MAX_CONNECTIONS) < 0) {
        perror("HTTP 서버 리스닝 실패");
        close(server_socket);
        return NULL;
    }
    
    printf("🌐 HTTP 서버 시작 (포트: %d)\n", HTTP_PORT);
    printf("📊 헬스체크: http://localhost:%d/health\n", HTTP_PORT);
    
    while (running) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket < 0) {
            if (errno != EINTR) {
                perror("HTTP 서버 연결 수락 실패");
            }
            continue;
        }
        
        char buffer[1024];
        int bytes_read = read(client_socket, buffer, sizeof(buffer) - 1);
        if (bytes_read > 0) {
            buffer[bytes_read] = '\0';
            
            pthread_mutex_lock(&stats_mutex);
            healthy_responses++;
            pthread_mutex_unlock(&stats_mutex);
            
            // 메트릭 업데이트
            update_metrics(healthy_responses, chunk_count);
            
            // 모든 요청에 대해 "정상" 응답
            generate_healthy_response(client_socket);
        }
        
        close(client_socket);
    }
    
    close(server_socket);
    return NULL;
}

// 헬스체크 엔드포인트 (항상 성공)
void* health_check_thread(void* arg) {
    printf("💚 헬스체크 스레드 시작\n");
    
    while (running) {
        pthread_mutex_lock(&leak_mutex);
        int current_chunks = chunk_count;
        pthread_mutex_unlock(&leak_mutex);
        
        // 메모리 누수가 있어도 "정상"으로 응답
        if (current_chunks < 100) {
            printf("✅ 헬스체크: 정상 (메모리 누수: %d MB)\n", current_chunks);
        } else if (current_chunks < 500) {
            printf("⚠️ 헬스체크: 주의 (메모리 누수: %d MB)\n", current_chunks);
        } else if (current_chunks < 1000) {
            printf("❌ 헬스체크: 위험 (메모리 누수: %d MB)\n", current_chunks);
        } else {
            printf("🚨 헬스체크: 치명적 (메모리 누수: %d MB)\n", current_chunks);
        }
        
        sleep(30);  // 30초마다 헬스체크
    }
    
    return NULL;
}

// 메모리 정리
void cleanup_memory() {
    printf("🧹 메모리 정리 중...\n");
    pthread_mutex_lock(&leak_mutex);
    for (int i = 0; i < chunk_count; i++) {
        if (leaked_chunks[i]) {
            free(leaked_chunks[i]);
            leaked_chunks[i] = NULL;
        }
    }
    chunk_count = 0;
    pthread_mutex_unlock(&leak_mutex);
    printf("✅ 메모리 정리 완료\n");
}

// 메인 함수
int main() {
    printf("🔬 은밀한 메모리 누수 시뮬레이션 서비스 v2.0\n");
    printf("==========================================\n");
    printf("🎯 목표: 표준 모니터링에서는 '정상', 실제로는 메모리 누수\n");
    printf("📊 특징:\n");
    printf("  - HTTP 서버로 헬스체크 제공 (포트 8080)\n");
    printf("  - Prometheus 메트릭 서버 (포트 9090)\n");
    printf("  - 모든 메트릭에서 '정상' 표시\n");
    printf("  - 백그라운드에서 은밀한 메모리 누수 (8초마다 1MB)\n");
    printf("  - eBPF로만 진짜 문제 확인 가능\n");
    printf("---\n");
    
    // 시그널 핸들러 설정
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    // 스레드 생성
    pthread_t leak_thread, http_thread, metrics_thread, health_thread;
    
    // 메모리 누수 스레드 시작
    if (pthread_create(&leak_thread, NULL, memory_leak_thread, NULL) != 0) {
        perror("메모리 누수 스레드 생성 실패");
        return 1;
    }
    
    // HTTP 서버 스레드 시작
    if (pthread_create(&http_thread, NULL, http_server_thread, NULL) != 0) {
        perror("HTTP 서버 스레드 생성 실패");
        return 1;
    }
    
    // 메트릭 서버 스레드 시작
    if (pthread_create(&metrics_thread, NULL, metrics_server_thread, NULL) != 0) {
        perror("메트릭 서버 스레드 생성 실패");
        return 1;
    }
    
    // 헬스체크 스레드 시작
    if (pthread_create(&health_thread, NULL, health_check_thread, NULL) != 0) {
        perror("헬스체크 스레드 생성 실패");
        return 1;
    }
    
    printf("🚀 모든 서비스 시작 완료!\n");
    printf("📝 종료하려면 Ctrl+C\n");
    printf("🔍 eBPF로 진짜 문제 확인: kubectl gadget memleak\n");
    printf("📊 거짓 메트릭 확인: http://localhost:%d/metrics\n", METRICS_PORT);
    printf("💚 거짓 헬스체크 확인: http://localhost:%d/health\n", HTTP_PORT);
    printf("---\n");
    
    // 메인 스레드는 대기
    while (running) {
        sleep(1);
    }
    
    // 정리
    printf("\n🔄 서비스 종료 중...\n");
    
    // 스레드 종료 대기
    pthread_join(leak_thread, NULL);
    pthread_join(http_thread, NULL);
    pthread_join(metrics_thread, NULL);
    pthread_join(health_thread, NULL);
    
    cleanup_memory();
    printf("👋 서비스 종료 완료\n");
    
    return 0;
}