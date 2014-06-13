#define BLE_NAME "BlendMicro"

#include <boards.h>
#include <SPI.h>
#include <Servo.h>
#include <Wire.h>
#include "BLEFirmata.h"
#include <RBL_nRF8001.h>

void setup()
{
  BleFirmata.setFirmwareVersion(FIRMATA_MAJOR_VERSION, FIRMATA_MINOR_VERSION);
  BleFirmata.attach(START_SYSEX, sysexCallback);

  ble_set_name(BLE_NAME);
  ble_begin();
}

void loop()
{
  ble_do_events();

  while(BleFirmata.available()) {
    BleFirmata.processInput();
  }
}

void sysexCallback(byte command, byte argc, byte*argv)
{
  switch(command){
  case 0x01: // LED Blink Command
    if(argc < 3) break;
    byte blink_pin;
    byte blink_count;
    int delayTime;
    blink_pin = argv[0];
    blink_count = argv[1];
    delayTime = argv[2] * 100;

    pinMode(blink_pin, OUTPUT);
    byte i;
    for(i = 0; i < blink_count; i++){
      digitalWrite(blink_pin, true);
      delay(delayTime);
      digitalWrite(blink_pin, false);
      delay(delayTime);
    }
    BleFirmata.sendSysex(command, argc, argv); // callback
    break;
  }
}
