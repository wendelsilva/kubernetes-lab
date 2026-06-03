package main

import (
	"database/sql"
	"embed"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"strconv"
	"time"

	_ "github.com/lib/pq"
)

//go:embed templates/*
var templatesFS embed.FS

type Task struct {
	ID        int
	Title     string
	Done      bool
	CreatedAt time.Time
}

type PageData struct {
	Tasks    []Task
	Hostname string
}

var db *sql.DB

func main() {
	// Lendo configurações do banco de dados via variáveis de ambiente (padrão 12-factor app)
	dbHost := getEnv("DB_HOST", "localhost")
	dbPort := getEnv("DB_PORT", "5432")
	dbUser := getEnv("DB_USER", "postgres")
	dbPassword := getEnv("DB_PASSWORD", "postgres")
	dbName := getEnv("DB_NAME", "tasks")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)

	// Loop de tolerância a falhas para conexão com o banco de dados
	var err error
	log.Printf("Conectando ao banco de dados em %s:%s...", dbHost, dbPort)
	for i := 0; i < 15; i++ {
		db, err = sql.Open("postgres", connStr)
		if err == nil {
			err = db.Ping()
		}
		if err == nil {
			break
		}
		log.Printf("Banco de dados indisponível (tentativa %d/15). Reconectando em 2 segundos...", i+1)
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		log.Fatalf("Falha crítica ao conectar ao banco de dados: %v", err)
	}

	log.Println("Conexão com o banco de dados estabelecida com sucesso!")

	// Migração simples de banco de dados
	createTableQuery := `
	CREATE TABLE IF NOT EXISTS tasks (
		id SERIAL PRIMARY KEY,
		title VARCHAR(255) NOT NULL,
		done BOOLEAN DEFAULT FALSE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);`
	_, err = db.Exec(createTableQuery)
	if err != nil {
		log.Fatalf("Erro ao executar migrações: %v", err)
	}
	log.Println("Tabelas do banco de dados verificadas/criadas!")

	// Roteamento
	http.HandleFunc("/", handleIndex)
	http.HandleFunc("/add", handleAdd)
	http.HandleFunc("/toggle", handleToggle)
	http.HandleFunc("/delete", handleDelete)
	http.HandleFunc("/healthz", handleHealth)

	port := getEnv("PORT", "8080")
	log.Printf("Servidor iniciado na porta %s...", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Erro ao iniciar o servidor: %v", err)
	}
}

// Retorna uma variável de ambiente ou um valor padrão
func getEnv(key, defaultValue string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return defaultValue
}

// Renderiza a página principal com as tarefas
func handleIndex(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}

	rows, err := db.Query("SELECT id, title, done, created_at FROM tasks ORDER BY created_at DESC")
	if err != nil {
		http.Error(w, fmt.Sprintf("Erro ao buscar tarefas: %v", err), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var t Task
		if err := rows.Scan(&t.ID, &t.Title, &t.Done, &t.CreatedAt); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		tasks = append(tasks, t)
	}

	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown-pod"
	}

	data := PageData{
		Tasks:    tasks,
		Hostname: hostname,
	}

	tmpl, err := template.ParseFS(templatesFS, "templates/index.html")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	tmpl.Execute(w, data)
}

// Cria uma nova tarefa
func handleAdd(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	title := r.FormValue("title")
	if title != "" {
		_, err := db.Exec("INSERT INTO tasks (title) VALUES ($1)", title)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// Inverte o estado de concluído de uma tarefa
func handleToggle(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	idStr := r.FormValue("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "ID inválido", http.StatusBadRequest)
		return
	}

	_, err = db.Exec("UPDATE tasks SET done = NOT done WHERE id = $1", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// Remove uma tarefa
func handleDelete(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Redirect(w, r, "/", http.StatusSeeOther)
		return
	}

	idStr := r.FormValue("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "ID inválido", http.StatusBadRequest)
		return
	}

	_, err = db.Exec("DELETE FROM tasks WHERE id = $1", id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// Liveness e Readiness Probe para o Kubernetes
func handleHealth(w http.ResponseWriter, r *http.Request) {
	if err := db.Ping(); err != nil {
		w.WriteHeader(http.StatusServiceUnavailable)
		w.Write([]byte("DATABASE_UNAVAILABLE"))
		return
	}
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}
