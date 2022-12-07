print("starting")

local socket = require 'socket'
local group = "225.0.0.37"
local sendPort = 18830
local timeout = 1

discoverProxy = {}

function discoverProxy.broadcast(s, message, port)
    --assert(broadcaster:setoption('broadcast', true))
    --assert(broadcaster:setoption('dontroute', true))   -- do we need this?

    print(('Broadcasting %q to %s:%i'):format(message, group, port))
    assert(s:sendto(message, group, port))
    --broadcaster:close()

end

function countTableEntries(t)
    size = 0
    for _ in pairs(t) do
        size = size + 1
    end
    return size
end

function discoverProxy.findFirstProxy()

    local listener = assert(socket.udp())
    assert(listener:setsockname("0.0.0.0", 0)) -- pick random port; specifying a port causes permission error; maybe because it's already in use?

    local listenIp, listenPort = listener:getsockname()
    print(('Listening for discovery response on %s:%i'):format(listenIp, listenPort))

    local clients, starttime = {}

    listener:settimeout(timeout)

    discoverProxy.broadcast(listener, tostring(listenPort), sendPort)

    starttime = socket.gettime()
    repeat
        local val, rip, rport = listener:receivefrom()
        if val then
            print(('Got discovery response: %s:%i'):format(rip, val))
            clients[rip] = val;
        end
    until socket.gettime() - starttime > timeout

    listener:close()

    print(('Got %i discovery responses'):format(countTableEntries(clients)))

    for k, v in pairs(clients) do
        return ('%s:%i'):format(k, v)
    end


end
