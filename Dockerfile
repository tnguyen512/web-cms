############################################
# Build stage
############################################
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files first for better layer caching
COPY package.json ./
COPY package-lock.json ./

# Install all dependencies (including dev) for building
RUN npm ci

# Copy scripts needed for building
COPY scripts ./scripts

# Copy extensions folder
COPY extensions ./extensions

# Build extensions if they exist
RUN if [ -d "extensions" ] && [ "$(ls -A extensions)" ]; then \
        npm run build-extensions; \
    else \
        echo "No extensions to build"; \
    fi

# Copy rest of source code
COPY . .

############################################
# Runtime stage
############################################
FROM node:22-alpine

WORKDIR /app

ENV NODE_ENV=production

# Copy package files
COPY package.json ./
COPY package-lock.json ./

# Install production dependencies only
RUN npm ci --omit=dev

# Copy built extensions from builder stage (includes dist folders)
COPY --from=builder /app/extensions ./extensions

# Copy other necessary files from builder
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/snapshot ./snapshot
COPY --from=builder /app/*.js ./

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8055

ENTRYPOINT ["docker-entrypoint.sh"]
