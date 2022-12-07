package proxy

import (
	"crypto/tls"
	"io"
	"log"
	"net"
	"net/http"
	"regexp"
	"strconv"
	"time"
)

var portExtract = regexp.MustCompile(":(\\d+)")

func FindAvailablePort() int {
	l, err := net.Listen("tcp", ":0")
	if err != nil {
		panic(err)
	}

	err = l.Close()
	if err != nil {
		panic(err)
	}

	submatch := portExtract.FindSubmatch([]byte(l.Addr().String()))

	result, err := strconv.Atoi(string(submatch[1]))

	if err != nil {
		panic(err)
	}

	return result
}

func handleTunneling(w http.ResponseWriter, r *http.Request) {
	dest_conn, err := net.DialTimeout("tcp", r.Host, 10*time.Second)
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	w.WriteHeader(http.StatusOK)
	hijacker, ok := w.(http.Hijacker)
	if !ok {
		http.Error(w, "Hijacking not supported", http.StatusInternalServerError)
		return
	}
	client_conn, _, err := hijacker.Hijack()
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
	}
	go transfer(dest_conn, client_conn)
	go transfer(client_conn, dest_conn)
}
func transfer(destination io.WriteCloser, source io.ReadCloser) {
	defer destination.Close()
	defer source.Close()
	io.Copy(destination, source)
}
func handleHTTP(w http.ResponseWriter, req *http.Request) {
	// Remove the Connection header which causes an incompatible http2 upgrade
	headers := req.Header
	headers.Del("Connection")

	resp, err := http.DefaultClient.Do(&http.Request{
		Method:           req.Method,
		URL:              req.URL,
		Header:           headers,
		Body:             req.Body,
		ContentLength:    req.ContentLength,
		TransferEncoding: req.TransferEncoding,
	})

	// We can't do a RoundTrip because it won't follow redirects, usually leading to an HTTPS redirect which breaks on the client
	//resp, err := http.DefaultTransport.RoundTrip(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}
	defer resp.Body.Close()
	copyHeader(w.Header(), resp.Header)
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}
func copyHeader(dst, src http.Header) {
	for k, vv := range src {
		for _, v := range vv {
			dst.Add(k, v)
		}
	}
}

func StartProxy(port int) {

	/*
		var pemPath string
		flag.StringVar(&pemPath, "pem", "server.pem", "path to pem file")
		var keyPath string
		flag.StringVar(&keyPath, "key", "server.key", "path to key file")
		var proto string
		flag.StringVar(&proto, "proto", "https", "Proxy protocol (http or https)")
		flag.Parse()
		if proto != "http" && proto != "https" {
			log.Fatal("Protocol must be either http or https")
		}*/
	server := &http.Server{
		Addr: ":" + strconv.Itoa(port),
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			log.Println(r)
			if r.Method == http.MethodConnect {
				handleTunneling(w, r)
			} else {
				handleHTTP(w, r)
			}
		}),
		// Disable HTTP/2.
		TLSNextProto: make(map[string]func(*http.Server, *tls.Conn, http.Handler)),
	}
	//if proto == "http" {
	log.Fatal(server.ListenAndServe())
	//} else {
	//	log.Fatal(server.ListenAndServeTLS(pemPath, keyPath))
	//}

}
