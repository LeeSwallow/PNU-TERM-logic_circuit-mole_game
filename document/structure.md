## 텀프로젝트 설계 제안서


### 프로젝트 개요

- **프로젝트 명**: fgga로 구현한 두더지 게임
- **팀원**: 이민형, 윤서경, Jamie
- **목표**: 
    - Combo II 기기에서 실행 가능한 두더지 게임 개발
    - 주요 모듈 학습 및 fsm 구현 경험 획득

### 기능 요구사항

#### 사용하는 모듈

- **입력모듈**
    - 12 key keypad 게임 입력 장치
- **출력모듈**
    - 8 arrays led
    - 7-segment display
    - rgb led
    - piezo buzzer

#### 게임 주요 상태

- **게임 준비 (READY)**
    - initial state
    - 게임 시작 버튼('*' key) 시 PLAYING 상태로 전환

- **게임 시작 (PLAYING)**
    - 60s 동안 두더지 잡기
    - 두더지 잡을 때마다 점수 획득(SCORE UP)
    - 잘못된 입력 시 생명 감소(LIFE DOWN)
        - 생명이 0이 되면 GAME OVER 상태로 전환
    - 60s가 지나고 stage != 3 이면 STAGE CLEAR 상태로 전환
    - 60s가 지나고 stage == 3 이면 GAME CLEAR 상태로 전환

- **게임 종료 (GAME OVER)**
    - 게임 종료 음 재생 후 끝나면 READY 상태로 전환
    - 모든 점수 및 상태 초기화(score=0, life=3, stage=1)

- **스테이지 클리어 (STAGE CLEAR)**
    - 스테이지 클리어 음 재생 후 READY 상태로 전환
    - 점수 유지, 생명 유지, 스테이지 1 증가(stage += 1)
    - 최대 3 스테이지까지 진행 가능

- **게임 클리어 (GAME CLEAR)**
    - 게임 클리어 음 재생
    
- **게임 일시정지 (PAUSE)**
    - dip switch로 게임 일시정지 및 재개 가능

3. 기술 스택 및 도구

- 하드웨어: Combo II 기기
- 프로그래밍 언어: Verilog HDL


