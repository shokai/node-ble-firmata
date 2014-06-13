var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var arduino = new BLEFirmata().connect();

arduino.on('connect', function(){
  console.log("connect!! "+arduino.serialport_name);
  console.log("board version: "+arduino.boardVersion);

  setInterval(function(){
    var angle = Math.random()*180;
    console.log("servo write 9 pin : " + angle);
    arduino.servoWrite(9, angle);
  }, 1000);
});
