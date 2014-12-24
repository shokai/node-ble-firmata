events = require 'eventemitter2'
BlendMicro = require 'blendmicro'

debug = require('debug')('ble-firmata')

exports = module.exports = class BLEFirmata extends events.EventEmitter2

  @INPUT  = 0
  @OUTPUT = 1
  @ANALOG = 2
  @PWM    = 3
  @SERVO  = 4
  @SHIFT  = 5
  @I2C    = 6
  @LOW    = 0
  @HIGH   = 1

  @MAX_DATA_BYTES  = 32
  @DIGITAL_MESSAGE = 0x90 # send data for a digital port
  @ANALOG_MESSAGE  = 0xE0 # send data for an analog pin (or PWM)
  @REPORT_ANALOG   = 0xC0 # enable analog input by pin
  @REPORT_DIGITAL  = 0xD0 # enable digital input by port
  @SET_PIN_MODE    = 0xF4 # set a pin to INPUT/OUTPUT/PWM/etc
  @REPORT_VERSION  = 0xF9 # report firmware version
  @SYSTEM_RESET    = 0xFF # reset from MIDI
  @START_SYSEX     = 0xF0 # start a MIDI SysEx message
  @END_SYSEX       = 0xF7 # end a MIDI SysEx message

  @I2C_REQUEST = 0x76
  @I2C_REPLY = 0x77
  @I2C_CONFIG = 0x78

  @I2C_MODES = {
    WRITE: 0x00,
    READ: 1,
    CONTINUOUS_READ: 2,
    STOP_READING: 3
  }

  constructor: ->
    @reconnect = true
    @state = 'close'
    @wait_for_data = 0
    @execute_multi_byte_command = 0
    @multi_byte_channel = 0
    @stored_input_data = []
    @parsing_sysex = false
    @sysex_bytes_read = 0
    @digital_output_data = [0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0]
    @digital_input_data  = [0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0]
    @analog_input_data   = [0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0]
    @boardVersion = null

  connect: (@peripheral_name = "BlendMicro") ->

    @once 'boardReady', ->
      debug "boardReady \"#{@peripheral_name}\""
      io_init_wait = 100
      debug "wait #{io_init_wait}(msec)"
      setTimeout =>
        for i in [0...6]
          @write [(BLEFirmata.REPORT_ANALOG | i), 1]
        for i in [0...2]
          @write [(BLEFirmata.REPORT_DIGITAL | i), 1]
        debug 'init IO ports'
        @emit 'connect'
      , io_init_wait

    unless @ble
      @ble = new BlendMicro(@peripheral_name)
    else
      @ble.open()

    @ble.once 'open', =>
      debug 'BLE open'
      cid = setInterval =>
        debug 'request REPORT_VERSION'
        @force_write [BLEFirmata.REPORT_VERSION]
      , 1000
      @once 'boardVersion', (version) =>
        clearInterval cid
        @state = 'open'
        @emit 'boardReady'
      @ble.on 'data', (data) =>
        for byte in data
          @process_input byte
      @ble.once 'close', =>
        @state = 'close'
        clearInterval cid
        debug 'BLE close'
        @emit 'disconnect'
        if @reconnect
          setTimeout =>
            debug "try re-connect #{@peripheral_name}"
            @connect @peripheral_name
          , 1000

    return @

  isOpen: ->
    return @state is 'open'

  close: (callback) ->
    @state = 'close'
    @ble.close callback

  reset: (callback) ->
    @write [BLEFirmata.SYSTEM_RESET], callback

  write: (bytes, callback) ->
    unless @state is 'open'
      return
    @force_write bytes, callback

  force_write: (bytes, callback) ->
    try
      unless @ble.state is 'connected'
        return
      @ble.write bytes, callback
    catch err
      @ble.close

  sysex: (command, data=[], callback) ->
    ## http://firmata.org/wiki/V2.1ProtocolDetails#Sysex_Message_Format
    data = data.map (i) -> i & 0b1111111  # 7bit
    write_data = [BLEFirmata.START_SYSEX, command].concat data, [BLEFirmata.END_SYSEX]
    @write write_data, callback

  sendI2CConfig: (delay=0, callback) ->
    data = [delay, delay >>> 8]
    data = data.map (i) -> i & 0b11111111 # 7bit
    write_data = [BLEFirmata.START_SYSEX, BLEFirmata.I2C_CONFIG].concat data, [BLEFirmata.END_SYSEX]
    @write write_data, callback

  sendI2CWriteRequest: (slaveAddress, bytes, callback) ->
    data = [slaveAddress, BLEFirmata.I2C_MODES.WRITE << 3]
    bytes.map (i) ->
      data.push i, i >>> 7
    @sysex BLEFirmata.I2C_REQUEST, data, callback

  pinMode: (pin, mode, callback) ->
    switch mode
      when true
        mode = BLEFirmata.OUTPUT
      when false
        mode = BLEFirmata.INPUT
    @write [BLEFirmata.SET_PIN_MODE, pin, mode], callback

  digitalWrite: (pin, value, callback) ->
    @pinMode pin, BLEFirmata.OUTPUT
    port_num = (pin >>> 3) & 0x0F
    if value is 0 or value is false
      @digital_output_data[port_num] &= ~(1 << (pin & 0x07))
    else
      @digital_output_data[port_num] |= (1 << (pin & 0x07))
    @write [ (BLEFirmata.DIGITAL_MESSAGE | port_num),
             (@digital_output_data[port_num] & 0x7F),
             (@digital_output_data[port_num] >>> 7) ],
           callback

  analogWrite: (pin, value, callback) ->
    value = Math.floor value
    @pinMode pin, BLEFirmata.PWM
    @write [ (BLEFirmata.ANALOG_MESSAGE | (pin & 0x0F)),
             (value & 0x7F),
             (value >>> 7) ],
           callback

  servoWrite: (pin, angle, callback) ->
    @pinMode pin, BLEFirmata.SERVO
    @write [ (BLEFirmata.ANALOG_MESSAGE | (pin & 0x0F)),
             (angle & 0x7F),
             (angle >>> 7) ],
           callback

  digitalRead: (pin) ->
    return ((@digital_input_data[pin >>> 3] >>> (pin & 0x07)) & 0x01) > 0

  analogRead: (pin) ->
    return @analog_input_data[pin]

  process_input: (input_data) ->
    if @parsing_sysex
      if input_data is BLEFirmata.END_SYSEX
        @parsing_sysex = false
        sysex_command = @stored_input_data[0]
        sysex_data = @stored_input_data[1...@sysex_bytes_read]
        @emit 'sysex', {command: sysex_command, data: sysex_data}
      else
        @stored_input_data[@sysex_bytes_read] = input_data
        @sysex_bytes_read += 1
    else if @wait_for_data > 0 and input_data < 128
      @wait_for_data -= 1
      @stored_input_data[@wait_for_data] = input_data
      if @execute_multi_byte_command isnt 0 and @wait_for_data is 0
        switch @execute_multi_byte_command
          when BLEFirmata.DIGITAL_MESSAGE
            input_data = (@stored_input_data[0] << 7) + @stored_input_data[1]
            diff = @digital_input_data[@multi_byte_channel] ^ input_data
            @digital_input_data[@multi_byte_channel] = input_data
            if @listeners('digitalChange').length > 0
              for i in [0..13]
                if ((0x01 << i) & diff) > 0
                  stat = (input_data&diff) > 0
                  @emit 'digitalChange',
                  {pin: i+@multi_byte_channel*8, value: stat, old_value: !stat}
          when BLEFirmata.ANALOG_MESSAGE
            analog_value = (@stored_input_data[0] << 7) + @stored_input_data[1]
            old_analog_value = @analogRead(@multi_byte_channel)
            @analog_input_data[@multi_byte_channel] = analog_value
            if old_analog_value != analog_value
              @emit 'analogChange', {
                pin: @multi_byte_channel,
                value: analog_value,
                old_value: old_analog_value
              }
          when BLEFirmata.REPORT_VERSION
            @boardVersion = "#{@stored_input_data[1]}.#{@stored_input_data[0]}"
            @emit 'boardVersion', @boardVersion
    else
      if input_data < 0xF0
        command = input_data & 0xF0
        @multi_byte_channel = input_data & 0x0F
      else
        command = input_data
      if command is BLEFirmata.START_SYSEX
        @parsing_sysex = true
        @sysex_bytes_read = 0
      else if command is BLEFirmata.DIGITAL_MESSAGE or
              command is BLEFirmata.ANALOG_MESSAGE or
              command is BLEFirmata.REPORT_VERSION
        @wait_for_data = 2
        @execute_multi_byte_command = command
