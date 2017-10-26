function startup()
    --start_graphics()
    startSplunkLook()
end
dofile("config.lua")
dofile("wifi.lua")
dofile("spinner.lua")
dofile("graphics.lua")
print("Here's our safety pause...")
tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)

