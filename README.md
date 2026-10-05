
# 운동갈지도 · WhereToFit

> 오늘 어떤 운동을, 어디서 할 수 있을까?
<img width=40% alt="Group 427318901" src="https://github.com/user-attachments/assets/6f601d77-3294-4ca7-8e42-07d3b1b4fe03" />

**운동갈지도**는 나의 운동 목적과 경험, 관심 종목에 맞는 운동과 주변 공공체육시설을 찾고, 운동 일정과 기록까지 관리하는 iOS 앱입니다.

흩어진 시설 정보를 모아 보는 데서 나아가, **나에게 맞는 운동을 선택하고 실제로 실천하는 과정**을 돕습니다.

## 기획 배경

공공체육시설 이용 경험이 있거나 이용 의향이 있는 잠재 사용자 **37명**을 대상으로 사전 설문조사를 진행했습니다. 시설 탐색부터 예약, 실천, 일정 관리까지 이어지는 과정에서 다음과 같은 불편을 확인했습니다.

| 사용자 니즈 | 해결하고자 하는 문제 |
| --- | --- |
| 한곳에서 찾고 비교하기 | 여러 플랫폼에 흩어진 시설·프로그램 정보를 비교하기 어렵습니다. |
| 처음 이용해도 쉽게 이해하기 | 이용 규칙과 예약 방법을 파악하기 어려워 진입 장벽을 느낍니다. |
| 나에게 맞는 프로그램 고르기 | 운동 목적과 수준에 맞는 프로그램을 선별하기 어렵습니다. |
| 운동 계획을 실천으로 연결하기 | 예약 마감과 번거로운 절차로 계획에 차질이 생깁니다. |
| 꾸준히 운동하기 | 이용 일정을 잊거나 변경 사항을 놓쳐 지속적인 이용이 어렵습니다. |

운동갈지도는 이 문제를 **맞춤 추천 → 시설 탐색 → 예약 페이지 연결 → 일정 관리 → 운동 기록**의 흐름으로 풀어갑니다.

## 기술 스택

| 영역 | 기술 및 역할 |
| --- | --- |
| UI | UIKit, SnapKit, Then / 리포트 일부 SwiftUI |
| 상태 관리 | ReactorKit, RxSwift, RxCocoa |
| 화면 이동 | RxFlow |
| 네트워킹 | Alamofire |
| 이미지 | Kingfisher |
| 지도·위치 검색 | Naver Maps SDK, Naver 검색·Geocoding API, CoreLocation |
| 로컬 저장·동기화 기반 | CoreData, `NSPersistentCloudKitContainer` |

## 프로젝트 구조

화면 상태는 ReactorKit으로 관리하며, Presentation·Domain·Data로 책임을 분리하는 구조를 지향합니다. 화면 이동은 `App/Flow`에서 구성합니다.

```text
WhereToFit/WhereToFit/
├── App/                 # 앱 진입점, Flow, 공유 사용자 상태
├── Presentation/        # 화면별 ViewController, View, Reactor
│   ├── Onboarding/
│   ├── Home/
│   ├── Map/
│   ├── Program/
│   ├── Calendar/
│   ├── MyPage/
│   ├── Location/
│   ├── Notification/
│   └── Splash/
├── Domain/
│   ├── Entity/          # 도메인 모델
│   ├── UseCase/         # 사용자 목적에 따른 처리 흐름과 추천 규칙
│   └── Repository/      # 데이터 접근 인터페이스
├── Data/
│   ├── DTO/             # API 요청·응답 모델
│   ├── Repository/      # 데이터 조회·저장 및 모델 변환
│   └── Service/         # 네트워크, 저장소, 위치, 알림 등 기술 구현
└── Util/                # 공통 UI, 설정, 확장
```

기본 책임 흐름은 `ViewController → Reactor → UseCase → Repository → Service`입니다. 기존 구현을 단계적으로 정리하고 있어 일부 화면에는 Reactor가 Repository를 직접 사용하는 경로도 남아 있습니다.

## 주요 기능

### 나를 알아가는 온보딩
<p align=center><img width=80% alt="Group 427318901 (1)" src="https://github.com/user-attachments/assets/1a1909c3-4e41-4c7b-96a1-4a941122524d" /></p>

- 운동 경험, 관심 운동, 불편한 신체 부위, 운동 목적, 공공체육시설 이용 여부 등을 입력합니다.
- 저장한 프로필을 운동 추천과 프로그램 매칭에 활용합니다.
- 마이페이지에서 프로필과 운동 추천 결과를 확인할 수 있습니다.

### 오늘의 운동과 프로그램 추천
<p align=center><img width=60% alt="Group 427318902" src="https://github.com/user-attachments/assets/c7225615-b6d7-4a56-852d-0fffab53c37a" /></p>

