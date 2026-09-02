# =============================================================================
# Backend — Production (multi-stage)
# Stage 1 : build  — Node 20 Alpine, full devDeps, compiles TypeScript → dist/
# Stage 2 : runner — Node 20 Alpine, production deps only, non-root user
# Final image ships zero TypeScript tooling; attack surface minimised.
# =============================================================================

# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:20-alpine AS build

WORKDIR /app

COPY backend/package*.json ./
# Install ALL deps (including devDeps for tsc)
RUN npm ci

COPY backend/tsconfig.json ./
COPY backend/src ./src

# Compile TypeScript → dist/
RUN npm run build

# ── Stage 2: Production runner ────────────────────────────────────────────────
FROM node:20-alpine AS production

WORKDIR /app

ENV NODE_ENV=production

COPY backend/package*.json ./
# Production deps only — no tsc, tsx, @types/*, etc.
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled output from build stage
COPY --from=build /app/dist ./dist

EXPOSE 5000

# Drop root privileges — node user ships with the official image
USER node

CMD ["node", "dist/server.js"]
