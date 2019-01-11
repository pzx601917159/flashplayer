/**
* the SunlandsPlayer object.
* @param container the html container id.
* @param width a float value specifies the width of player.
* @param height a float value specifies the height of player.
* @param private_object [optional] an object that used as private object, 
*       for example, the logic chat object which owner this player.
*/
//sunlands播放器
function SunlandsPlayer(container, width, height, private_object) 
{
  if (!SunlandsPlayer.__id) 
  {
      SunlandsPlayer.__id = 100;
  }
  if (!SunlandsPlayer.__players) 
  {
      SunlandsPlayer.__players = [];
  }
  
  SunlandsPlayer.__players.push(this);
  
  this.private_object = private_object;
  this.container = container;
  this.width = width;
  this.height = height;
  this.id = SunlandsPlayer.__id++;
  this.stream_url = null;
  this.buffer_time = 3.0; // default to 0.3
  this.is_live = false;
  //this.buffer_time = 5;
  this.volume = 0.1; // default to 100%
  this.callbackObj = null;
  //this.sunlands_player_url = "sunlands_player/release/sunlands_player.swf?_version=+sunlands_get_version_code()";
  this.sunlands_player_url = "./libs/sunlands_player.swf?_version=" + this.sunlands_get_version_code();
  //this.sunlands_player_url = "http://sddown.8686c.com/sunlands_player.swf";
  
  // callback set the following values.
  this.meatadata = {}; // for on_player_metadata
  this.time = 0; // current stream time.
  this.buffer_length = 0; // current stream buffer length.
  this.kbps = 0; // current stream bitrate(video+audio) in kbps.
  this.fps = 0; // current stream video fps.
  this.rtime = 0; // flash relative time in ms.


  this.__fluency = {
      total_empty_count: 0,
      total_empty_time: 0,
      current_empty_time: 0
  };
  this.__fluency.on_stream_empty = function(time) {
      this.total_empty_count++;
      this.current_empty_time = time;
  };
  this.__fluency.on_stream_full = function(time) {
      if (this.current_empty_time > 0) {
          this.total_empty_time += time - this.current_empty_time;
          this.current_empty_time = 0;
      }
  };
  this.__fluency.calc = function(time) {
      var den = this.total_empty_count * 4 + this.total_empty_time * 2 + time;
      if (den > 0) {
          return time * 100 / den;
      }
      return 0;
  };
}
/**
* user can set some callback, then start the player.
* @param url the default url.
* callbacks:
*      on_player_ready():int, when sunlands player ready, user can play.
*      on_player_metadata(metadata:Object):int, when sunlands player get metadata.
*/
SunlandsPlayer.prototype.sunlands_get_version_code = function(){
  return "1.0.0";
}


SunlandsPlayer.prototype.start = function(url) {
  if (url) {
      this.stream_url = url;
  }
  
  // embed the flash.
  var flashvars = {};
  flashvars.id = this.id;
  flashvars.is_live = 0;
  flashvars.on_player_ready = "__sunlands_on_player_ready";
  flashvars.on_player_metadata = "__sunlands_on_player_metadata";
  flashvars.on_player_timer = "__sunlands_on_player_timer";
  flashvars.on_player_empty = "__sunlands_on_player_empty";
  flashvars.on_player_full = "__sunlands_on_player_full";
  flashvars.on_player_stop = "__sunlands_on_player_stop";
  flashvars.on_update_loaded_video = "__sunlands_on_update_loaded_video";
  flashvars.on_update_media_time = "__sunlands_on_update_media_time";
  flashvars.on_player_status = "__sunlands_on_player_status";
  flashvars.debug = 1;
  
  var params = {};
  params.wmode = "opaque";
  params.allowFullScreen = "true";
  params.allowScriptAccess = "always";
  
  var attributes = {};
  
  var self = this;
  console.log("jjjjjjjjjjjjjjjj is_live",flashvars.is_live);
  
  swfobject.embedSWF(
      this.sunlands_player_url, 
      this.container,
      this.width, this.height,
      "10.2.0", "js/AdobeFlashPlayerInstall.swf",
      flashvars, params, attributes,
      function(callbackObj){
          self.callbackObj = callbackObj;
      }
  );
  
  console.log("flash init complete");
  return this;
}
/**
* play the stream.
* @param stream_url the url of stream, rtmp or http.
* @param volume the volume, 0 is mute, 1 is 100%, 2 is 200%.
*/
SunlandsPlayer.prototype.play = function(url, volume) {
  this.stop();
  SunlandsPlayer.__players.push(this);
  
  if (url) {
      this.stream_url = url;
  }
  
  // volume maybe 0, so never use if(volume) to check its value.
  if (volume != null && volume != undefined) {
      this.volume = volume;
  }
  console.log("iiiiiiiiiiiiiiiiiiiiiiiiiiiiiii:",this.is_live);
  
  //this.callbackObj.ref.__play(this.stream_url, this.is_live, this.width, this.height, this.buffer_time, this.volume);
  this.callbackObj.ref.__play({"url":this.stream_url,"is_live":this.is_live,"width":this.width,"height":this.height,"buffer_time":this.buffer_time,"volume":this.volume})
}

