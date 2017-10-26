gpioWatchTimer = tmr.create()
uploadTimer = tmr.create()
configCheck = tmr.create()

noSpinCheckin = 0
spincount = 0
spinnerName = wifi.sta.getmac()
lastStatus = 1
numberuploads = 0
failedCheckins = 0 
failedUploadAttempts = 0
concurrentcheckswithspins = 0

externalIP = "x.x.x.x"
internalIP = "x.x.x.x"

neverUploaded=true


inSlowGpioMode = 0
inFastCheckinMode = 0



function startSplunkLook()
   gpio.mode(4, gpio.INPUT)
   gpioWatchTimer:alarm(config.gpioCheckInterval,tmr.ALARM_AUTO, magnetLook)
   uploadTimer:alarm(config.checkinInterval, tmr.ALARM_AUTO,checkIn)
   configCheck:alarm(config.configCheckInterval, tmr.ALARM_AUTO,getConfig)

end


function magnetLook() 
   currentStatus = gpio.read(4)
   if currentStatus == 1 and lastStatus == 0 then
      spincount = spincount + 1
      if spincount == 5 then
        print("H/W Address: "..wifi.sta.getmac())    
      end
      --updateDisplay()
      print(spincount)
      if inSlowGpioMode == 1 then
         print("Leaving slow gpio mode")
         inSlowGpioMode = 0
         config.gpioCheckInterval = 5
         gpioWatchTimer:interval(config.gpioCheckInterval)
      end
   end
   lastStatus = currentStatus
end

function checkIn()
--get external and internal IPs 
   if spincount > 0 or neverUploaded == true then
      --dofile("wifi.lua")
      failedUploadAttempts = failedUploadAttempts + 1
      concurrentcheckswithspins = concurrentcheckswithspins + 1
      startWifiAndUploadSpins()
   else
      concurrentcheckswithspins = 0
      noSpinCheckin = noSpinCheckin + 1
      print("No spins to checkin: "..noSpinCheckin)
   end

   if noSpinCheckin >= 4 then
      if inSlowGpioMode == 1 then
         -- do nothing, already slow
      else
         -- set to slow
         print("Entering slow gpio mode")
         config.gpioCheckInterval = 1000
         inSlowGpioMode = 1
         gpioWatchTimer:interval(config.gpioCheckInterval)
      end
   end

   if concurrentcheckswithspins > 1 then
      if inFastCheckinMode == 1 then
         -- do nothing already fast
      else
         print("Entering fast checkin mode")
         inFastCheckinMode = 1
         config.checkinInterval = config.fastCheckinInterval 
         uploadTimer:interval(config.checkinInterval)
      end
   else
      print("Leaving fast checkin mode")
      inFastCheckinMode = 0
      config.checkinInterval = config.normalCheckinInterval
      uploadTimer:interval(config.checkinInterval)
   end

end


function uploadSpins()

  if adc ~= nil then 
     batteryLevel = adc.read(0)
     
     
     if batteryLevel < 550 or batteryLevel > 775 then
        calcedBatteryLevel = "-1"
     else
        calcedBatteryLevel = (((batteryLevel-580)*(100-0))/(774-580))
     end
  else
     calcedBatteryLevel = -2
  end

  dataString = "{\"host\":\""..wifi.sta.getmac().."\",\"source\":\"splunk-spinner\","
                .."\"event\":{\"spins\":\""..spincount.."\","

  if config.collectWan==1 or config.collectWan=="1" then dataString=dataString.."\"ext_ip\":\""..externalIP.."\"," end
  if config.collectLan==1 or config.collectLan=="1" then dataString=dataString.."\"int_ip\":\""..internalIP.."\"," end
  if config.collectAp==1 or config.collectAp=="1" then dataString=dataString.."\"ap_name\":\""..candidateAP.."\"," end

  dataString = dataString.."\"failed_checkins\":\""..failedCheckins.."\","
                .."\"failed_upload_attempts\":\""..failedUploadAttempts.."\","
                .."\"checkin_interval\":\""..config.checkinInterval.."\","
                .."\"fast_checkin_mode\":\""..inFastCheckinMode.."\","
                .."\"raw_battery_level\":\""..batteryLevel.."\","
                .."\"battery_level\":\""..calcedBatteryLevel.."\","
                .."\"checkins_with_no_spins\":\""..noSpinCheckin.."\"}"
             .."}"
  
  --print("posting: ")
--  print(dataString)
  headers="Authorization: Splunk "..config.splunkHecGuid.."\r\n"
  print("Uploading to: "..config.hecUrl)
  print("Headers: "..headers)
  http.post(config.hecUrl,headers,dataString,function(code,data) 
     if code == 200 then
        numberuploads = numberuploads + 1
        print("Upload Successful")
        --print("reset spin count - uploads: "..numberuploads)
        spincount = 0
        failedCheckins = 0
        noSpinCheckin = 0
        failedUploadAttempts = 0
        neverUploaded = false
     else
        print("Upload failed:"..code)
        failedCheckins = failedCheckins+1
        print("Leaving fast checkin mode")
        inFastCheckinMode = 0
        config.checkinInterval = config.normalCheckinInterval
        uploadTimer:interval(config.checkinInterval)
        
     end
  end)
  
end

