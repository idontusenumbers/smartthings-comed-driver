package discovery

import (
	"encoding/hex"
	"log"
	"net"
	"strconv"
)

const (
	maxDatagramSize = 8192
)

func ListenDiscover(address string, response []byte, handler func(*net.UDPAddr, []byte, int, []byte)) {
	// Parse the string address
	addr, err := net.ResolveUDPAddr("udp4", address)
	if err != nil {
		log.Fatal(err)
	}

	// Open up a connection
	conn, err := net.ListenMulticastUDP("udp4", nil, addr)
	if err != nil {
		log.Fatal(err)
	}
	err = conn.SetReadBuffer(maxDatagramSize)
	if err != nil {
		log.Fatal(err)
	}

	// Loop forever reading from the socket
	for {
		buffer := make([]byte, maxDatagramSize)
		numBytes, src, err := conn.ReadFromUDP(buffer)
		if err != nil {
			log.Fatal("ReadFromUDP failed:", err)
		}

		handler(src, response, numBytes, buffer)
	}
}

func DiscoverHandler(src *net.UDPAddr, response []byte, n int, b []byte) {
	log.Println(n, "bytes read from", src)
	log.Println(hex.Dump(b[:n]))

	// The payload should be the port the discovery request wants the discovery response sent to
	port, err := strconv.Atoi(string(b[:n]))

	if err != nil {
		log.Fatal(err)
	}

	// Open socket to discovery requester
	dst := net.UDPAddr{IP: src.IP, Port: port}
	conn, err := net.DialUDP("udp", nil, &dst)
	if err != nil {
		log.Fatal(err)
	}

	// Send the discovery response
	_, err = conn.Write(response)
	if err != nil {
		log.Fatal(err)
	}

	log.Println("Sent discovery response to ", dst)
}
