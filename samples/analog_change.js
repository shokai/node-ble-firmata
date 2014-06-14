var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var device_name = process.argv[2] || "BlendMicro";

var arduino = new BLEFirmata().connect(device_name);

arduino.on('connect', function(){
  console.log("connect!!");
  console.log("board version: "+arduino.boardVersion);
});

arduino.on('analogChange', function(e){
  if(e.pin != 0) return;
  console.log("pin" + e.pin + " : " + e.old_value + " -> " + e.value);
});

arduino.on('disconnect', function(){
  console.log("disconnect!");
});
