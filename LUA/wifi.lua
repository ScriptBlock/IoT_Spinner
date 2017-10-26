--geeze..
--nz


stationConfig = {}
stationConfig.save = false

candidateAP = nil
lastAP = "XAXAXXXXXAXA"

wifiTrys     = 0

function launchUpload()
  print("Connected to WIFI!")
  print("IP Address: " .. wifi.sta.getip())
  internalIP = wifi.sta.getip()
  candidateAP = wifi.sta.getconfig():match("^([^%d]+)")
  http.get(config.externalIPLookupURL, nul, function(code, data)
    if code >= 0 then
      matchedIP = data:match("^(%d+\.%d+\.%d+\.%d+)")
      if matchedIP ~= nil then
        externalIP = matchedIP
      else
        externalIP = "x.x.x.x"
      end
    end
    uploadSpins()
  end)
end


function checkWIFIForUpload() 
  tries = tonumber(config.NUMWIFITRYS)
  if ( wifiTrys > tries ) then
    print("Sorry. Not able to connect")
  else
    ipAddr = wifi.sta.getip()
    if ( ( ipAddr ~= nil ) and  ( ipAddr ~= "0.0.0.0" ) ) then
      tmr.alarm( 5 , 500 , 0 , launchUpload )
    else
      tmr.alarm( 4 , config.wifiTimeout , 0 , checkWIFIForUpload)
      print("Checking WIFI..." .. wifiTrys)
      wifiTrys = wifiTrys + 1
    end 
  end 
end


function startWifiAndUploadSpins() 
  print("-- Starting up! ")
  wifiTrys = 0
  ipAddr = wifi.sta.getip()
  if ( ( ipAddr == nil ) or  ( ipAddr == "0.0.0.0" ) ) then
    print("No IP Found Configuring WIFI....")
    wifi.setmode( wifi.STATION )
    findBestWifiAndUpload()
  else
    print("Already have an IP, just uploading")
    launchUpload()
  end
end



function findBestWifiAndUpload() 
  wifi.sta.getap(findCandidateAPForUpload)
end

function findCandidateAPForUpload(t) 
  openaps = {}
  candidateAP = nil
  useStatic = false
  print("Static Wifi setting: "..config.staticWifiName)
  for ssid, v in pairs(t) do
    
    if config.staticWifiName ~= nil and (ssid:lower() == config.staticWifiName:lower()) then
      print("Found SSID that has a static config.  Doing that")
      useStatic = true
    end
    if v:match("^0,") then
      signal = tonumber(v:match("^[^,]+,([^,]+),"))
      print("found an open ap:"..ssid.." signal: "..signal)
      openaps[ssid] = signal
    else
      print("ssid "..ssid.."is not open")
    end
  end
  if useStatic == false then
    openapcount = 0
    for x in pairs(openaps) do openapcount = openapcount + 1 end
    if openapcount > 1 then
      print("selecting from best open signal")
      bestSignal = -500
      for n,v in pairs(openaps) do
        if v > bestSignal then
          bestSignal = v
          candidateAP = n
        end
      end
    else
      if openapcount == 1 then
        print("selecting only available open AP")
        for n,v in pairs(openaps) do
          candidateAP = n
        end
      end
    end

    if candidateAP ~= nil then
      print("Connecting to open WIFI"..candidateAP)
      stationConfig.ssid = candidateAP
      stationConfig.pwd = nil
      wifi.sta.config(stationConfig)
    end
  else
    print("Connecting to static WIFI")
    stationConfig.ssid = config.staticWifiName
    stationConfig.pwd = config.staticWifiPassword
    wifi.sta.config(stationConfig)
  end
  tmr.alarm( 3 , config.wifiTimeout , 0 , checkWIFIForUpload )
end

