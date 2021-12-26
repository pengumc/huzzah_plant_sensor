ads1115 = {
  reset = function () print("ads1115.reset")  end,
  ads1115 = function () return ads1115 end,
  setting = function (...) print("ads1115.setting") end,
  startread = function (event) print("ads1115.startread") event(math.pi) end
}

gpio = {
  mode = function () print("gpio.mode") end
}

node = {
  dsleep = function (i) print("dsleep ", tostring(i)) end
}

mqtt = {
  Client = function () print("mqtt.Client") return mqtt end,
  connect = function (a, b, c) print("mqtt.connect") c() end,
  publish = function (topic, msg) print("mqtt.publish", topic, msg) end,
  on = function (a, msg) print("mqtt.on") mqtt.msg = msg end,
  subscribe = function () print("mqtt.subscribe") end,
  unsubscribe = function () print("mqtt.unsubscribe") end,
  close = function () print("mqtt.close") end,
}

wifi = {
  eventmon = {
    register = function (a, b) print("wifi.eventmon.register") wifi.event = b end
  },
  setmode = function () print("wifi.setmode") end,
  sta = {
    connect = function () 
      print("wifi.sta.connect")
      wifi.event({IP="some ip"})
    end,
    config = function (a) print("wifi.sta.config") end
  }
}

tmr = {
  create = function () return tmr end,
  register = function (a, b, c) print("tmr.register") tmr.event = c end,
  start = function () print("tmr.start") end
}

adc = {
  read = function () return 5.345e-3 end
}

i2c = {
  setup = function () print("i2c.setup") end
}