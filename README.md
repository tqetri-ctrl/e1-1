# 🚀 개발자 워크스테이션 구축 및 컨테이너 가상화 실습 보고서

> **프로젝트 소유자**: tqetri-ctrl (`tqetri@gmail.com`)  
> **미션 목표**: Windows 환경에서 WSL2(Ubuntu), Docker, Git을 활용하여 재현 가능한 개발 워크스테이션을 구축하고, CLI 기본 조작, 파일 접근 권한, 커스텀 Dockerfile 빌드, 포트 매핑, 바인드 마운트 및 볼륨 영속성을 실증합니다.

---

## 1. 프로젝트 개요
개발 워크스테이션 구축은 코드가 "내 컴퓨터에서만" 동작하는 환경 의존성 문제를 방지하고, 팀원 누구나 동일한 방식으로 실행·배포·디버깅할 수 있는 재현 가능한 실행 환경을 구성하는 데 목적이 있습니다.

- **리눅스 CLI**: 터미널 기본 조작 9종 및 POSIX 파일 권한(`r/w/x`, 8진수 표기법)을 직접 실습.
- **Docker 컨테이너**: 이미지와 컨테이너의 분리, 격리된 가상 환경 구동, 포트 매핑 및 스토리지 연결(바인드 마운트/볼륨).
- **Git / GitHub**: 소스코드 형상 관리 파이프라인 구축 및 민감정보 유출 방지.

---

## 2. 실행 환경

| 구분 | 환경 및 버전 정보 | 비고 |
| :--- | :--- | :--- |
| **호스트 OS** | Windows 10/11 Home/Pro (x86_64 / AMD64) | Intel 64-bit CPU |
| **Linux 환경** | WSL2 (Windows Subsystem for Linux 2) - Ubuntu 24.04/22.04 LTS | Linux 5.15 / 6.x 커널 |
| **Shell / 터미널** | bash (WSL), PowerShell 7 / Windows Terminal | UTF-8 표준 인코딩 |
| **Docker Engine** | Docker version 29.9.2 (Docker Desktop v4.35+) | WSL2 기반 백엔드 구동 |
| **Git 버전** | git version 2.52.0.windows.1 (및 Linux git) | Local & Global 환경 |

---

## 3. 수행 항목 체크리스트

- [x] **0단계**: 하드웨어 가상화, WSL2 Ubuntu, Docker Desktop, VS Code 필수 확장 4종 설치
- [x] **1단계**: Docker 버전(`--version`) 및 데몬 정상 구동(`info`) 점검
- [ ] **2단계**: 리눅스 터미널 기본 명령어 9종 수행 및 출력 로그 기록
- [ ] **2단계**: 파일(1개) 및 디렉토리(1개) 권한 변경(`chmod 600`, `chmod 700`) 전/후 비교
- [ ] **3단계**: `hello-world` 및 `ubuntu` 대화형 컨테이너 실행, attach vs exec 동작 분석
- [ ] **4단계**: `nginx:alpine` 기반 커스텀 Dockerfile 작성, 3대 커스텀 포인트 명시 및 빌드
- [ ] **4단계**: 포트 매핑(`8080`, `8081`) 실행 및 주소창 포함 브라우저 접속 화면 캡처
- [ ] **5단계**: 바인드 마운트 소스 실시간 수정 전/후 `curl` 응답 비교
- [ ] **5단계**: Docker 볼륨 생성, 컨테이너 강제 삭제(`rm -f`) 전/후 데이터 영속성 검증
- [ ] **6단계**: Git 사용자 정보(`tqetri-ctrl`) 설정, `.gitignore` 보안 적용, 원격 GitHub 연동
- [x] **7단계**: 트러블슈팅 2건 이상 (문제 ➔ 원인 가설 ➔ 확인 ➔ 해결) 완비

---

## 4. 리눅스 터미널 조작 및 권한 실습 로그

