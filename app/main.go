package main

import (
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "os"
    "sync/atomic"
    "time"
)

type response struct {
    Nome    string `json:"nome"`
    Horario string `json:"horario"`
}

var totalRequests uint64
var lastRequestUnix uint64

func main() {
    port := getenv("PORT", "8080")

    mux := http.NewServeMux()
    mux.HandleFunc("/projeto-korp", projetoKorpHandler)
    mux.HandleFunc("/metrics", metricsHandler)

    server := &http.Server{
        Addr:              ":" + port,
        Handler:           loggingMiddleware(mux),
        ReadHeaderTimeout: 5 * time.Second,
    }

    log.Printf("http-server-projeto-korp iniciado na porta %s", port)
    if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
        log.Fatalf("erro ao iniciar servidor: %v", err)
    }
}

func projetoKorpHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet {
        http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
        return
    }

    now := time.Now().UTC()
    atomic.AddUint64(&totalRequests, 1)
    atomic.StoreUint64(&lastRequestUnix, uint64(now.Unix()))

    w.Header().Set("Content-Type", "application/json; charset=utf-8")
    w.WriteHeader(http.StatusOK)

    payload := response{
        Nome:    "Projeto Korp",
        Horario: now.Format(time.RFC3339),
    }

    if err := json.NewEncoder(w).Encode(payload); err != nil {
        log.Printf("erro ao gerar resposta JSON: %v", err)
    }
}

func metricsHandler(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodGet {
        http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
        return
    }

    requests := atomic.LoadUint64(&totalRequests)
    lastRequest := atomic.LoadUint64(&lastRequestUnix)

    w.Header().Set("Content-Type", "text/plain; version=0.0.4; charset=utf-8")
    w.WriteHeader(http.StatusOK)

    fmt.Fprintf(w, "# HELP http_server_projeto_korp_up Disponibilidade do servico http-server-projeto-korp.\n")
    fmt.Fprintf(w, "# TYPE http_server_projeto_korp_up gauge\n")
    fmt.Fprintf(w, "http_server_projeto_korp_up 1\n")

    fmt.Fprintf(w, "# HELP http_requests_total Total de requisicoes recebidas no endpoint /projeto-korp.\n")
    fmt.Fprintf(w, "# TYPE http_requests_total counter\n")
    fmt.Fprintf(w, "http_requests_total{service=\"http-server-projeto-korp\",endpoint=\"/projeto-korp\"} %d\n", requests)

    fmt.Fprintf(w, "# HELP http_server_last_request_timestamp_seconds Timestamp Unix da ultima requisicao recebida no endpoint /projeto-korp.\n")
    fmt.Fprintf(w, "# TYPE http_server_last_request_timestamp_seconds gauge\n")
    fmt.Fprintf(w, "http_server_last_request_timestamp_seconds{service=\"http-server-projeto-korp\"} %d\n", lastRequest)
}

func loggingMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        next.ServeHTTP(w, r)
        log.Printf("method=%s path=%s remote=%s duration=%s", r.Method, r.URL.Path, r.RemoteAddr, time.Since(start))
    })
}

func getenv(key, fallback string) string {
    value := os.Getenv(key)
    if value == "" {
        return fallback
    }
    return value
}
