package main


import (
	"log"
	"net/http"
	"os"
	"path"
)


func main() {
	userHomeDir, err := os.UserHomeDir()
	if err != nil { log.Fatal(err) }
	fileServer := http.FileServer(http.Dir(path.Join(userHomeDir, "Thwump/media")))
	http.Handle("/", fileServer)
	err = http.ListenAndServe("localhost:10003", nil)
	if err != nil { log.Fatal(err) }
}
