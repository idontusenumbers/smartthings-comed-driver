-- smartthings libraries
local capabilities = require "st.capabilities"
local Driver = require "st.driver"
local log = require "log"
local utils = require "st.utils"

local cosock = require "cosock"
local http = cosock.asyncify "socket.http"
local ltn12 = require('ltn12')

local JSON = require("JSON")

require("discoverProxy")

local GLOBAL_ID = "comedhourly"

local timer = nil
local timerDevice = nil

-- https://github.com/SmartThingsDevelopers/SampleDrivers/blob/0fd6db1b41dc6f993e364d40795b777f284c762d/thingsim/rpcclient/src/discovery.lua

local function destroy(device)
    if timer then
        device.thread:cancel_timer(timer)
    end
end

local function refreshValue()

    local proxyAddress = discoverProxy:findFirstProxy()

    log.info(string.format("Using proxy address: %s", proxyAddress))

    local responseBody = {}
    local result, code, responseHeaders, status = http.request({
        url = "http://hourlypricing.comed.com/api?type=currenthouraverage",
        sink = ltn12.sink.table(responseBody),
        proxy = "http://" .. proxyAddress,
        headers = {
            ['Content-Type'] = 'application/x-www-urlencoded'
        } })

    local responseString = table.concat(responseBody)

    log.info(string.format("Comed response: %s (%s): %s", status, code, responseString))

    local responseTable = JSON:decode(responseString)[1]
    log.info(string.format("Comed response table:%s", utils.stringify_table(responseTable)))

    local price = responseTable.price
    log.info(string.format("Comed price: %s", price))

    timerDevice:emit_event(capabilities.powerMeter.power(math.floor(price)))
end

local function initialize_device_state(device)
    log.info("[" .. tostring(device.id) .. "] Initializing Comed hourly device")

    if not timer then
        timerDevice = device
        timer = device.thread:call_on_schedule(60 * 5, refreshValue) -- 5 min
        refreshValue()
    end

end

local function device_init(driver, device)
    initialize_device_state(device)
end

local function device_added(driver, device)
    initialize_device_state(device)
end

local function device_removed(driver, device)
    destroy(device)
end

local function discovery_handler(driver, options, should_continue)
    log.info("Starting discovery")
    local known_devices = {}

    -- get a list of devices already added
    local device_list = driver:get_devices()
    for i, device in ipairs(device_list) do
        local id = device.device_network_id
        log.info(string.format("Already know about %s ", id))
        known_devices[id] = true
    end

    local id = GLOBAL_ID
    local name = "Comed Hourly"

    if known_devices[id] then
        log.info(string.format("already know about %s ", id))
    else
        known_devices[id] = true
        local metadata = {
            type = "LAN",
            device_network_id = id,
            label = name,
            profile = "net.obive.comedhourly.v1",
            manufacturer = "obive",
            model = "Comed Hourly",
            vendor_provided_label = name
        }
        log.info(string.format("adding %s: %s ", id, utils.stringify_table(metadata)))
        local result = driver:try_create_device(metadata)
        log.info(string.format("add result: %s ", result))
        assert(result, "failed to send found_device")
    end
    log.info("exiting discovery")
end

----------------------------------------------------------------------------------------------------
-- Command Handlers
----------------------------------------------------------------------------------------------------

function handle_on(driver, device, command)
    log.info("switch on", device.id)
end

function handle_off(driver, device, command)
    log.info("switch off", device.id)
end

----------------------------------------------------------------------------------------------------
-- Build and Run Driver
----------------------------------------------------------------------------------------------------

local comedhourly_driver = Driver("comedhourly",
        {
            discovery = discovery_handler,
            lifecycle_handlers = {
                added = device_added,
                init = device_init,
                removed = device_removed,
            },
            capability_handlers = {
                [capabilities.switch.ID] = {
                    [capabilities.switch.commands.on.NAME] = handle_on,
                    [capabilities.switch.commands.off.NAME] = handle_off
                },
            }
        }
)

comedhourly_driver.bulb_handles = {}

comedhourly_driver:run()
