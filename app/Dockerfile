FROM node:18-alpine

WORKDIR /app

# 먼저 소유권 설정 후 USER 변경
COPY --chown=node:node package*.json ./
RUN npm ci --only=production

COPY --chown=node:node src/ ./src/

# 마지막에 USER 설정
USER node

EXPOSE 3000

CMD ["node", "src/index.js"]