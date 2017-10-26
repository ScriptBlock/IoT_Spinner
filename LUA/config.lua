config = {}

config.defaultConfigUrl="http://s3.amazonaws.com/splunk-spinner/spinner.conf"
config.configUrl=config.defaultConfigUrl
config.externalIPLookupURL="http://myexternalip.com/raw"
config.wifiTimeout = 2500 
config.NUMWIFITRYS = 5
config.collectLan=1
config.collectWan=1
config.collectAp=1
config.normalCheckinInterval = 30000
config.fastCheckinInterval = 20000
config.checkinInterval = 30000
config.hecUrl="http://conf17-science-sandbox-iot.splunkoxygen.com:8088/services/collector/event"
config.splunkHecGuid = "2F50AFBC-6F47-44F0-9A98-BEBD453028F7"
config.gpioCheckInterval = 5 --ms
config.staticWifiName = "Splunk Apps"
config.staticWifiPassword = "splunkapps"
config.configCheckInterval=60000

function urlencode(str)
   if (str) then
      str = string.gsub (str, "\n", "\r\n")
      str = string.gsub (str, "([^%w ])",
         function (c) return string.format ("%%%02X", string.byte(c)) end)
      str = string.gsub (str, " ", "+")
   end
   return str    
end

function getConfig()
    fullUrl=config.configUrl
    http.get(fullUrl, nul, function(code, data)
       if code >= 0 then
          for k,v in string.gmatch(data,"([%w_]+)=([^\r\n]+)") do
             print(k..":"..v)
             config[k]=v
          end
          configCheck:interval(config.configCheckInterval)
       end
    end)
end
