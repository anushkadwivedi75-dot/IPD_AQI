# ==========================================
# Stage 1: Build Flutter Web Application
# ==========================================
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Enable web support and disable analytics in builder
RUN flutter config --no-analytics && \
    flutter config --enable-web

# Copy dependency specifications first for layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy frontend source code
COPY . .

# Optional build argument for backend API base URL
# Default empty string allows Nginx reverse-proxy routing
ARG API_BASE_URL=""
ENV API_BASE_URL=${API_BASE_URL}

# Build production Flutter Web bundle
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ==========================================
# Stage 2: Production Nginx Server
# ==========================================
FROM nginx:alpine AS runner

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy custom Nginx configuration with SPA routing and API reverse proxy
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled web bundle from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:80/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
