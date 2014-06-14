var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var device_name = process.argv[2] || "BlendMicro";

var arduino = new BLEFirmata().connect(device_name);

arduino.on('connect', function(){
  console.log("connect!!");
  console.log("board version: "+arduino.boardVersion);
});

arduino.once('connect', function(){
  setInterval(function(){
    arduino.pinMode(1, BLEFirmata.INPUT);
    var pin_stat = arduino.digitalRead(1);
    console.log("pin 1 -> "+pin_stat);
    arduino.digitalWrite(13, pin_stat);
  }, 100);
});

arduino.on('disconnect', function(){
  console.log("disconnect!");
});
