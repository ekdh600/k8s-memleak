#ifndef FAKE_METRICS_H
#define FAKE_METRICS_H

#include <pthread.h>

// 메트릭 관련 상수
#define METRICS_PORT 9090
#define MAX_CONNECTIONS 100

// 전역 변수 (extern으로 선언)
extern int total_requests;
extern int memory_leak_chunks;
extern pthread_mutex_t metrics_mutex;

// 함수 선언
void generate_fake_metrics(int client_socket);
void* metrics_server_thread(void* arg);
void update_metrics(int requests, int chunks);
void start_metrics_server();

#endif // FAKE_METRICS_H
