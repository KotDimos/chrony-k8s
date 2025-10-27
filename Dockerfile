ARG CHRONY_VERSION="4.8"

FROM alpine:3.22 AS builder-chronyd

WORKDIR /workspace
RUN apk add --no-cache \
        automake \
        autoconf \
        libtool \
        build-base \
        bison \
        asciidoctor \
        libcap-dev \
        libcap-static \
        git

ARG CHRONY_VERSION
RUN git clone --branch $CHRONY_VERSION https://gitlab.com/chrony/chrony

WORKDIR /workspace/chrony
RUN echo "$CHRONY_VERSION" > version.txt && \
    CFLAGS="-static" LDFLAGS="-static" ./configure --prefix=/opt/chrony && \
    make install && \
    chmod +x /opt/chrony/bin/chronyc /opt/chrony/sbin/chronyd && \
    chown 65535:65535 /opt/chrony/bin/chronyc /opt/chrony/sbin/chronyd


FROM golang:1.25 AS builder-app

WORKDIR /workspace
COPY go.mod .
RUN go mod download

COPY main.go .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o chrony-k8s main.go && \
    chmod +x chrony-k8s && \
    chown 65535:65535 chrony-k8s


FROM alpine:3.22 AS users
RUN echo "chrony:x:65535:65535:chrony:/:/sbin/nologin" > /etc/passwd && \
    echo "chrony:x:65535:" > /etc/group && \
    echo "chrony:!::0:::::" > /etc/shadow


FROM gcr.io/distroless/base-debian12:nonroot

COPY --from=builder-chronyd /opt/chrony/bin/chronyc /usr/local/bin/chronyc
COPY --from=builder-chronyd /opt/chrony/sbin/chronyd /usr/local/bin/chronyd

COPY --from=builder-app /workspace/chrony-k8s /usr/local/bin/chrony-k8s

COPY --from=users /etc/passwd /etc/passwd
COPY --from=users /etc/group /etc/group
COPY --from=users /etc/shadow /etc/shadow

USER 65535:65535
ENTRYPOINT ["/usr/local/bin/chrony-k8s"]
