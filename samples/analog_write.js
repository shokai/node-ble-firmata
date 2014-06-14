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
    var an = Math.random()*255;
    console.log("analog write 9 pin : " + an);
    arduino.analogWrite(9, an);
  }, 100);
});

arduino.on('disconnect', function(){
  console.log("disconnect!");
});
