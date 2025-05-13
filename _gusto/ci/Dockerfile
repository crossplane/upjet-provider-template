# syntax=docker/dockerfile:1.2

##
## Build
##
FROM golang:1.24-bookworm AS builder

WORKDIR /app
RUN install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc ; \
    chmod a+r /etc/apt/keyrings/docker.asc ; \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null ; \
    apt-get update ; \
    apt-get install docker.io docker-buildx-plugin npm -y ; \
    npm install --global yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY go.mod ./
COPY go.sum ./

RUN go mod download

RUN chown -R $(id -gn):$(whoami) /app 2>/dev/null || true
