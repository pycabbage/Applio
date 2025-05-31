# syntax=docker/dockerfile:1

FROM python:3.11-bullseye AS base

# Set up working directory
WORKDIR /app

FROM base AS runner_base

# Install system dependencies, clean up cache to keep image size small
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    mv /etc/apt/apt.conf.d/docker-clean /tmp/docker-clean && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    apt update && apt-get --no-install-recommends install -y ffmpeg && \
    mv /tmp/docker-clean /etc/apt/apt.conf.d/docker-clean && rm /etc/apt/apt.conf.d/keep-cache

FROM base AS builder

# Use uv to run the app with the specified port
RUN \
    --mount=type=cache,target=/root/.cache/uv,sharing=locked \
    --mount=type=bind,from=ghcr.io/astral-sh/uv:0.7.9,source=/uv,target=/usr/local/bin/uv,readonly \
    --mount=type=bind,source=pyproject.toml,target=/app/pyproject.toml,readonly \
    --mount=type=bind,source=uv.lock,target=/app/uv.lock,readonly \
    UV_LINK_MODE=copy uv sync --locked --no-install-project --no-editable

FROM runner_base AS runner

# Expose the required port
EXPOSE 6969

COPY . .
COPY --from=builder /app/.venv /app/

# Define volumes for persistent storage
VOLUME ["/app/logs/"]

# Set environment variables if necessary
ENV PATH="/app/.venv/bin:$PATH"

# Run the app
ENTRYPOINT ["python3"]
CMD ["app.py"]
