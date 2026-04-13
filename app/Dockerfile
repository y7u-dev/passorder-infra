FROM node:18-alpine

# 보안: root 대신 node 유저 사용
USER node

WORKDIR /app

# 의존성 먼저 복사 (캐시 활용)
COPY --chown=node:node package*.json ./
RUN npm ci --only=production

# 소스코드 복사
COPY --chown=node:node src/ ./src/

EXPOSE 3000

CMD ["node", "src/index.js"]