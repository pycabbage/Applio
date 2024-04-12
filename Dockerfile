# syntax=docker/dockerfile:1

FROM python:3.10-bullseye

EXPOSE 6969

WORKDIR /app

ARG DEBIAN_FRONTEND=noninteractive

# Cache apt packages with Docker
# https://docs.docker.com/reference/dockerfile/#example-cache-apt-packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt update && \
  apt-get install -y -qq apt-utils && \
  apt-get install -y -qq --no-install-recommends ffmpeg aria2 ca-certificates

# By caching the pip module file with Docker, the build time is reduced while suppressing the image file.
RUN --mount=type=cache,mode=0755,target=/root/.cache/pip \
  --mount=type=bind,source=requirements.txt,target=requirements.txt \
  python3 -m pip install -U pip && \
  pip3 install -r requirements.txt

# Copying the files after installing dependencies prevents the cache from becoming invalidated when files other than requirements.txt change.
COPY . .

VOLUME [ "/app/logs", "/app/opt", "/app/rvc/pretraineds" ]

ENTRYPOINT [ "python3" ]

CMD ["app.py"]
