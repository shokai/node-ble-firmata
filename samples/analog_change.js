var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var arduino = new BLEFirmata().connect();

arduino.on('connect', function(){
  console.log("connect!! "+arduino.serialport_name);
  console.log("board version: "+arduino.boardVersion);

  arduino.on('analogChange', function(e){
    if(e.pin != 0) return;
    console.log("pin" + e.pin + " : " + e.old_value + " -> " + e.value);
  });
});
