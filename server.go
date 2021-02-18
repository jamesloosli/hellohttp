package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"strconv"
	"strings"
	"time"
)

var (
	Version string // sha1 revision used to build the program
	Build   string // when the executable was built
)

func main() {
	http.HandleFunc("/", HelloServer)
	http.HandleFunc("/session/", SessionServer)
	http.HandleFunc("/health", HealthServer)
	http.ListenAndServe(":80", nil)
}

func HelloServer(w http.ResponseWriter, r *http.Request) {
	// Create and seed the generator.
	// Typically a non-fixed seed should be used, such as time.Now().UnixNano().
	// Using a fixed seed will produce the same output on every run.
	rng := rand.New(rand.NewSource(time.Now().UnixNano()))
	nextSession := strconv.Itoa(rng.Int())[:6]
	http.Redirect(w, r, "/session/"+nextSession, 303)
}

func SessionServer(w http.ResponseWriter, r *http.Request) {
	var segments []string
	segments = strings.Split(r.URL.Path, "/")

	fmt.Fprintf(w, "<html><body>")
	fmt.Fprintf(w, "Session; %s</br>", segments[2])
	fmt.Fprintf(w, "Version; %s</br>", Version)
	fmt.Fprintf(w, "For more information, go <a href='https://gitlab.com/roosri/hellohttp'>here</a></br>")
	fmt.Fprintf(w, "</body></html>")
}

func HealthServer(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "helth")
}