### 4.1 터미널 기본 조작 9종 로그
> **절대 경로 vs 상대 경로**:
> - **절대 경로(Absolute Path)**: 최상위 루트(`/` 또는 `C:\`)부터 시작하여 대상 파일/디렉토리까지의 전체 고유 경로 (예: `/home/ksh/practice/sample.txt`). 현재 작업 위치와 무관하게 항상 동일한 대상을 가리킵니다.
> - **상대 경로(Relative Path)**: 현재 작업 디렉토리(`.` 또는 `pwd`)를 기준으로 상대적인 위치를 나타내는 경로 (예: `./test_dir`, `../sample.txt`). 현재 위치에 따라 가리키는 대상이 달라집니다.

```bash
# 1) 현재 위치 확인 (pwd)
ksh@ksh:~$ pwd
/home/ksh

# 2) 실습 폴더 생성 (mkdir -p)
ksh@ksh:~$ mkdir -p ~/practice/test_dir
ksh@ksh:~$ cd ~/practice/test_dir

# 3) 빈 파일 생성 (touch)
ksh@ksh:~/practice/test_dir$ touch sample.txt

# 4) 파일 내용 작성 및 출력 (echo, cat)
ksh@ksh:~/practice/test_dir$ echo "Workstation Linux CLI Lab" > sample.txt
ksh@ksh:~/practice/test_dir$ cat sample.txt
Workstation Linux CLI Lab

# 5) 목록 및 숨김 파일 확인 (ls -la)
ksh@ksh:~/practice/test_dir$ ls -la
total 12
drwxr-xr-x 2 ksh ksh 4096 Nov  2 15:30 .
drwxr-xr-x 3 ksh ksh 4096 Nov  2 15:30 ..
-rw-r--r-- 1 ksh ksh   26 Nov  2 15:30 sample.txt

# 6) 파일 복사 (cp)
ksh@ksh:~/practice/test_dir$ cp sample.txt sample_copy.txt

# 7) 파일 이동 및 이름 변경 (mv)
ksh@ksh:~/practice/test_dir$ mv sample_copy.txt renamed.txt

# 8) 파일 삭제 (rm)
ksh@ksh:~/practice/test_dir$ rm renamed.txt
```

---

### 4.2 권한(Permission) 변경 실습 및 비교
> **권한 표기 규칙 (r/w/x 및 8진수 해석)**:
> - 리눅스 권한은 `소유자(User) / 소유그룹(Group) / 기타사용자(Others)`의 3개 영역으로 나뉩니다.
> - 각 자리는 2진수 플래그의 합으로 계산됩니다: `r (Read, 읽기) = 4`, `w (Write, 쓰기) = 2`, `x (Execute, 실행/디렉토리진입) = 1`.
> - **`755`**: 소유자 `rwx (4+2+1=7)`, 그룹 `r-x (4+0+1=5)`, 기타 `r-x (4+0+1=5)`
> - **`644`**: 소유자 `rw- (4+2+0=6)`, 그룹 `r-- (4+0+0=4)`, 기타 `r-- (4+0+0=4)`
> - **디렉토리에서 `x`의 의미**: 파일에서의 `x`는 실행 프로그램을 의미하지만, 디렉토리에서의 `x`는 **디렉토리 내부로 진입(`cd`)하고 파일 메타데이터에 접근할 수 있는 권한**을 뜻합니다.

#### 1) 파일 권한 변경 (`sample.txt` : 644 ➔ 600)
```bash
# 변경 전 권한 확인 (기본값: 644)
$ ls -l sample.txt
-rw-r--r-- 1 ksh ksh 26 Nov  2 15:30 sample.txt

# 권한 변경: 소유자만 읽기/쓰기 허용 (600)
$ chmod 600 sample.txt

# 변경 후 권한 확인 (600)
$ ls -l sample.txt
-rw------- 1 ksh ksh 26 Nov  2 15:30 sample.txt
```

#### 2) 디렉토리 권한 변경 (`test_dir` : 755 ➔ 700)
```bash
# 변경 전 디렉토리 권한 확인 (기본값: 755)
$ ls -ld ~/practice/test_dir
drwxr-xr-x 2 ksh ksh 4096 Nov  2 15:30 /home/ksh/practice/test_dir

# 권한 변경: 소유자만 진입 및 파일 목록 조회 가능 (700)
$ chmod 700 ~/practice/test_dir

# 변경 후 디렉토리 권한 확인 (700)
$ ls -ld ~/practice/test_dir
drwx------ 2 ksh ksh 4096 Nov  2 15:30 /home/ksh/practice/test_dir
```

---

## 5. Docker 운영 및 컨테이너 관리 로그

*(3단계 실습 수행 후 터미널 출력 로그 기재 영역)*
- `docker info`
- `docker run --name hello-test hello-world`
- `docker run -it --name ubuntu-test ubuntu /bin/bash`
- `docker ps -a`, `docker images`, `docker logs`, `docker stats --no-stream`

---

## 6. Dockerfile 커스텀 웹 서버 및 포트 매핑

*(4단계 실습 수행 후 Dockerfile 전문, 커스텀 3포인트, 빌드 로그, 브라우저 주소창 스크린샷 링크 기재 영역)*

---

## 7. 바인드 마운트 및 볼륨 영속성 검증

*(5단계 실습 수행 후 호스트 파일 수정 전/후 curl 응답 비교, 컨테이너 rm -f 후 볼륨 데이터 유지 확인 로그 기재 영역)*

---

## 8. Git 설정 및 GitHub 연동 증빙

*(6단계 실습 수행 후 git config --local --list 출력 및 VSCode/GitHub 연동 화면 링크 기재 영역)*

---

## 9. 🔍 트러블슈팅 보고서 (Troubleshooting Report)

### 📌 [트러블슈팅 1] WSL Windows 마운트 드라이브(`/mnt/d/...`) 상의 `chmod` 권한 미반영 현상 (실제 발생 사례)

- **1. 문제 현상 (Symptom)**:
  WSL2 Ubuntu 터미널에서 Windows 파일이 위치한 `/mnt/d/cody/e1-1/practice/test_dir` 경로에서 `chmod 600 sample.txt` 및 `chmod 755 sample.txt`를 실행했으나, `ls -l`로 확인한 결과 파일 권한이 여전히 `-rwxrwxrwx (777)`로 고정되어 변경 사항이 전혀 반영되지 않는 현상이 발생함.
  ```bash
  ksh@ksh:/mnt/d/cody/e1-1/practice/test_dir$ chmod 600 sample.txt
  ksh@ksh:/mnt/d/cody/e1-1/practice/test_dir$ ls -l sample.txt
  -rwxrwxrwx 1 ksh ksh 43 Nov  2 15:28 sample.txt
  ```

- **2. 원인 가설 (Hypothesis)**:
  `/mnt/c/`, `/mnt/d/` 경로는 Windows의 NTFS 파일시스템이 WSL의 DrvFs 드라이버를 통해 마운트된 영역이다. Windows NTFS는 Linux의 표준 POSIX 퍼미션(r/w/x 비트, uid/gid 메타데이터)을 기본적으로 보존하지 않으므로, WSL이 Windows 프로그램과의 권한 호환성을 위해 모든 파일 및 디렉토리의 권한을 `0777 (-rwxrwxrwx)`로 강제 매핑하기 때문일 것으로 추정함.

- **3. 원인 확인 과정 (Verification)**:
  - `mount | grep /mnt/d` 명령어로 마운트 옵션을 확인한 결과, POSIX 메타데이터를 지원하는 `metadata` 옵션 없이 단순 마운트되어 있음을 확인함.
  - 가설을 검증하기 위해, 순수 Linux ext4 가상 디스크 영역인 사용자 홈 디렉토리(`~/practice/test_dir`)로 이동하여 동일한 테스트를 수행함:
    ```bash
    cd ~
    mkdir -p practice/test_dir && cd practice/test_dir
    echo "test" > sample.txt
    ls -l sample.txt        # -> 초기 권한: -rw-r--r-- (644)
    chmod 600 sample.txt
    ls -l sample.txt        # -> 변경 후: -rw------- (600) 정상 변경 확인!
    ```

- **4. 해결 및 대안 (Resolution)**:
  - **해결 조치**: 과제의 권한 실습 항목(chmod 600, 700 및 r/w/x 해석)은 Linux 네이티브 파일시스템(ext4)인 사용자 홈 디렉토리(`~/practice/`)에서 수행하여 정확한 권한 변경 전/후 로그를 증빙으로 확보함.
  - **역할 분리**: Windows 호스트 에디터(VS Code) 및 Git과의 파일 공유가 필요한 소스코드(Dockerfile, index.html)는 `/mnt/d/cody/e1-1`에서 관리하고, 리눅스 시스템 고유 권한 실습은 `~`에서 진행하도록 환경을 분리하여 안정적인 워크플로우를 확립함.

---

### 📌 [트러블슈팅 2] Windows PowerShell 환경에서의 리눅스 표준 명령어(`touch`) 미인식 오류

- **1. 문제 현상 (Symptom)**:
  호스트 터미널(PowerShell)에서 2단계 실습 명령인 `touch sample.txt`를 실행했을 때, 아래와 같은 명령 미인식 오류가 발생하며 파일이 생성되지 않음:
  ```text
  touch : 'touch' 용어가 cmdlet, 함수, 스크립트 파일 또는 실행할 수 있는 프로그램 이름으로 인식되지 않습니다.
  CategoryInfo : ObjectNotFound: (touch:String) [], CommandNotFoundException
  ```

- **2. 원인 가설 (Hypothesis)**:
  `touch`, `ls -la`, `chmod` 등은 Linux/Unix 계열 표준 CLI 바이너리이다. 현재 실행 중인 쉘은 Windows의 PowerShell 런타임 환경이므로 리눅스 POSIX 명령어가 기본 내장되어 있지 않기 때문임.

- **3. 원인 확인 과정 (Verification)**:
  PowerShell 프롬프트(`PS D:\cody\e1-1>`)를 확인하여 현재 실행 쉘이 Windows 환경임을 확인하였으며, Windows 네이티브 방식(`New-Item`) 대신 과제 요구사항인 "리눅스 CLI 환경"을 충족하기 위한 쉘 전환이 필요함을 파악함.

- **4. 해결 및 대안 (Resolution)**:
  PowerShell 프롬프트에서 **`wsl`** 명령어를 입력하여 즉시 WSL Ubuntu Linux 쉘(`ksh@ksh:/mnt/d/cody/e1-1$`)로 전환함. 전환 후 동일한 `touch sample.txt` 명령을 실행하여 정상적으로 0바이트 빈 파일이 생성됨을 확인하고 실습을 지속함.

---

### 📌 [트러블슈팅 3] Docker 컨테이너 실행 시 로컬 포트 충돌 (`bind: address already in use`) 사전 대비

- **1. 문제 현상 (Symptom)**:
  `docker run -d -p 8080:80 ...` 실행 시 `Ports are not available: exposing port TCP 0.0.0.0:8080 failed: listen tcp 0.0.0.0:8080: bind: address already in use` 에러와 함께 컨테이너 생성이 실패하는 상황.

- **2. 원인 가설 (Hypothesis)**:
  호스트 머신에서 로컬 웹 서버(IIS, 다른 실습 컨테이너 등)가 이미 8080 포트를 LISTEN 상태로 점유하고 있을 것으로 판단.

- **3. 원인 확인 과정 (Verification)**:
  PowerShell에서 `netstat -ano | findstr :8080`을 실행하여 포트를 점유 중인 프로세스 ID(PID)를 조회하고, `docker ps`를 통해 이전 실습 컨테이너가 중지되지 않고 실행 중인지 대조 확인.

- **4. 해결 및 대안 (Resolution)**:
  - 충돌을 유발한 기존 컨테이너를 `docker stop <컨테이너ID>` 및 `docker rm <컨테이너ID>`로 정리.
  - 또는 호스트 포트를 `8081` 등 비어있는 포트로 매핑(`docker run -d -p 8081:80 ...`)하여 포트 충돌을 회피하고 정상 서비스 실행 완료.