- 개인 프로필을 바탕으로 운동 종목과 주변 프로그램을 추천합니다.
- 매칭률과 추천 이유를 함께 보여줘 선택을 돕습니다.
- 홈에서 현재 날씨와 등록한 프로그램 일정을 함께 확인합니다.
- 운동할 위치를 추가하고 선택해 주변 프로그램을 탐색합니다.

### 주변 공공체육시설 탐색과 예약 연결
<p align=center><img width=80% alt="Group 427318902 (1)" src="https://github.com/user-attachments/assets/9890329a-ec9c-48ed-bebc-41bdfac372bf" /></p>

- 지도와 목록에서 주변 시설 및 프로그램을 탐색합니다.
- 운동 종목과 가격 등 조건으로 원하는 대상을 좁혀봅니다.
- 시설 상세에서 운영 정보, 편의시설, 이용·신청 방법 등을 확인합니다.
- AI 추천을 켜면 개인화된 매칭 정보를 활용해 탐색할 수 있습니다.
- 예약 버튼으로 외부 예약·안내 페이지에 연결합니다. 실제 예약은 해당 서비스에서 진행합니다.

### 운동 일정과 관심 목록 관리
<p align=center><img width=80% alt="Group 5" src="https://github.com/user-attachments/assets/a5a3c11f-03cf-41c3-aea0-55e05765278d" /></p>

- 이용할 프로그램의 기간, 요일, 시간을 등록하고 관리합니다.
- 홈에서 오늘과 이후의 등록 일정을 확인합니다.
- 프로그램 시작 전 알림을 설정하고 알림 내역을 확인합니다.

- 관심 시설과 프로그램을 찜하고 마이페이지에서 다시 찾아봅니다.

앱에 프로그램 일정을 등록하는 기능은 외부 시설의 예약 확정과 별개입니다.

### 운동 기록과 리포트
<p align=center><img width=60% alt="Group 427318902 (2)" src="https://github.com/user-attachments/assets/673ebf10-23e9-4268-8e26-a4a914d00cdc" /></p>

- 캘린더에 운동, 몸무게, 컨디션을 기록합니다.
- 날짜별 기록을 확인하며 운동 습관을 돌아봅니다.
- 최근 7일의 운동·컨디션과 최근 30일의 몸무게 기록을 리포트로 확인합니다.

## 추천 방식

현재 `develop`의 추천은 **규칙 기반 매칭 점수 계산**과 **서버를 통한 추천 문구 생성 요청**으로 구성됩니다.

| 구성 | 현재 구현 |
| --- | --- |
| 운동 종목 매칭 | 서버에서 받은 추천 규칙에 나이, 운동 경험, 운동 목적, 신체 불편 부위, 선호 종목을 적용해 점수를 계산합니다. |
| 프로그램 매칭 | 운동 종목 점수와 프로그램의 대상 연령·수준을 반영해 매칭률을 계산합니다. |
| 홈 프로그램 추천 | 사용자 위치 주변의 프로그램을 찾고, 적합도와 거리 가점을 반영해 노출 순서를 정합니다. |
| 추천 이유 | 프로필과 추천 종목 정보를 `generate-home-recommendation-copy` 서버 함수로 보내 추천 문구를 요청합니다. |

AI 추천이라는 기능명과 별개로, 클라이언트의 매칭률은 규칙 기반으로 계산됩니다. 서버 함수의 모델과 내부 구현은 이 저장소에 포함되어 있지 않습니다.

## 향후 개선 계획

- **날씨를 반영한 추천:** 야외 활동에 적합한 날에는 야외 시설을, 궂은 날에는 실내 시설과 프로그램을 우선 제안합니다. 현재는 날씨 조회·표시와 프로그램 추천이 별도로 동작합니다.
- **기록에 따라 발전하는 추천:** 누적 운동 기록과 이용 패턴으로 추천 기준을 보완합니다.
- **리포트 확장:** 주간·월간 목표 달성 현황과 관심 운동의 변화를 살펴볼 수 있도록 발전시킵니다.

## API 설정

`WhereToFit/WhereToFit/Config.xcconfig` 파일을 생성하고 아래 형식으로 발급받은 값을 입력합니다.

```xcconfig
NAVER_MAP_CLIENT_ID = YOUR_NAVER_MAP_CLIENT_ID
NAVER_MAP_CLIENT_SECRET = YOUR_NAVER_MAP_CLIENT_SECRET
NAVER_SEARCH_CLIENT_ID = YOUR_NAVER_SEARCH_CLIENT_ID
NAVER_SEARCH_CLIENT_SECRET = YOUR_NAVER_SEARCH_CLIENT_SECRET
OPENWEATHER_KEY = YOUR_OPENWEATHER_KEY
SUPABASE_PUBLISHABLE_KEY = YOUR_SUPABASE_PUBLISHABLE_KEY
```
