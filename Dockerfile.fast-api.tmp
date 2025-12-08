# Python 3.13 slim 베이스 이미지 사용
FROM python:3.13-slim

# 기본 환경 변수 설정
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Asia/Seoul \
    APP_PORT=8080

# 작업 디렉터리
WORKDIR /app

# 시스템 패키지 (필요 최소한만)
# - ca-certificates: https 요청 시 인증서 문제 방지 (httpx 등)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Python 의존성 먼저 설치 (Docker 레이어 캐시 효율 ↑)
# requirements.txt는 프로젝트 루트에 있어야 함
COPY requirements.txt /app/requirements.txt

RUN pip install --no-cache-dir -r /app/requirements.txt

# 애플리케이션 소스 코드 복사
COPY . /app

# FastAPI/uvicorn이 리스닝할 포트
EXPOSE 8080

# 컨테이너 기본 실행 커맨드
# APP_PORT 환경변수를 이용해 포트 변경 가능 (기본 8080)
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${APP_PORT}"]
