var BLEFirmata = require(__dirname+'/../');
// var BLEFirmata = require('ble-firmata');

var arduino = new BLEFirmata().connect();

arduino.on('connect', function(){
  console.log("connect!!");
  console.log("board version: "+arduino.boardVersion);

  setInterval(function(){
    var an = Math.random()*255;
    console.log("analog write 9 pin : " + an);
    arduino.analogWrite(9, an);
  }, 100);
});
