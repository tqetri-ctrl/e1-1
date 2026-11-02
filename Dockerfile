# 1. 베이스 이미지 선택: 보안성과 40MB 이하의 경량성을 갖춘 Nginx Alpine 버전 사용
FROM nginx:alpine

# 2. 메타데이터 라벨 정의: 이미지 관리자 및 버전 정보 명시
LABEL maintainer="tqetri-ctrl <tqetri@gmail.com>"
LABEL description="Custom Nginx Web Server for Workstation Lab"
LABEL version="1.0"

# 3. 환경 변수 주입: 애플리케이션 실행 환경 및 기본 포트 설정
ENV APP_ENV=production
ENV SERVER_PORT=80

# 4. 정적 콘텐츠 교체: 기본 Welcome 페이지를 커스텀 index.html로 덮어쓰기
COPY app/index.html /usr/share/nginx/html/index.html

# 5. 포트 노출 선언 및 실행 명령
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
