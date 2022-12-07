# Overview
This virtual device that represents the current Comed hourly pricing average. The device pretends to be a power meter and will have a watt rating of the current hourly price in cents per killowatt hour. For example, if the price is 6 cents per killowatt hour, the power meter will read 6. For reference, the cost can go negative!

Once setup, the SmartThings hub will poll the Comed hourly pricing API (http://hourlypricing.comed.com/api?type=currenthouraverage) at 5 min intervals.


# Installation
Repackage, redeploy, rerun, reattach console
```shell
smartthings edge:drivers:package && smartthings edge:channels:assign a9f857d7-839d-4c7e-88ae-5b2e66f5ad97 && smartthings edge:drivers:install a9f857d7-839d-4c7e-88ae-5b2e66f5ad97 &&  smartthings edge:drivers:logcat --hub-address=10.0.0.152 a9f857d7-839d-4c7e-88ae-5b2e66f5ad97
```

Once the console attaches and starts logging, you can use ctrl-c to close the connection but the device will remain running.

Once running, add the device:
1. Open SmartThings
2. Tap add device
3. Tap scan
4. (Device is automatically discovered and automatically added)

You will need to run a proxy locally, see the following section.


# Proxy Required!
Unfortunately, the Samsung SmartThings hub cannot talk to public (internet) IP addresses; it can only talk to private (local) IP addresses. To reach Comed, you must run a proxy server.

The provided proxy server has been written in Go and will use very little memory and CPU (I measured ~10MB memory). It can be run anywhere on the local network.

Instead of relying on a configuration value, UDP multicast is used to discover this proxy. The proxy discovery happens every time the device polls.

Build for current platform:
```shell
cd comedproxy
go build -o bin/comedproxy main.go
```
Cross compile to Linux:
```shell
GOOS=linux GOARCH=amd64 go build -o bin/comedproxy main.go
```


# External reference and documentation

https://developer.smartthings.com/docs/devices/hub-connected/first-lua-driver/


LUA SDK reference
https://developer.smartthings.com/docs/edge-device-drivers/

LUA SDK Timer
https://developer.smartthings.com/docs/edge-device-drivers/thread.html

Sample UDP discovery
https://github.com/SmartThingsDevelopers/SampleDrivers/blob/0fd6db1b41dc6f993e364d40795b777f284c762d/thingsim/rpcclient/src/discovery.lua

Setting up dev env
https://developer.smartthings.com/docs/devices/hub-connected/set-up-dev-env/


# Historical
Original groovy code:
https://github.com/idontusenumbers/SmartThingsPublic/blob/master/smartapps/idontusenumbers/comed-price-automation.src/comed-price-automation.groovy

