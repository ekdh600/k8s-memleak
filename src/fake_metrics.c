#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/resource.h>
#include <time.h>
#include <pthread.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>

#define METRICS_PORT 9090
#define MAX_CONNECTIONS 50

// 전역 변수
int total_requests = 0;
int memory_leak_chunks = 0;
pthread_mutex_t metrics_mutex = PTHREAD_MUTEX_INITIALIZER;

// Prometheus 메트릭 생성 (거짓 "정상" 데이터)
void generate_fake_metrics(int client_socket) {
    struct rusage rusage;
    getrusage(RUSAGE_SELF, &rusage);
    
    // 실제 메모리 사용량
    long real_rss_kb = rusage.ru_maxrss;
    
    // 거짓 "정상" 메트릭 생성
    long fake_rss_kb = real_rss_kb;
    if (fake_rss_kb > 100000) {  // 100MB 초과시
        fake_rss_kb = 80000 + (fake_rss_kb % 20000);  // 80-100MB 범위로 조작
    }
    
    // GC 메트릭 (항상 "정상")
    int gc_count = total_requests / 100;  // 요청 수에 비례
    int gc_duration = 10 + (total_requests % 20);  // 10-30ms
    
    // 응답 시간 (점진적 증가를 숨김)
    int response_time = 50 + (total_requests % 30);  // 50-80ms로 고정
    
    char response[4096];
    snprintf(response, sizeof(response),
        "HTTP/1.1 200 OK\r\n"
        "Content-Type: text/plain; version=0.0.4; charset=utf-8\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "\r\n"
        "# HELP http_requests_total Total number of HTTP requests\n"
        "# TYPE http_requests_total counter\n"
        "http_requests_total %d\n"
        "\n"
        "# HELP http_request_duration_seconds HTTP request duration in seconds\n"
        "# TYPE http_request_duration_seconds histogram\n"
        "http_request_duration_seconds_bucket{le=\"0.1\"} %d\n"
        "http_request_duration_seconds_bucket{le=\"0.5\"} %d\n"
        "http_request_duration_seconds_bucket{le=\"1.0\"} %d\n"
        "http_request_duration_seconds_bucket{le=\"+Inf\"} %d\n"
        "http_request_duration_seconds_sum %.3f\n"
        "http_request_duration_seconds_count %d\n"
        "\n"
        "# HELP process_resident_memory_bytes Resident memory size in bytes\n"
        "# TYPE process_resident_memory_bytes gauge\n"
        "process_resident_memory_bytes %ld\n"
        "\n"
        "# HELP process_virtual_memory_bytes Virtual memory size in bytes\n"
        "# TYPE process_virtual_memory_bytes gauge\n"
        "process_virtual_memory_bytes %ld\n"
        "\n"
        "# HELP go_gc_cycles_total Total number of garbage collection cycles\n"
        "# TYPE go_gc_cycles_total counter\n"
        "go_gc_cycles_total %d\n"
        "\n"
        "# HELP go_gc_duration_seconds A summary of the GC invocation durations\n"
        "# TYPE go_gc_duration_seconds summary\n"
        "go_gc_duration_seconds{quantile=\"0\"} %.3f\n"
        "go_gc_duration_seconds{quantile=\"0.25\"} %.3f\n"
        "go_gc_duration_seconds{quantile=\"0.5\"} %.3f\n"
        "go_gc_duration_seconds{quantile=\"0.75\"} %.3f\n"
        "go_gc_duration_seconds{quantile=\"1\"} %.3f\n"
        "go_gc_duration_seconds_sum %.3f\n"
        "go_gc_duration_seconds_count %d\n"
        "\n"
        "# HELP memory_leak_simulator_chunks_total Total number of memory chunks (HIDDEN)\n"
        "# TYPE memory_leak_simulator_chunks_total counter\n"
        "memory_leak_simulator_chunks_total %d\n"
        "\n"
        "# HELP service_health_status Service health status (ALWAYS HEALTHY)\n"
        "# TYPE service_health_status gauge\n"
        "service_health_status 1\n"
        "\n"
        "# HELP memory_usage_percent Memory usage percentage (NORMALIZED)\n"
        "# TYPE memory_usage_percent gauge\n"
        "memory_usage_percent %.1f\n",
        total_requests,
        total_requests, total_requests, total_requests, total_requests,
        response_time / 1000.0, total_requests,
        fake_rss_kb * 1024, fake_rss_kb * 1024,
        gc_count,
        gc_duration / 1000.0, gc_duration / 1000.0, gc_duration / 1000.0, 
        gc_duration / 1000.0, gc_duration / 1000.0,
        gc_duration / 1000.0, gc_count,
        memory_leak_chunks,  // 숨겨진 실제 메모리 누수
        75.0  // 항상 75%로 표시 (정상 범위)
    );
    
    write(client_socket, response, strlen(response));
}

// 메트릭 서버
void* metrics_server_thread(void* arg) {
    int server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket < 0) {
        perror("메트릭 서버 소켓 생성 실패");
        return NULL;
    }
    
    int opt = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(METRICS_PORT);
    
    if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("메트릭 서버 바인드 실패");
        close(server_socket);
        return NULL;
    }
    
    if (listen(server_socket, MAX_CONNECTIONS) < 0) {
        perror("메트릭 서버 리스닝 실패");
        close(server_socket);
        return NULL;
    }
    
    printf("📊 Prometheus 메트릭 서버 시작 (포트: %d)\n", METRICS_PORT);
    printf("🔍 메트릭 확인: http://localhost:%d/metrics\n", METRICS_PORT);
    
    while (1) {
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        
        int client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &client_len);
        if (client_socket < 0) {
            if (errno != EINTR) {
                perror("메트릭 서버 연결 수락 실패");
            }
            continue;
        }
        
        // 메트릭 요청 처리
        char buffer[1024];
        int bytes_read = read(client_socket, buffer, sizeof(buffer) - 1);
        if (bytes_read > 0) {
            buffer[bytes_read] = '\0';
            
            // Prometheus 메트릭 응답
            generate_fake_metrics(client_socket);
        }
        
        close(client_socket);
    }
    
    close(server_socket);
    return NULL;
}

// 메트릭 업데이트
void update_metrics(int requests, int chunks) {
    pthread_mutex_lock(&metrics_mutex);
    total_requests = requests;
    memory_leak_chunks = chunks;
    pthread_mutex_unlock(&metrics_mutex);
}

// 메트릭 서버 시작
void start_metrics_server() {
    pthread_t metrics_thread;
    if (pthread_create(&metrics_thread, NULL, metrics_server_thread, NULL) != 0) {
        perror("메트릭 서버 스레드 생성 실패");
        return;
    }
    
    printf("✅ Prometheus 메트릭 서버 시작됨\n");
}