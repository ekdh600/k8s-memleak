package main

import (
	"fmt"
	"log"
	"net/http"
	"runtime"
	"time"
	_ "net/http/pprof"
)

// 메모리 누수를 시뮬레이션하는 전역 변수
var memoryLeak []*[]byte

func main() {
	// pprof 디버그 엔드포인트 활성화
	go func() {
		log.Println("Starting pprof server on :6060")
		log.Fatal(http.ListenAndServe(":6060", nil))
	}()

	fmt.Println("🚀 메모리 누수 시뮬레이터 시작")
	fmt.Println("📊 pprof 서버: http://localhost:6060/debug/pprof/")
	fmt.Println("🔍 메모리 상태 모니터링 중...")

	// 메모리 누수 시뮬레이션
	go simulateMemoryLeak()
	
	// 메모리 상태 주기적 출력
	go monitorMemory()

	// 메인 스레드 유지
	select {}
}

func simulateMemoryLeak() {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		// 1MB씩 메모리 누수
		leak := make([]byte, 1024*1024)
		memoryLeak = append(memoryLeak, &leak)
		
		fmt.Printf("💧 메모리 누수 발생! 누적: %d MB\n", len(memoryLeak))
		
		// GC 강제 실행 (실제로는 누수된 메모리는 해제되지 않음)
		runtime.GC()
	}
}

func monitorMemory() {
	ticker := time.NewTicker(10 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)
		
		fmt.Printf("📈 메모리 상태:\n")
		fmt.Printf("   힙 할당: %d MB\n", m.Alloc/1024/1024)
		fmt.Printf("   힙 시스템: %d MB\n", m.Sys/1024/1024)
		fmt.Printf("   GC 횟수: %d\n", m.NumGC)
		fmt.Printf("   고루틴 수: %d\n", runtime.NumGoroutine())
		fmt.Printf("   누수된 청크 수: %d\n", len(memoryLeak))
		fmt.Println("---")
	}
}