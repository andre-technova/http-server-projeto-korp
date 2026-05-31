FROM golang:1.22-alpine AS builder

WORKDIR /src
COPY app/go.mod ./
COPY app/ ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /bin/http-server-projeto-korp .

FROM alpine:3.20

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /bin/http-server-projeto-korp /app/http-server-projeto-korp
USER appuser
EXPOSE 8080
ENTRYPOINT ["/app/http-server-projeto-korp"]
