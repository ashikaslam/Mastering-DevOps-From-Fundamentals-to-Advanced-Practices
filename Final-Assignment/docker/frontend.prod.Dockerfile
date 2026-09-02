# =============================================================================
# Frontend — Production (multi-stage)
# Stage 1 : build — Node 20 Alpine + Yarn → tsc + vite build → dist/
# Stage 2 : serve — nginx Alpine (< 10 MB) serves static assets
# =============================================================================

# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:20-alpine AS build

RUN corepack enable && corepack prepare yarn@stable --activate

WORKDIR /app

# Leverage layer cache: install deps before copying full source
COPY frontend/package.json frontend/yarn.lock ./
RUN yarn install --frozen-lockfile

COPY frontend/ .

# VITE_ env vars must be baked in at build time; pass them as build-args
ARG VITE_API_URL
ARG VITE_SOCKET_URL
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_SOCKET_URL=$VITE_SOCKET_URL

RUN yarn build

# ── Stage 2: Serve ────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS production

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built assets from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Custom nginx config: handle SPA client-side routing (try_files → index.html)
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# nginx runs as PID 1 in foreground
CMD ["nginx", "-g", "daemon off;"]
