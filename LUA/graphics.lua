graphicsMode = 0

function init_i2c_display()
    -- SDA and SCL can be assigned freely to available GPIOs
    local sda = 2
    local scl = 1
    local sla = 0x3c
    i2c.setup(0, sda, scl, i2c.SLOW)
    disp = u8g.ssd1306_128x64_i2c(sla)
end

function prepare()
    disp:setFont(u8g.font_6x10)
    disp:setFontRefHeightExtendedText()
    disp:setDefaultForegroundColor()
    disp:setFontPosTop()
end

function draw()
    prepare()
    if graphicsMode == 0 then
        disp:drawStr(0, 0, "Splunk IoT Spinner")
        disp:drawStr(0,15, "Status: "..spincount)
        disp:drawStr(0,25, "Status: 2")
        disp:drawStr(0,35, "Status: 3")
    elseif graphicsMode == 2 then

    end
    
end


function draw_loop()
    -- Draws one page and schedules the next page, if there is one
    local function draw_pages()
        draw()
        if disp:nextPage() then
            node.task.post(draw_pages)
        else 
            tmr.delay(10000)
            node.task.post(draw_loop,node.task.LOW_PRIORITY)
        end
    end
    -- Restart the draw loop and start drawing pages
    --print("here!!");
    disp:firstPage()
    node.task.post(draw_pages)
end

function start_graphics()
   if i2c ~= nil then
      graphicsMode = 0
      init_i2c_display()
      draw_loop()
   end
end

function updateDisplay()
  
   if i2c ~= nil and disp ~= nil then
      disp:drawStr(0,15, "Status: "..spincount)
   else
      start_graphics()
   end
end

--draw_loop()
