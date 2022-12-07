package main

import (
	"comedproxy/discovery"
	"comedproxy/proxy"
	"strconv"
)

const (
	address = "225.0.0.37:18830"
)

func main() {

	println("Starting proxy")

	//port := proxy.FindAvailablePort()
	port := 18888

	go proxy.StartProxy(port)

	println("Proxy listening on port ", port)

	println("Listening for discovery discovery requests at", address)

	discovery.ListenDiscover(address, []byte(strconv.Itoa(port)), discovery.DiscoverHandler)
}
