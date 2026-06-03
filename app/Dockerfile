# ==========================================
# Estágio de Compilação (Build Stage)
# ==========================================
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Instala dependências de build necessárias para baixar módulos
RUN apk add --no-cache git

# Copia o arquivo de módulos e o código principal para resolver dependências
COPY go.mod main.go ./
RUN go mod tidy

# Copia o código fonte e os templates
COPY . .

# Compila o binário otimizado
# - CGO_ENABLED=0 remove a dependência de bibliotecas C dinâmicas (libc)
# - GOOS=linux força a compilação para o SO Linux
# - ldflags "-s -w" remove tabelas de símbolos e informações de depuração, reduzindo o tamanho
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o task-app .

# ==========================================
# Estágio de Execução Mínimo (Runtime Stage)
# ==========================================
FROM scratch

# Copia o binário compilado do estágio anterior
COPY --from=builder /app/task-app /task-app

# Expõe a porta interna da aplicação
EXPOSE 8080

# Inicia o servidor web
ENTRYPOINT ["/task-app"]
