### Frontend production build (React) multi-stage container
### Stage 1: Build static assets using a pinned Node.js version
FROM node:18-alpine AS build
WORKDIR /app
ENV CI=true
ENV NODE_OPTIONS=--openssl-legacy-provider
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm npm install --no-audit --no-fund
COPY . .
RUN npm run build

### Stage 2: Use Nginx stable to serve static content (smaller attack surface)
FROM nginx:1.27.2-alpine
WORKDIR /usr/share/nginx/html
COPY --from=build /app/build .
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
