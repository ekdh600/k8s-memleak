#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/resource.h>
#include <signal.h>
#include <time.h>

#define CHUNK_SIZE (1024 * 1024)  // 1MB
#define MAX_CHUNKS 1000
#define LEAK_INTERVAL 5  // 5초마다

void* leaked_chunks[MAX_CHUNKS];
int chunk_count = 0;
int running = 1;

void signal_handler(int sig) {
    printf("\n🛑 시그널 %d 수신, 정리 중...\n", sig);
    running = 0;
}

void get_memory_info() {
    struct rusage rusage;
    if (getrusage(RUSAGE_SELF, &rusage) == 0) {
        printf("📈 RSS: %ld KB (%.1f MB)\n", 
               rusage.ru_maxrss, 
               rusage.ru_maxrss / 1024.0);
    }
    
    // /proc/self/status에서 더 자세한 정보
    FILE* status = fopen("/proc/self/status", "r");
    if (status) {
        char line[256];
        while (fgets(line, sizeof(line), status)) {
            if (strncmp(line, "VmRSS:", 6) == 0 || 
                strncmp(line, "VmSize:", 7) == 0) {
                printf("📊 %s", line);
            }
        }
        fclose(status);
    }
}

void cleanup_memory() {
    printf("🧹 메모리 정리 중...\n");
    for (int i = 0; i < chunk_count; i++) {
        if (leaked_chunks[i]) {
            free(leaked_chunks[i]);
            leaked_chunks[i] = NULL;
        }
    }
    chunk_count = 0;
    printf("✅ 메모리 정리 완료\n");
}

void leak_memory() {
    printf("🚀 C 메모리 누수 시뮬레이터 시작\n");
    printf("📊 %d초마다 1MB씩 메모리 누수 발생\n", LEAK_INTERVAL);
    printf("📈 최대 누수: %d MB\n", MAX_CHUNKS);
    printf("🔍 eBPF 도구로 트래킹 가능\n");
    printf("---\n");
    
    // 시그널 핸들러 설정
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    time_t start_time = time(NULL);
    
    while (running && chunk_count < MAX_CHUNKS) {
        // 1MB 메모리 할당
        void* chunk = malloc(CHUNK_SIZE);
        if (chunk) {
            // 메모리 초기화 (실제 사용으로 인식)
            memset(chunk, 'x', CHUNK_SIZE);
            leaked_chunks[chunk_count++] = chunk;
            
            time_t current_time = time(NULL);
            int elapsed = (int)(current_time - start_time);
            
            printf("💧 메모리 누수 발생! 누적: %d MB (경과: %d초)\n", 
                   chunk_count, elapsed);
            get_memory_info();
            printf("---\n");
        } else {
            printf("❌ 메모리 할당 실패!\n");
            break;
        }
        
        sleep(LEAK_INTERVAL);
        fflush(stdout);  // 즉시 출력
    }
    
    if (chunk_count >= MAX_CHUNKS) {
        printf("⚠️ 최대 메모리 누수 도달: %d MB\n", chunk_count);
    }
    
    printf("🔄 eBPF 트래킹을 위해 프로세스 유지 중...\n");
    printf("📝 종료하려면 Ctrl+C 또는 kill 명령 사용\n");
    
    // 무한 대기 (eBPF 트래킹용)
    while (running) {
        sleep(1);
    }
    
    cleanup_memory();
    printf("👋 메모리 누수 시뮬레이터 종료\n");
}

int main() {
    printf("🔬 메모리 누수 시뮬레이션 및 eBPF 트래킹 데모\n");
    printf("=============================================\n");
    
    leak_memory();
    
    return 0;
}