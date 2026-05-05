# Stage 1: Build
FROM node:22.12.0-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

# CI에서 GitHub Secrets → .env.production 생성 후 빌드 컨텍스트에 포함됨
# Vite가 빌드 시 .env.production 을 자동으로 읽으므로 별도 ARG 불필요
COPY . .
RUN npm run build

# Stage 2: Serve
FROM nginx:alpine AS runner

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
