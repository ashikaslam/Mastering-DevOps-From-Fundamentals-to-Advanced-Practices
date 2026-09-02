# =============================================================================
# Backend — Development
# Node 20 Alpine / Express / Socket.IO / TypeScript
# Uses `tsx watch` for live reload without a separate compile step.
# Source is mounted via Docker volume at runtime.
# =============================================================================
FROM node:20-alpine

WORKDIR /app

# Install dependencies first (layer cache)
COPY backend/package*.json ./
RUN npm ci

# Copy source (overridden by bind-mount in dev compose, but useful for plain docker run)
COPY backend/ .

EXPOSE 5000

ENV NODE_ENV=development

# tsx watch restarts automatically on any *.ts file change
CMD ["npm", "run", "dev"]
