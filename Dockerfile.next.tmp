# 빌드 단계
FROM node:20.15.0 AS builder
WORKDIR /app

# 패키지 설치
COPY package.json package-lock.json ./
RUN npm ci

# 애플리케이션 소스 복사
COPY . .

# Next.js 빌드
RUN npm run build

# 실행 단계
FROM node:20.15.0-alpine
WORKDIR /app

# 빌드 아티팩트 및 의존성만 복사
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["npm", "start"]