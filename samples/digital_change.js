var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var arduino = new BLEFirmata().connect();

arduino.on('connect', function(){
  console.log("connect!! "+arduino.serialport_name);
  console.log("board version: "+arduino.boardVersion);

  arduino.pinMode(1, BLEFirmata.INPUT);
  arduino.on('digitalChange', function(e){
    console.log("pin" + e.pin + " : " + e.old_value + " -> " + e.value);
  });

});
