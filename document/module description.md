## 전체 모듈 종합 설명

게임은 `gm`(game_main) 최상위 모듈을 통해 하위의 상태/게임로직/입출력/사운드/서보 제어 등을 묶어 동작한다. 기준 클럭은 1 MHz를 사용하며, 시간 관련 모든 서브모듈이 이 클럭을 전제로 ms, s 단위 시간을 계산한다.

---
### 1. gm (game_main)
역할: 시스템 최상위 결합 모듈.
포함 구성요소:
- `gsm` 게임 상태/타이머/점수/스테이지/라이프 관리
- `igm` 두더지(몰) 등장/숨김 순서 및 난수 기반 위치 관리
- `sndm` 사운드 이펙트 재생 관리 + `peizo_output` 버저 구동
- `key_button_input` 버튼 디코딩(1~11번)
- `leds_output` 현재 두더지 위치 LED 출력
- `7seg_arr_output` 라이프 및 점수 7-세그먼트 표시
- `servo_output` 타이머 기반 서보 PWM 출력 (게임 진행 연출)

주요 내부 제어:
- `gsm_state`에 따라 ready / playing / clear / gameover 상태별 분기.
- ready 상태에서 START(버튼 값 10) 눌림 시 카운트다운 재생 후 자동 playing 전환.
- playing 동안 버튼(1~8)과 현재 `igm_mole_pos` 비교해 hit/miss 처리 (점수 증가 또는 라이프 감소 + 사운드).
- 타이머 종료 시 stage 진행 또는 game clear / game over 전환 플래그 설정.
- 각 상태 종료 시 대응 사운드(클리어, 실패, 게임 클리어) 재생 완료 후 ready 복귀.

---
### 2. gsm (game_state_manager)
역할: 글로벌 게임 상태, 스테이지, 라이프, 점수, 타이머 카운트다운 관리. 트리거(fl ag+trig) 기반의 원자적 상태 변경을 수행하고 `done` 펄스를 제공.

입출력 개요:
- 입력: `flag[3:0]` (동작/상태 전환 코드), `trig` (상승엣지 시 적용)
- 출력: `done`(변경 완료 알림 펄스), `sec_posedge`(1초 경과 펄스), `timer_running`, `timer[6:0]`, `state[2:0]`, `stage[1:0]`, `lives[1:0]`, `score[9:0]`

시간 처리:
- 1 MHz 기준 1000클럭 = 1ms, 1000 ms 누적해 1초 감소.
- `sec_posedge`는 지정 펄스 길이로 유지되어 다른 모듈이 쉽게 동기화.

게임 파라미터 초기값:
- lives=3, stage=1, score=0, ready 상태에서 timer=READY_DURATION(5초), playing 진입 시 PLAY_DURATION(60초).

flag 정의(동작/상태 전환):
- 0001: 점수 +1
- 0010: 라이프 -1 (0 미만 방지)
- 0100: 타이머 일시정지
- 0101: 타이머 재개
- 1000: ready로 (카운트다운 준비) 
- 1010: ready→playing (플레이 시작)
- 1100: playing→stage clear (스테이지 번호 +1, 타이머 정지)
- 1101: playing→game over (스테이지/라이프/점수 리셋)
- 1110: playing→game clear
- 1111: stage clear 후 완전 리셋 ready

state 정의:
- 000: ready
- 001: playing
- 011: game over
- 100: stage clear
- 101: game clear
(코드에 010(paused)은 명시적 전환 사용 안 함)

---
### 3. igm (in_game_manager)
역할: 두더지(mole) 등장/숨김 타이밍 및 위치를 난수 기반으로 생성. 난이도(스테이지)에 따라 표시 지속 시간(mole_dur)과 숨김 간격(inter_limit)을 조정.

동작 흐름:
- enable=1 && idle → 즉시 첫 몰 등장 설정
- show 상태: mole_dur(ms) 동안 LED 유지 후 hide 상태로 전환, hide 상태에서 난수 기반 interval 경과 후 새 위치 등장.
- 위치 산출: `(rand_val % 8)+1` → 1~8
- 숨김 간격: `(rand_val % inter_limit)+1` ms

스테이지별 파라미터:
- stage1: show 1000ms / inter_limit 500ms
- stage2: show 750ms / inter_limit 250ms
- stage3: show 500ms / inter_limit 200ms

---
### 4. sndm (sound_manager)
역할: 트리거 펄스 입력 시 선택된 사운드 모드의 음 패턴을 순차 재생. 각 음은 고정 길이(BASE_CYCLES=200ms) 후 다음 인덱스로 이동. 종료 혹은 sentinel(1111) 도달 시 `playing`=0.

사운드 모드별 패턴 (4비트 코드: 음 또는 0000 무음, 1111 종료):
- 001(beep): D4
- 010(start_beep): C5
- 011(hit): C4 → G4
- 100(miss): E4 → (무음) → E4
- 101(stage clear/win): C4 → E4 → G4 → C5
- 110(game over): C5 → G4 → E4 → C4
- 111(game clear): C4 → E4 → G4 → (무음) → F4 → A4 → C5

