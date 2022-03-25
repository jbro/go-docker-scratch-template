FROM golang:alpine as builder

WORKDIR /go/src
COPY . .

RUN apk --no-cache add git file

# Install gcc and libc so we can do static and external linking
RUN apk --no-cache add gcc musl-dev

# Install Alpine standar CA chain so we can copy this in to our scratch image later
RUN apk --no-cache add ca-certificates

# Install Alpine timezone so we can copy these in to our scratch image later
RUN apk --no-cache add tzdata

# Build our app as a static binary
# -w and -s should be removed if you want to keep debug symbols in your binary
# -linkmode external forces go to use external linking even if you are not using
# a module that requires CGO_ENABLED=1, if this is omited then the -extldflags is ignored
RUN go build -a -ldflags="-w -s -extldflags=-static -linkmode external" -o app ./...

# Canary, this make the build fail if app isn't staically linked
RUN file app | grep -q 'statically linked'

FROM scratch

# Copy in the CA chain
# If your know which CA certificates your applications will need, that is if you don't
# need to query arbitrary hosts, you can just copy in the ones you need, and skip this step.
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy in all the timezeon
# If you only need a subset you can just copy that in to save some space
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy in the app
COPY --from=builder /go/src/app /app

# Run the app
# You need to use the array syntax here (exec form), otherwise docker will use /bin/sh to execute, which
# isn't in the image
CMD ["/app"]
