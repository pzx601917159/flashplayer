package
{
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageDisplayState;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.FullScreenEvent;
    import flash.events.MouseEvent;
    import flash.events.NetStatusEvent;
    import flash.events.TimerEvent;
    import flash.external.ExternalInterface;
    import flash.media.SoundTransform;
    import flash.media.Video;
    import flash.net.NetConnection;
    import flash.net.NetStream;
    import flash.net.NetStreamInfo;
    import flash.net.NetStreamPlayOptions;
    import flash.system.Security;
    import flash.ui.ContextMenu;
    import flash.ui.ContextMenuBuiltInItems;
    import flash.ui.ContextMenuClipboardItems;
    import flash.ui.ContextMenuItem;
    import flash.events.ContextMenuEvent;
    import flash.utils.Timer;
    import flash.utils.getTimer;
    import flash.utils.setTimeout;
    import flash.ui.Keyboard;
    import flash.events.KeyboardEvent;
    import flash.display.DisplayObject;
    import flashx.textLayout.formats.Float;
	import flash.net.NetStreamInfo;
    import player.Config;
	import player.Callback;
	import player.BasePlayer;
	import player.LivePlayer;
	import player.VideoPlayer;
	import flvparser.flvparser;
    
    public class SunlandsPlayer extends Sprite
    {
        private var _config:player.Config;
		private var _callback:player.Callback;
		private var _player:player.BasePlayer;
        
        private var _url:String = null;
        private var _width:int = 0;
        private var _height:int = 0;
        private var _user_dar_den:int = 0;
        private var _user_dar_num:int = 0;
        private var _user_fs_refer:String = null;
        private var _user_fs_percent:int = 0;
        
        private var _media_conn:NetConnection = null;
        private var _media_stream:NetStream = null;
        private var _media_video:Video = null;
        private var _media_metadata:Object = {};
        private var _metadata_count:int = 0;
        private var _media_timer:Timer = new Timer(1000);
        private var _reconnect_timer:Timer = null;
        private var _duration:Number = 0;
        private var _current_time:Number = 0;
        
        private const STARTING:String = "STARTING";
        private const STARTED:String = "STARTED";
        private const STOPPING:String = "STOPPING";
        private const STOPPED:String = "STOPPED";
        private const PAUSED:String = "PAUSED";
        private var _status:String = STOPPED;
		private var _is_live:Boolean = true;
		private var _start_sequence:Number = 0;
		private var _sequnce:Number = 0;
		private var _loaded_percent:Number = 0;
			
		var _menuItemVersion:ContextMenuItem = null;
		var _menuItemFullScreenModel:ContextMenuItem = null;
		
        private var control_fs_mask:Sprite = new Sprite();
        
        
        public function SunlandsPlayer()
        {
            if (!this.stage) 
            {
                this.addEventListener(Event.ADDED_TO_STAGE, this.system_on_add_to_stage);
            } 
            else 
            {
                this.system_on_add_to_stage(null);
            }
        }
        
        private function system_on_add_to_stage(evt:Event):void 
        {
			_config = new player.Config();
			_callback = new player.Callback();
            this.removeEventListener(Event.ADDED_TO_STAGE, this.system_on_add_to_stage);
            this.stage.scaleMode = StageScaleMode.EXACT_FIT;
            Security.allowDomain("*");
            
            this.addChild(this.control_fs_mask);
            this.control_fs_mask.buttonMode = true;
            this.control_fs_mask.addEventListener(MouseEvent.CLICK, user_on_click_video);
            
            this.contextMenu = new ContextMenu();
            this.contextMenu.hideBuiltInItems();
            update_context_items();
            
            var flashvars:Object = this.root.loaderInfo.parameters;            
            this._config._js_id = flashvars.id;
			this._callback.init(flashvars);
			
            flash.utils.setTimeout(this.system_on_js_ready, 0);
			js_call_play2({"url":"http://10.247.62.68/test2.flv", "is_live":1, "width":400, "height":300, "buffer_time":3, "volume":1.0});
            
        }
        
        //设置js可以调用的函数
        private function system_on_js_ready():void 
        {
            if (!flash.external.ExternalInterface.available) 
            {
                log("js not ready, try later.");
                flash.utils.setTimeout(this.system_on_js_ready, 100);
                return;
            }
            
            if (ExternalInterface.available)
            {
                flash.external.ExternalInterface.addCallback("__play", this.js_call_play);
                flash.external.ExternalInterface.addCallback("__stop", this.js_call_stop);
                flash.external.ExternalInterface.addCallback("__pause", this.js_call_pause);
                flash.external.ExternalInterface.addCallback("__resume", this.js_call_resume);
                flash.external.ExternalInterface.addCallback("__set_dar", this.js_call_set_dar);
                flash.external.ExternalInterface.addCallback("__set_fs", this.js_call_set_fs_size);
                flash.external.ExternalInterface.addCallback("__set_bt", this.js_call_set_bt);
                flash.external.ExternalInterface.addCallback("__set_volume", this.js_call_set_volume);
                flash.external.ExternalInterface.addCallback("__seek_video", this.js_call_seek_video);
                
                flash.external.ExternalInterface.call(_callback._js_on_player_ready, _config._js_id);
            }
        }
        
        
        private function system_on_timer(evt:TimerEvent):void 
        {
			if (ExternalInterface.available)
            {
                flash.external.ExternalInterface.call(_callback._js_on_update_media_time, _config._js_id, _media_stream.time);
            }
        }
        
        
        private function system_on_buffer_empty():void 
        {
            var time:Number = flash.utils.getTimer();
            log("stream is empty at " + time + "ms");
            if (ExternalInterface.available)
            {
                flash.external.ExternalInterface.call(_callback._js_on_player_empty, _config._js_id, time);
            }
        }
        
        
        private function system_on_buffer_full():void 
        {
            var time:Number = flash.utils.getTimer();
            log("stream is full at " + time + "ms");
            if (ExternalInterface.available)
            {
                flash.external.ExternalInterface.call(_callback._js_on_player_full, _config._js_id, time);
            }
        }
        
        
        private function system_on_player_stop():void 
        {
            if (ExternalInterface.available)
            {
                flash.external.ExternalInterface.call(_callback._js_on_player_stop, _config._js_id);
            }
        }
        
        //收到metadata的回调
        private function system_on_metadata(metadata:Object):void 
        {
            _metadata_count += 1;
            if (!this._media_metadata[width])
            {
                this._media_metadata = metadata;          
            }
            
            var time:Number = 0;
            // for js.
            var obj:Object = __get_video_size_object();
            var key:String;
            for (key in metadata)
            {
                obj[key] = metadata[key];
                if (key == "user_data")
                {
                    time = Number(metadata[key]);
                    obj[key] = time;
                }
                if (key == "duration")
                {
                    _duration = Number(metadata[key]);
                }
            }
            obj["user_time"] = _media_stream.time;
            if (_duration > 0 )
            {
                obj["totoal_time"] = _duration;
            }
            if (ExternalInterface.available)
            {
                var code:int = flash.external.ExternalInterface.call(_callback._js_on_player_metadata, _config._js_id, obj);
                if (code != 0) 
                {
                    throw new Error("callback on_player_metadata failed. code=" + code);
                }
            }
        }
        

        //收到metadata的回调
        private function system_on_imagedata(imagedata:Object):void 
        {
            var key:String;
            for (key in imagedata)
            {
                trace(imagedata[key]);
            }
        }
        
        private function user_on_stage_fullscreen(evt:FullScreenEvent):void 
        {
            trace("user_on_stage_fullscreen:",evt.fullScreen);
            if (!evt.fullScreen) 
            {
                __execute_user_set_dar();
            } 
            else 
            {
                __execute_user_enter_fullscreen();
            }
        }
        
        
        private function user_on_click_video(evt:MouseEvent):void 
        {   
            // enter fullscreen to get the fullscreen size correctly.
            if (this.stage.displayState == StageDisplayState.FULL_SCREEN) 
            {
                this.stage.displayState = StageDisplayState.NORMAL;
                this._media_video.width = this.stage.stageWidth;
                this._media_video.height = this.stage.stageHeight;
                
            } 
            else 
            {
                this.stage.displayState = StageDisplayState.FULL_SCREEN;
                this._media_video.width = this.stage.stageWidth;
                this._media_video.height = this.stage.stageHeight;
            }
        }
        
        
        private function js_call_pause():void 
        {
            log("================js call pause\n");
            if (this._media_stream) 
            {
				if (ExternalInterface.available)
				{
					flash.external.ExternalInterface.call(_callback._js_on_update_media_time, _config._js_id, _media_stream.time);
				}
                this._media_stream.pause();
				_media_timer.stop();
                _status = PAUSED;
            }
        }
        
        
        private function js_call_resume():void 
        {
            if (this._media_stream) 
            {
                this._media_stream.resume();
				_media_timer.start();
                _status = STARTED;
            }
        }
        
        
        //设置视频比例
        private function js_call_set_dar(num:int, den:int):void 
        {
            _user_dar_num = num;
            _user_dar_den = den;
            
            flash.utils.setTimeout(__execute_user_set_dar, 0);
        }
        
        
        //设置画面占比
        private function js_call_set_fs_size(refer:String, percent:int):void 
        {
            _user_fs_refer = refer;
            _user_fs_percent = percent;
        }
        
        
        private function js_call_set_bt(buffer_time:Number):void 
        {
            if (this._media_stream) {
                this._media_stream.bufferTime = buffer_time;
            }
        }

        
        private function js_call_set_volume(volume:Number):void
        {
            if (volume < 0 || volume > 1.0)
            {
                return;
            }
            update_volume(volume);
        }
        

        private function update_volume(volume:Number):void
        {
            this._media_stream.soundTransform = new SoundTransform(volume);
        }
        
        
        private function js_call_seek_video(seekPoint:Number):void
        {
            if (seekPoint < 0 || seekPoint > _duration)
            {
                return;
            }
            seek_video(seekPoint);
        }
        
        
        private function seek_video(seekPoint:Number):void
        {
            _media_stream.seek(seekPoint);
        }
        
        
        private function js_call_stop():void 
        {
            return;
            if (this._media_video) 
            {
                this.removeChild(this.media_video);
                this._media_video = null;
            }
            if (this._media_stream) 
            {
                this._media_stream.close();
                this._media_stream = null;
            }
            if (this._media_conn) 
            {
                this._media_conn.close();
                this._media_conn = null;
            }
            log("player stopped");
        }
        
        
        private function update_context_items():void 
        {
            _menuItemVersion = new ContextMenuItem(this._config._version, false, false);
            _menuItemFullScreenModel = new ContextMenuItem("切换全屏模式", false, true);
            var customItems:Array = new Array();
            customItems.push(_menuItemVersion);
            customItems.push(_menuItemFullScreenModel);
            contextMenu.customItems = customItems;
            _menuItemFullScreenModel.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, on_context_click);
            
        }
        
        
        private function on_context_click(e:ContextMenuEvent):void
        {
            if (this.stage.displayState == StageDisplayState.FULL_SCREEN) 
            {
                if (stage.scaleMode == StageScaleMode.SHOW_ALL)
                {
                    stage.scaleMode = StageScaleMode.EXACT_FIT;
                }
                else
                {
                    stage.scaleMode = StageScaleMode.SHOW_ALL;
                }
            }
            
        }
        
        
        private function clear():void
        {
            //return;
            this._url = null;
            this._width = 0;
            this._height = 0;
            this._user_dar_den = 0;
            this._user_dar_num = 0;
            this._user_fs_refer = null;
            this._user_fs_percent = 0;
            if (this._media_conn)
            {
                this._media_conn.close();
                this._media_conn = null;
            }
            if (this._media_stream)
            {
                this._media_stream.close();
                this._media_stream = null;
            }
            if (this._media_video)
            {
                this._media_video.clear();
                this._media_video = null;
            }
            
            this._media_metadata = {};
            this._media_timer.stop();
            if (this._reconnect_timer)
            {
                this._reconnect_timer.stop();
            }
            this._duration = 0;
            this._current_time = 0;
            this._status = STOPPED;
            this._is_live = true;
        }
        
		//重构后的播放
        private function js_call_play2(obj:Object)
		{
			//判断是直播还是点播
			if (obj.is_live)
			{
				//直播
				_player = new player.LivePlayer();
				_player.init(obj);
				_player.play();
			}
			else 
			{
				//点播
				_player = new player.VideoPlayer();
				_player.init(obj);
			}
		}
		
        //private function js_call_play(url:String, is_live:Boolean, width:int, height:int, buffer_time:Number, volume:Number, sequence:Number=0):void
		private function js_call_play(obj:Object)
        {
			_start_sequence = obj.sequence;
			this.clear();
			this._reconnect_timer = new Timer(3000);
			this._media_timer.addEventListener(TimerEvent.TIMER, this.system_on_timer);
            this._reconnect_timer.addEventListener(TimerEvent.TIMER, this.reconnect);
            this._media_timer.start();
            this._reconnect_timer.start();
            
            this._is_live = obj.is_live;
            if (!this._is_live)
            {
                stage.addEventListener(Event.ENTER_FRAME, on_enter_frame);
            }
            
            this._url = obj.url;
			trace("---url", this._url);
            this._width = obj.width;
            this._height = obj.height;
            log("start to play url: " + this._url + ", w=" + this._width + ", h=" + this._height);
            
            js_call_stop();
            
            this._media_conn = new NetConnection();
            this._media_conn.client = {};
            this._media_conn.client.onBWDone = function():void {};
            this._media_conn.addEventListener(NetStatusEvent.NET_STATUS, function(evt:NetStatusEvent):void 
            {
                if (evt.info.code != "NetStream.Buffer.Full" && evt.info.code != "NetStream.Buffer.Empty")
                {
                    trace("NetConnection: code=" + evt.info.code);
                }
                log("NetConnection: code=" + evt.info.code);
                
                if (evt.info.code == "NetConnection.Connect.Closed")
                {
                    _status = STOPPED;
                }
                
                // TODO: FIXME: failed event.
                if (evt.info.code != "NetConnection.Connect.Success") 
                {
                    return;
                }
                
                _media_stream = new NetStream(_media_conn);
				_media_stream.useHardwareDecoder = true;
                _media_stream.soundTransform = new SoundTransform(obj.volume);
                _media_stream.bufferTime = obj.buffer_time;
                _media_stream.client = {};
                _media_stream.bufferTimeMax = 0;
                _media_stream.client.onMetaData = system_on_metadata;
                _media_stream.client.onImageData = system_on_imagedata;
                _media_stream.addEventListener(NetStatusEvent.NET_STATUS, function(evt:NetStatusEvent):void 
                {
                    if (evt.info.code != "NetStream.Buffer.Full" && evt.info.code != "NetStream.Buffer.Empty")
                    {
                        trace("NetConnection: code=" + evt.info.code);
                    }
                    log("===============================NetStream: code=" + evt.info.code);
                    
                    if (evt.info.code == "NetStream.Video.DimensionChange") 
                    {
                        system_on_metadata(_media_metadata);
                    } 
                    else if (evt.info.code == "NetStream.Buffer.Empty") 
                    {
                        system_on_buffer_empty();
                    } 
                    else if (evt.info.code == "NetStream.Buffer.Full") 
                    {
                        system_on_buffer_full();
                    }
                    else if (evt.info.code == "NetStream.Play.Start")
                    {
                        _status = STARTED;
                        //log("width:" + _width + "height:" + _height);
                        if (_media_video)
                        {
                            _media_video.clear();
                            _media_video = null;
                        }
                        _media_video = new Video(stage.stageWidth, stage.stageHeight);
                        //trace("_width:", _width, "height:", _height);
                        _media_video.attachNetStream(_media_stream);
                        _media_video.smoothing = true;
                        addChild(_media_video);
                    }
                    else if (evt.info.code == "NetStream.Play.Stop")
                    {
                        _status = STOPPED;
                        system_on_player_stop();
                    }
                    else if (evt.info.code == "NetStream.Seek.InvalidTime")
                    {
                        log(evt.info.details);
                    }
                    else if (evt.info.code == "NetStream.Seek.Notify")
                    {
                        
                    }
                    else if (evt.info.code == "NetStream.Buffer.Full")
                    {
                        
                    }
                    
                    // TODO: FIXME: failed event.
                });
                
                if (_url.indexOf("http") == 0) 
                {
                    //media_conn.connect
                    if (_is_live)
                    {
                        _media_stream.close();
                        _media_stream.play(_url, -1);
                    }
                    else
                    {
                        _media_stream.play(_url);
                    }
                } 
                else 
                {
                    var streamName:String = _url.substr(_url.lastIndexOf("/") + 1);
                    if (this._is_live)
                    {
                        _media_stream.play(streamName, -1);
                    }
                    else
                    {
                        _media_stream.play(streamName);
                    }
                }
           
                log("width:" + this._width + "height:" + this._height);
                _media_video = new Video(stage.stageWidth, stage.stageHeight);
                //trace("_width:", _width, "height:", _height);
                _media_video.attachNetStream(_media_stream);
                _media_video.smoothing = true;
                addChild(_media_video);
                
                __draw_black_background(stage.stageWidth, stage.stageHeight);
                setChildIndex(_media_video, 0);

            });
            
            if (this._url.indexOf("http") == 0) 
            {
                this._media_conn.connect(null);
            } 
            else 
            {
                var tcUrl:String = this._url.substr(0, this._url.lastIndexOf("/"));
                this._media_conn.connect(tcUrl);
            }
        }
        
        
        private function reconnect(evt:TimerEvent):void
        {
            if (_status == PAUSED || _status == STARTED || _status == STARTING)
            {
                return;
            }
            if(this._status == STOPPED)
            {
                if (this._url.indexOf("http") == 0) 
                {
                    _media_conn.connect(null);
                } 
                else 
                {
                    var tcUrl:String = this._url.substr(0, this._url.lastIndexOf("/"));
                    this._media_conn.connect(tcUrl);
                }
                return;
            }
            _current_time = _media_stream.time;
        }
        
        
        private function __get_video_size_object():Object 
        {
            var obj:Object = 
            {
                width: _media_video.width,
                height: _media_video.height
            };
            
            // override with metadata size.
            if (this._media_metadata.hasOwnProperty("width")) 
            {
                obj.width = this._media_metadata.width;
            }
            if (this._media_metadata.hasOwnProperty("height")) 
            {
                obj.height = this._media_metadata.height;
            }
            
            // override with codec size.
            if (_media_video.videoWidth > 0) 
            {
                obj.width = _media_video.videoWidth;
            }
            if (_media_video.videoHeight > 0) 
            {
                obj.height = _media_video.videoHeight;
            }
            
            return obj;
        }
        
        
        //全屏模式
        private function __execute_user_enter_fullscreen():void 
        {
            //trace("user_fs_refer:", user_fs_refer);
            //trace("user_fs_percent:", user_fs_percent);
            if (!_user_fs_refer || _user_fs_percent <= 0) 
            {
                return;
            }
            
            var obj:Object = __get_video_size_object();
            var den:int = _user_dar_den;
            var num:int = _user_dar_num;
            
            if (den == 0) 
            {
                den = obj.height;
            }
            if (den == -1) 
            {
                den = this.stage.fullScreenHeight;
            }
            if (num == 0) 
            {
                num = obj.width;
            }
            if (num == -1) 
            {
                num = this.stage.fullScreenWidth;
            }
                
            // for refer is screen.
            if (_user_fs_refer == "screen") 
            {
                obj = {
                    width: this.stage.fullScreenWidth,
                    height: this.stage.fullScreenHeight
                };
            }
            
            // rescale to fs
            __update_video_size(num, den, 
                obj.width * _user_fs_percent / 100, 
                obj.height * _user_fs_percent / 100, 
                this.stage.fullScreenWidth, this.stage.fullScreenHeight
            );
        }
        
        
        private function __execute_user_set_dar():void 
        {
            var den:int = _user_dar_den;
            var num:int = _user_dar_num;
            
            var obj:Object = __get_video_size_object();
            
            if (den == 0) 
            {
                den = obj.height;
            }
            if (den == -1) 
            {
                den = this._height;
            }
            
            if (num == 0) 
            {
                num = obj.width;
            }
            if (num == -1) 
            {
                num = this._width;
            }
            
            __update_video_size(num, den, this._width, this._height, this._width, this._height);
        }
        
        
        private function __update_video_size(_num:int, _den:int, _w:int, _h:int, _sw:int, _sh:int):void 
        {
            if (!this._media_video || _den <= 0 || _num <= 0) 
            {
                return;
            }
            
            // set DAR.
            // calc the height by DAR
            var _height:int = _w * _den / _num;
            if (_height <= _h) 
            {
                this._media_video.width = _w;
                this._media_video.height = _height;
            } 
            else 
            {
                // height overflow, calc the width by DAR
                var _width:int = _h * _num / _den;
                
                this._media_video.width = _width;
                this._media_video.height = _h;
            }
            
            // align center.
            this._media_video.x = (_sw - this._media_video.width) / 2;
            this._media_video.y = (_sh - this._media_video.height) / 2;
            
            __draw_black_background(_sw, _sh);
        }
        
        
        private function __draw_black_background(_width:int, _height:int):void 
        {
            // draw black bg.
            this.graphics.beginFill(0x00, 1.0);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();
            
            // draw the fs mask.
            this.control_fs_mask.graphics.beginFill(0xff0000, 0);
            this.control_fs_mask.graphics.drawRect(0, 0, _width, _height);
            this.control_fs_mask.graphics.endFill();
        }
        
        
        private function log(msg:String):void 
        {
            
            msg = "[" + new Date() +"][sunlands-player][" + _config._js_id + "] " + msg;
            
            if (!flash.external.ExternalInterface.available) 
            {
                flash.utils.setTimeout(log, 300, msg);
                return;
            }
            if (ExternalInterface.available)
            {
                //ExternalInterface.call("console.log", msg);
            }
            
        }
        
        
        private function on_enter_frame(e:Event):void
        {
            if (!this._is_live && _media_stream)
            {
                if (ExternalInterface.available)
                {
                    ExternalInterface.call(_callback._js_on_update_loaded_video, _config._js_id, (_media_stream.bytesLoaded / Number(_media_stream.bytesTotal)).toFixed(2));
                }
            }
            
            if (this._is_live || (_media_stream && _media_stream.bytesLoaded == _media_stream.bytesTotal))
            {
                stage.removeEventListener(Event.ENTER_FRAME,on_enter_frame);
            }
        }
        
    }
}