SunlandsPlayer.prototype.setVolume = function(volume){
  this.callbackObj.ref.__set_volume(volume);
}

SunlandsPlayer.prototype.seekVideo = function(seekPoint){
  this.callbackObj.ref.__seek_video(seekPoint);
}

SunlandsPlayer.prototype.stop = function() {
  for (var i = 0; i < SunlandsPlayer.__players.length; i++) {
      var player = SunlandsPlayer.__players[i];
      
      if (player.id != this.id) {
          continue;
      }
      
      SunlandsPlayer.__players.splice(i, 1);
      break;
  }
  
  this.callbackObj.ref.__stop();
}
SunlandsPlayer.prototype.pause = function() {
  this.callbackObj.ref.__pause();
}
SunlandsPlayer.prototype.resume = function() {
  this.callbackObj.ref.__resume();
}
/**
* get the stream fluency, where 100 is 100%.
*/
SunlandsPlayer.prototype.fluency = function() {
  return this.__fluency.calc(this.rtime);
}
/**
* get the stream empty count.
*/
SunlandsPlayer.prototype.empty_count = function() {
  return this.__fluency.total_empty_count;
}
/**
* to set the DAR, for example, DAR=16:9 where num=16,den=9.
* @param num, for example, 16. 
*       use metadata width if 0.
*       use user specified width if -1.
* @param den, for example, 9. 
*       use metadata height if 0.
*       use user specified height if -1.
*/
SunlandsPlayer.prototype.set_dar = function(num, den) {
  this.callbackObj.ref.__set_dar(num, den);
}
/**
* set the fullscreen size data.
* @refer the refer fullscreen mode. it can be:
*       video: use video orignal size.
*       screen: use screen size to rescale video.
* @param percent, the rescale percent, where
*       100 means 100%.
*/
SunlandsPlayer.prototype.set_fs = function(refer, percent) {
  this.callbackObj.ref.__set_fs(refer, percent);
}
/**
* set the stream buffer time in seconds.
* @buffer_time the buffer time in seconds.
*/
SunlandsPlayer.prototype.set_bt = function(buffer_time) {
  this.buffer_time = buffer_time;
  this.callbackObj.ref.__set_bt(buffer_time);
}
/**
* set the sunlands_player.swf url
* @param url, sunlands_player.swf's url.
* @param params, object.
*/
SunlandsPlayer.prototype.set_sunlands_player_url = function(url, params) {
  var query_array = [], 
      query_string = "", 
      p;
  params = params || {}; 
  params._version = sunlands_get_version_code();
  for (p in params) {
      if (params.hasOwnProperty(p)) {
          query_array.push(p + "=" + encodeURIComponent(params[p]));
      }
  }   
  query_string = query_array.join("&");
  this.sunlands_player_url = url + "?" + query_string;
}
SunlandsPlayer.prototype.on_player_ready = function() {
  console.log("on_player_ready");
}
SunlandsPlayer.prototype.on_player_metadata = function(metadata) {
  // ignore.
}
SunlandsPlayer.prototype.on_player_timer = function(time, buffer_length, kbps, fps, rtime, livedelay, bufferTimeMax) {
  console.log("buffer_length:" + buffer_length + " bitrate:" + kbps+" fps:" + fps + " rtime:" + rtime + " livedelay:" + livedelay + "buffertimeMax:" + buffTimeMax);
}
SunlandsPlayer.prototype.on_player_empty = function(time) {
  // ignore.
  console.log("on_player_empty");
}
SunlandsPlayer.prototype.on_player_full = function(time) {
  // ignore.
  console.log("-------------------on_player_full");
}
SunlandsPlayer.prototype.on_player_stop = function(time) {
  // ignore.
  console.log("on_player_stop");
}

