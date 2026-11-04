# ==========================================
# Stage 1: Build & Dependency Wheel Compiler
# ==========================================
FROM python:3.12-slim AS builder

WORKDIR /build

# Prevent python from buffering and writing bytecode
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install build essentials if native extensions are required
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ==========================================
# Stage 2: Minimal Runtime for Cloud Run
# ==========================================
FROM python:3.12-slim AS runner

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    PATH="/home/appuser/.local/bin:$PATH"

# Create non-privileged user and group for security
RUN groupadd -r appgroup && useradd -r -g appgroup -d /home/appuser -m appuser

# Copy installed wheels from builder to non-root user home
COPY --from=builder /root/.local /home/appuser/.local
RUN chown -R appuser:appgroup /home/appuser/.local

# Copy application source code
COPY --chown=appuser:appgroup app /app/app
COPY --chown=appuser:appgroup openapi.json /app/openapi.json

# Switch to non-root user
USER appuser

# Cloud Run health check container port
EXPOSE 8080

# Graceful termination (SIGTERM) with dynamic Cloud Run PORT binding
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080} --loop uvloop --http httptools --proxy-headers --forwarded-allow-ips='*'"]
