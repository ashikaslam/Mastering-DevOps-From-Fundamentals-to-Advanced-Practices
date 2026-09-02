# =============================================================================
# Frontend — Development
# Vite 8 / React 19 / Tailwind CSS 4
# Hot-module replacement enabled; source mounted via Docker volume at runtime.
# =============================================================================
FROM node:20-alpine

# Install yarn (corepack ships with Node 20)
RUN corepack enable && corepack prepare yarn@stable --activate

WORKDIR /app

# Install dependencies first (layer cache)
COPY frontend/package.json frontend/yarn.lock ./
RUN yarn install --frozen-lockfile

# Copy source (overridden by bind-mount in dev compose, but useful for plain docker run)
COPY frontend/ .

EXPOSE 5173

# Vite's --host flag makes the dev server accessible outside the container
CMD ["yarn", "dev", "--host"]
