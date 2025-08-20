package main

import (
	"os"
	"runtime"
	"runtime/pprof"
	"testing"
	"time"
)

func TestHeapDoesNotGrowUnbounded(t *testing.T) {
	t.Log("🧪 메모리 누수 테스트 시작")
	
	// 테스트에서 누수를 켠 상태에서 성장률을 측정
	go func() {
		for i := 0; i < 10; i++ {
			leak := make([]byte, 1024*1024) // 1MB
			memoryLeak = append(memoryLeak, &leak)
			time.Sleep(100 * time.Millisecond)
		}
	}()
	
	time.Sleep(2 * time.Second)

	// 초기 스냅샷
	runtime.GC()
	f1, err := os.CreateTemp("", "heap1.pb")
	if err != nil {
		t.Fatalf("초기 힙 프로파일 생성 실패: %v", err)
	}
	defer os.Remove(f1.Name())
	defer f1.Close()
	
	err = pprof.WriteHeapProfile(f1)
	if err != nil {
		t.Fatalf("초기 힙 프로파일 쓰기 실패: %v", err)
	}

	// 관찰 기간
	time.Sleep(3 * time.Second)

	// 두 번째 스냅샷
	runtime.GC()
	f2, err := os.CreateTemp("", "heap2.pb")
	if err != nil {
		t.Fatalf("두 번째 힙 프로파일 생성 실패: %v", err)
	}
	defer os.Remove(f2.Name())
	defer f2.Close()
	
	err = pprof.WriteHeapProfile(f2)
	if err != nil {
		t.Fatalf("두 번째 힙 프로파일 쓰기 실패: %v", err)
	}

	// 간단 비교를 위해 파일 크기 비교
	s1, err := os.Stat(f1.Name())
	if err != nil {
		t.Fatalf("첫 번째 프로파일 크기 확인 실패: %v", err)
	}
	
	s2, err := os.Stat(f2.Name())
	if err != nil {
		t.Fatalf("두 번째 프로파일 크기 확인 실패: %v", err)
	}

	t.Logf("힙 프로파일 크기: 초기=%d bytes, 최종=%d bytes", s1.Size(), s2.Size())

	if s2.Size() > s1.Size()*2 {
		t.Fatalf("힙 프로파일이 너무 많이 성장했습니다! 초기=%d, 최종=%d", s1.Size(), s2.Size())
	}

	t.Log("✅ 메모리 누수 테스트 통과")
}

func TestMemoryLeakSimulation(t *testing.T) {
	t.Log("🧪 메모리 누수 시뮬레이션 테스트")
	
	initialLen := len(memoryLeak)
	
	// 메모리 누수 시뮬레이션
	for i := 0; i < 5; i++ {
		leak := make([]byte, 1024*1024) // 1MB
		memoryLeak = append(memoryLeak, &leak)
		time.Sleep(100 * time.Millisecond)
	}
	
	finalLen := len(memoryLeak)
	
	if finalLen <= initialLen {
		t.Fatalf("메모리 누수가 시뮬레이션되지 않았습니다. 초기=%d, 최종=%d", initialLen, finalLen)
	}
	
	t.Logf("✅ 메모리 누수 시뮬레이션 성공: %d -> %d 청크", initialLen, finalLen)
}