-- mqtt water topics
-- table of [topic] = pin no
mqtt_water_topics = {
  ["home/watering/grove_0"] = 5,
  ["home/watering/grove_1"] = 6,
  ["home/watering/grove_2"] = 7
}

-- Topics to publish on.
-- index 1 = local adc. index 2..5 grove ADC channels
-- use "" to indicate no measurement 
mqtt_moisture_topics = {
  "",
  "home/moisture/0",
  "home/moisture/1",
  "home/moisture/2",
  ""
}

mqtt_name = "sensor1"
timeout = 10e3  -- Always sleep after X milliseconds
sleep_time = 5*60e3
max_water_time = 10e3

-- Generate list of topics to subscribe to
mqtt_subscribes = {}
local n = 0
for k, v in pairs(mqtt_water_topics) do
  n = n + 1
  mqtt_subscribes[n] = k
end

