# Celery Worker Dockerfile  
# Multi-stage build for production-ready worker container using uv

FROM python:3.11-slim as base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_CACHE_DIR=/tmp/uv-cache \
    C_FORCE_ROOT=1

# Install system dependencies and uv
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/* \
    && pip install uv

# Create app user for security
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set work directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock* ./

# Install Python dependencies using uv (including flower for monitoring)
RUN uv sync --dev && \
    uv add flower && \
    rm -rf /tmp/uv-cache

# Copy application code
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p /app/runs /app/logs && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Health check for worker
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD uv run celery -A worker.celery_app inspect ping || exit 1

# Default command to run Celery worker
CMD ["uv", "run", "celery", "-A", "worker.celery_app", "worker", "--loglevel=info"]