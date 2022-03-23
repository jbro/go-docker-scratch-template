FROM golang:alpine as builder

WORKDIR /src
COPY . .

RUN apk --no-cache add build-base \
  git \
  ca-certificates \
  tzdata

RUN go build -a -ldflags="-w -s -extldflags=-static -linkmode external" -o out ./...
RUN file out
RUN stat out

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=builder /src/out /app

CMD /app
