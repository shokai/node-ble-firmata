var socket = io.connect(location.protocol+"//"+location.hostname)

socket.on('connect', function(){
  console.log('connect!!');

  socket.on('analogRead', function(v){
    $("#analog").text(v);
  });

  socket.on('bleState', function(v){
    $("#ble_state").text(v);
  });
});

$(function(){
  $("#btn_on").click(function(){
    socket.emit("digitalWrite", true);
  });

  $("#btn_off").click(function(){
    socket.emit("digitalWrite", false);
  });

});