`trig` 상승엣지 시 현재 `snd_mode` 래치하여 재생 중 모드 변동 영향 방지.
`buzzer_mode`는 진행 중 & sentinel 아님일 때 활성, 그 외 0000.

---
### 5. peizo_output (버저 출력)
역할: 모드(4비트)에 따른 주파수 분주로 피에조 부저 PWM 생성.
주요 모드 주파수 (카운트 임계값 기준):
- C4=1911, D4=1703, E4=1517, F4=1432, G4=1275, A4=1136, B4=1012, C5=956
카운터가 해당 값 도달 시 토글 → 사각파 발생. mode가 유효하지 않으면 출력 0(무음).

---
### 6. key_button_input
역할: 11비트 버튼 인코딩을 단일 우선순위 디코드하여 `button_pressed`와 `button_value(1~11)` 제공. 어떠한 패턴에도 매칭 안 되면 0.
용도: 게임 메인에서 start 버튼(값 10) 및 몰 타격 버튼(1~8) 판별.

---
### 7. leds_output
역할: 현재 몰 위치(`mole_pos`)를 8비트 LED 원-핫(one-hot) 형태로 출력. 1~8 위치 매핑, 그 외 0.

---
### 8. 7seg_arr_output
역할: 8자리 7세그먼트 배열을 시간다중화 스캔(약 1kHz)하여 라이프 1자리 + 점수(최대 3자리) 우측 정렬 표시. 나머지 자리는 공백 처리.

표시 배치 (scan_idx 7→0) (4자리 score 블록 + 4자리 lives 블록):
- [7] score thousands (선행 0 blank)
- [6] score hundreds (선행 0 blank)
- [5] score tens (선행 0 blank)
- [4] score ones
- [3] lives thousands (blank 고정)
- [2] lives hundreds (blank 고정)
- [1] lives tens (blank 고정)
- [0] lives ones (2비트 lives 확장값 표시)

세그 인코딩: common-anode 기준, a~g, dp. 0~9 전부 정의, 나머지 blank.

---
### 9. rand_gen
역할: 16비트 LFSR (다항식 taps 15,13,12,10) 기반 순환 시퀀스 생성. 하위 9비트를 `rand_num`으로 지속 출력. 리셋 후 seed=16'hACE1. START 누르는 시점의 타이밍 차이가 사실상 시드 역할을 해 의사 난수 다양성 확보.

---
### 10. servo_output
역할: 1 MHz 기반 20 ms(50 Hz) 프레임 PWM 생성. 타이머(0~60) 값에 따라 0.7 ms~2.3 ms 범위 선형 매핑 → 서보 위치 표현. 게임 비활성(enable=0) 시 중립(센터) 펄스 출력. 
계산식: pulse = MIN + (MAX-MIN)*timer/60.

---
### 11. text_lcd_output
역할: HD44780 호환 16x2 문자 LCD에 게임 상태 텍스트 출력. state/stage/lives/score/timer 또는 매초(sec_posedge) 변화 시 두 줄을 재작성.
라인 포맷(각 16문자):
- Line1: STATE(5) + 공백 + "ST" + stage + 공백 + "T" + 남은 타이머 2자리 + 공백 패딩
- Line2: "L" + lives + 공백 + "S" + score 4자리(0 패딩) + 나머지 공백
상태 단축표기: READY, PLAY , GOVER, SCLR , GCLR (길이 5로 맞춤). 점수는 최대 9999로 클램프.
초기화 시퀀스(기본 8비트 / 2라인 / 표시 ON / Clear / Entry 모드) 후 버퍼를 순차 문자 쓰기.
EN 펄스와 명령 지연을 내부 us 단위 카운터(1MHz)로 단순 처리. RW=0만 사용(바쁜 플래그 미폴링).

---
### 상호 작용 흐름 요약
1. 전원/리셋 후 ready: `gsm` 카운트다운 대기, START 버튼(10) 입력 시 resume → 카운트다운 음향 재생(`sndm`).
2. 카운트다운 종료 → playing: `igm` 난수 기반 몰 등장, 사용자는 버튼(1~8)으로 타격 시도.
3. hit/miss → `gsm` 점수/라이프 변경 + 대응 음향.
4. 타이머 종료 → 스테이지 증감 또는 게임 클리어/오버 상태, 사운드 재생 종료 후 ready 복귀.
5. 서보는 남은 시간(timer)을 위치로 표현(시각적/물리적 피드백).

---
### 확장/개선 아이디어 (향후 참고)
- `rand_gen` enable/샘플링 방식 도입으로 재시드/간헐적 캡처 구현.
- `key_button_input` 다중 동시 버튼 처리(현재는 단일 패턴) 또는 디바운싱 추가.
- `7seg_arr_output` 점수 4자리 이상 확장 및 DP(소수점) 활용.
- `sndm` 재생 중 인터럽트(우선순위 높은 효과로 교체) 기능.
- `servo_output` 스테이지별 속도 변화나 애니메이션(펄스 스윕) 추가.

---
문서 최종 갱신: 2025-11-24

