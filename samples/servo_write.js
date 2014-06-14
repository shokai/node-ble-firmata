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
    var angle = Math.random()*180;
    console.log("servo write 9 pin : " + angle);
    arduino.servoWrite(9, angle);
  }, 1000);
});

arduino.on('disconnect', function(){
  console.log("disconnect!");
});
