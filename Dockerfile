FROM golang:alpine as builder

WORKDIR /src
COPY . .

RUN apk --no-cache add build-base \
  git \
  ca-certificates \
  tzdata

RUN CGO_ENABLED=1 go build -a -ldflags="-extldflags=-static" -o out ./...
RUN file out

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=builder /src/out /app

CMD /app
