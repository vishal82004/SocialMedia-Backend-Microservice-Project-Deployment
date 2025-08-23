#use the official node js 18 alpine linux image as the base image
FROM node:18-alpine AS builder
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
FROM node:18-alpine AS final
WORKDIR /usr/src/app
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app .
EXPOSE 3004
CMD ["node", "src/server.js"]