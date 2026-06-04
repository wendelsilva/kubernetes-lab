FROM golang:1.21-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

COPY go.mod main.go ./
RUN go mod tidy

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o task-app .

FROM scratch

COPY --from=builder /app/task-app /task-app

EXPOSE 8080

ENTRYPOINT ["/task-app"]
