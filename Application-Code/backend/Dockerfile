### Backend production build (Node.js) multi-stage container

### Stage 1: Builder - Install all dependencies and copy source code
FROM node:18-alpine AS builder
WORKDIR /usr/src/app
COPY package*.json ./
# Use BuildKit cache to speed up dependency installation
RUN --mount=type=cache,target=/root/.npm npm install
COPY . .

### Stage 2: Production - Create a lean production image
FROM node:18-alpine
WORKDIR /usr/src/app

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy only necessary files from the builder stage
COPY --from=builder /usr/src/app/package*.json ./

# Install only production dependencies and use the cache
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

# Copy application code from the builder stage and set permissions
COPY --from=builder --chown=appuser:appgroup /usr/src/app .

# Switch to the non-root user
USER appuser

EXPOSE 3500
CMD ["node", "index.js"]
