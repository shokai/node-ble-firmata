var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var arduino = new BLEFirmata().connect();

arduino.on('connect', function(){
  console.log("connect!! "+arduino.serialport_name);
  console.log("board version: "+arduino.boardVersion);

  var stat = true
  setInterval(function(){
    console.log(stat);
    arduino.digitalWrite(13, stat);
    arduino.digitalWrite(12, !stat);
    stat = !stat;  // blink
  }, 300);
});