SunlandsPlayer.prototype.on_update_loaded_video = function(rate) {
  // ignore.
  console.log("on_update_loaded_video:===============:",rate);
}

SunlandsPlayer.prototype.on_update_media_time = function(time) {
  // ignore.
  console.log("on_update_media_time:===============:",time);
}

SunlandsPlayer.prototype.on_player_status = function(status) {
  // ignore.
  console.log("on_player_status:===============:");
}

function __sunlands_find_player(id) {
  for (var i = 0; i < SunlandsPlayer.__players.length; i++) 
  {
      var player = SunlandsPlayer.__players[i];
      
      if (player.id != id) {
          continue;
      }
      
      return player;
  }
  
  throw new Error("player not found. id=" + id);
}
function __sunlands_on_player_ready(id) {
  console.log("__sunlands_on_player_ready");
  var player = __sunlands_find_player(id);
  player.on_player_ready();
}
function __sunlands_on_player_metadata(id, metadata) 
{
  //console.log(metadata);
  var player = __sunlands_find_player(id);
  
  // user may override the on_player_metadata, 
  // so set the data before invoke it.
  player.metadata = metadata;
  
  player.on_player_metadata(metadata);
}
function __unlands_on_player_timer(id, time, buffer_length, kbps, fps, rtime, livedelay, bufferTimeMax) 
{
  var player = __sunlands_find_player(id);
  
  buffer_length = Math.max(0, buffer_length);
  buffer_length = Math.min(player.buffer_time, buffer_length);
  
  time = Math.max(0, time);
  
  // user may override the on_player_timer, 
  // so set the data before invoke it.
  player.time = time;
  player.buffer_length = buffer_length;
  player.kbps = kbps;
  player.fps = fps;
  player.rtime = rtime;
  player.livedelay = livedelay

  player.on_player_timer(time, buffer_length, kbps, fps, rtime, livedelay, bufferTimeMax);
}
function __sunlands_on_player_empty(id, time) 
{
  var player = __sunlands_find_player(id);
  player.__fluency.on_stream_empty(time);
  player.on_player_empty(time);
}
function __sunlands_on_player_full(id, time) 
{
  var player = __sunlands_find_player(id);
  player.__fluency.on_stream_full(time);
  player.on_player_full(time);
}

function __sunlands_on_player_stop(id)
{
  //console.log("on player stop");
  var player = __sunlands_find_player(id);
  player.on_player_stop();
}

function __sunlands_on_update_loaded_video(id,rate)
{
  //console.log("=====on update loaded video:",rate);
  var player = __sunlands_find_player(id);
  player.on_update_loaded_video(rate);
}

function __sunlands_on_update_media_time(id,time)
{
  //console.log("=====on update loaded video:",rate);
  var player = __sunlands_find_player(id);
  player.on_update_media_time(time);
}

function __sunlands_on_player_status(id,status)
{
  console.log("__sunlands_on_player_status:" + id + "---" +status);
  //console.log("=====on update loaded video:",rate);
  var player = __sunlands_find_player(id);
  if(player == null)
  {
    console.log("player is null");
  }
  else{
    console.log("find player");
  }
  player.on_player_status(stats);
}