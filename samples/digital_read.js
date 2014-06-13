var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var arduino = new BLEFirmata().connect();

arduino.on('connect', function(){
  console.log("connect!! "+arduino.serialport_name);
  console.log("board version: "+arduino.boardVersion);

  setInterval(function(){
    arduino.pinMode(1, BLEFirmata.INPUT);
    var pin_stat = arduino.digitalRead(1);
    console.log("pin 1 -> "+pin_stat);
  }, 100);
});
