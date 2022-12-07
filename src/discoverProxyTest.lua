
local ltn12 = require('ltn12')
local http = require("socket.http")

require("discoverProxy")

local proxyAddress = discoverProxy:findFirstProxy()

print(proxyAddress)

local res_body = {}
local result, code, rheaders, status = http.request({
    url = "http://hourlypricing.comed.com/api?type=currenthouraverage",
    sink = ltn12.sink.table(res_body),
    proxy = "http://" .. proxyAddress,
    headers = {
        ['Content-Type'] = 'application/x-www-urlencoded'
    } })

print(result)
print(code)
print(rheaders)
print(status)
print(table.concat(res_body))
