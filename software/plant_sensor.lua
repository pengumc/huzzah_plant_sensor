dofile("./account.lua") -- provides global ssid, wifi_password, mqtt_user, mqtt_password, mqtt_ip, mqtt_port
dofile("./conf.lua")

-- Feather will wake and take samples of all measurement inputs (can be the ADC or the i2c connected ADC)
-- publish the values on configured mqtt 
--    first topic (when not "") is the local adc
--    subsequent topics are index on ads1115 on i2c address 0x48
-- wait for X seconds for a message on configured topics
--    message is number of milliseconds to switch relay
--    topic name is connected to pin via mqtt_water_topics table in conf.lua

require("dummy")

feather = {
  tmr_timeout= tmr.create(),
  tmr_water = tmr.create(),
  measurements = {},
}

-- Clear and set the led on the feather
function feather.set_led ()
  gpio.mode(3, gpio.OUTPUT)
end

function feather.clear_led ()
  gpio.mode(3, gpio.INPUT)
end

function feather.close_relay(pin)
  print("Close relay on pin ", pin)
  gpio.mode(pin, gpio.OUTPUT)
end

function feather.open_relay(pin)
  print("Open relay on pin ", pin)
  gpio.mode(pin, gpio.INPUT)
end

-- setup grove i2c stuff
function feather.setup_grove ()
  i2c.setup(0, 2, 1, i2c.SLOW)
  ads1115.reset()
  feather.adc = ads1115.ads1115(0, 0x48)
end

-- WIFI stuff
-------------
function feather.sta_got_ip (T)
  -- https://nodemcu.readthedocs.io/en/release/modules/wifi/#wifieventmonregister
  -- table has IP, netmask, gateway
  print("Wifi connected: " .. T.IP)
  feather.set_led()
  feather.setup_mqtt()
end

function feather.connect_wifi ()
  wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, feather.sta_got_ip)
  wifi.setmode(wifi.STATION)
  wifi.sta.config({
    ['ssid']=ssid,
    ['pwd']=wifi_password,
    ['save']=false
  })
  wifi.sta.connect()
end

-- Measurements
---------------
function feather.collect0 ()
  -- store measurements feather.measurements
  if mqtt_moisture_topics[1] then
    feather.measurements[1] = (adc.read(0) + adc.read(0) + adc.read(0) + adc.read(0))/4
  end
  feather.collect(2)
end

local ads1115_ch = {ads1115.SINGLE_0, ads1115.SINGLE_1, ads1115.SINGLE_2}
function feather.collect(i)
  -- Recusively go through mqtt_moisture_topics 2..4
  if mqtt_moisture_topics[i] and string.len(mqtt_moisture_topics[i]) > 0  then
    feather.adc.setting(ads1115.GAIN_4_096V, ads1115.DR_8SPS, ads1115_ch[i], ads1115.SINGLE_SHOT)
    feather.adc.startread(function (v) feather.meas_done(i, v) end)
  else
    feather.meas_done(i, nil)
  end
end

function feather.meas_done(i, v)
  feather.measurements[i] = v
  if i and i < 5 then
    feather.collect(i+1)
  else
    feather.publish()
  end
end

-- MQTT stuff
-------------
function feather.setup_mqtt ()
  feather.mqtt = mqtt.Client(mqtt_name, 20, mqtt_user, mqtt_password)
  feather.mqtt.connect(mqtt_ip, mqtt_port, function (client)
    -- Connected succesfully, start measurements
    feather.collect0()
  end)
  feather.mqtt.on("message", feather.mqtt_message)
  feather.mqtt.subscribe(mqtt_subscribes)
end

function feather.mqtt_message (client, topic, msg)
  -- If we recvieved a value on our subscribed topics
  -- Close the associated relay for <msg> milliseconds
  -- When done, close the mqtt connection and sleep
  print("MQTT recv: ", topic, msg)
  local val = (tonumber(msg) or 0)
  val = val > max_water_time and max_water_time or val -- limit
  local pin = mqtt_water_topics[topic]
  if pin and val > 0 then
    -- We can only water 1 plant at a time, so unsubscribe immediately
    feather.mqtt.unsubscribe(mqtt_subscribes)
    feather.mqtt.close()
    print("pin ", pin, " for ", val)
    feather.close_relay(pin)
    feather.tmr_water.register(val, tmr.ALARM_SIGNAL, function () 
      feather.open_relay(pin)
      node.dsleep(sleep_time) -- We assume mqtt has closed by now
    end)
  end
end

function feather.publish ()
  -- publish feather.measurement value for each topic in mqtt_moisture_topics
  for i, topic in ipairs(mqtt_moisture_topics) do
    if string.len(topic) > 0 then
      feather.mqtt.publish(mqtt_moisture_topics[i], feather.measurements[i], 0, 0)
    end
  end
end

------------------------------------------------------------
-- start
function feather.start ()
  -- Check mqtt_moisture_topics to see if we need to init i2c
  if mqtt_moisture_topics[2] or mqtt_moisture_topics[3] or mqtt_moisture_topics[4] then
    feather.setup_grove()
  end
  -- Setup timers
  feather.tmr_timeout.register(timeout, tmr.ALARM_SIGNAL, function ()
    node.dsleep(sleep_time)
  end)
  feather.tmr_timeout.start()

  -- Connect wifi
  feather.connect_wifi()
end

