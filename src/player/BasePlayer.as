package player 
{
	import flash.display.Sprite;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.events.NetStatusEvent;
	import flash.ui.ContextMenuItem;
	import flash.events.ContextMenuEvent;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.external.ExternalInterface;
	import flash.media.SoundTransform;
	import flash.utils.Timer;
	import flash.events.MouseEvent;
	import flash.events.Event;
	
	/**
	 * ...
	 * @author pzx
	 */
	//liveplayer和videoplayer的基类
	public class BasePlayer extends Sprite
	{
		//connection
		public var _nc:NetConnection = null;
		//stream
		public var _ns:NetStream = null;
		//video
		public var _video:Video = null;
		//是否为直播
		public var _is_live:Boolean = false;
		//音量
		public var _volume:Number = 0;
		//播放地址
		public var _url:String = null;
		//video宽
        public var _width:int = 0;
		//video高
        public var _height:int = 0;
		//播放状态
		public var _play_status:String = PlayStatus.STOP;
		//直播缓冲大小,TODO放到子类里面去
		public var _buffer_time:Number = 0;
		//日志对象
		public var _log:Log = new Log();
		//metadata计数
		public var _metadata_count:int = 0;
		//metadata
		public var _metadata:Object = null;
		//
		public var _user_dar_num:int = 0;
		//
		public var _user_dar_den:int = 0;
        private var _user_fs_refer:String = null;
        private var _user_fs_percent:int = 0;

		public function BasePlayer() 
		{
		}
		
		public function init(obj:Object)
		{
			trace("------------------init");
			this._url = obj.url;
			this._height = obj.height;
			this._width = obj.width;
			this._volume = obj.volume;
			this._metadata_count = 0;
			this._buffer_time = obj.buffer_time;
			trace("buffer_time", this._buffer_time);
			if (this._metadata)
			{
				_metadata = null;
				_metadata = new Object();
			}
			trace("-----------width" + obj["width"]);
		}
		
		public function ns_status_handler(evt:NetStatusEvent):void
		{
			if (evt.info.code != "NetStream.Buffer.Full" && evt.info.code != "NetStream.Buffer.Empty")
			{
				trace("NetConnection: code=" + evt.info.code);
			}
			if (evt.info.code == "NetStream.Video.DimensionChange") 
			{
				//system_on_metadata(_media_metadata);
			} 
			else if (evt.info.code == "NetStream.Buffer.Empty") 
			{
				//system_on_buffer_empty();
			} 
			else if (evt.info.code == "NetStream.Buffer.Full") 
			{
				//system_on_buffer_full();
			}
			else if (evt.info.code == "NetStream.Play.Start")
			{
				trace("--------------start");
				_play_status = PlayStatus.PLAYING;
				Log.log("play status change:" + _play_status);
				if (_video)
				{
					_video.clear();
					_video = null;
				}
				_video = new Video(stage.stageWidth, stage.stageHeight);
				//_video = new Video();
				_video.attachNetStream(_ns);
				_video.smoothing = true;
				addChild(_video);
				if (ExternalInterface.available)
				{
					ExternalInterface.call(Callback._js_on_player_status, Config._js_id, _play_status);
				}
			}
			else if (evt.info.code == "NetStream.Play.Stop")
			{
				trace("----------------stop");
				stop();
			}
			else if (evt.info.code == "NetStream.Seek.InvalidTime")
			{
				trace(evt.info.details);
			}
			else if (evt.info.code == "NetStream.Seek.Notify")
			{ 
			}
			else if (evt.info.code == "NetStream.Buffer.Full")
			{    
			}
			// TODO: FIXME: failed event.
		}
		
		
		public function get_video_size_object():Object 
        {
            var obj:Object = 
            {
                width: _video.width,
                height: _video.height
            };
            
            // override with metadata size.
            if (this._metadata.hasOwnProperty("width")) 
            {
                obj.width = this._metadata.width;
            }
            if (this._metadata.hasOwnProperty("height")) 
            {
                obj.height = this._metadata.height;
            }
            
            // override with codec size.
            if (_video.videoWidth > 0) 
            {
                obj.width = _video.videoWidth;
            }
            if (_video.videoHeight > 0) 
            {
                obj.height = _video.videoHeight;
            }
            
            return obj;
        }
		
		public function metadata_handler(metadata:Object):void 
        {
            _metadata_count += 1;
			
            if (!this._metadata || !this._metadata.hasOwnProperty("width")) 
            {
                this._metadata = metadata;
            }			
        }
		
		private function nc_status_handler(evt:NetStatusEvent):void
		{
			if (evt.info.code != "NetStream.Buffer.Full" && evt.info.code != "NetStream.Buffer.Empty")
            {
                trace("NetConnection: code=" + evt.info.code);
            }
            trace("NetConnection: code=" + evt.info.code);
                
            if (evt.info.code == "NetConnection.Connect.Closed")
            {
                _play_status = PlayStatus.STOP;
				Log.log("play status change:" + _play_status);
				if (ExternalInterface.available)
				{
					ExternalInterface.call(Callback._js_on_player_status, Config._js_id, _play_status);
				}
            }
                
            // TODO: FIXME: failed event.
            if (evt.info.code != "NetConnection.Connect.Success") 
            {
                return;
            }
            if (_ns) 
			{
				_ns.close();
				_ns == null;
			}
            _ns = new NetStream(_nc);
			_ns.useHardwareDecoder = true;
            _ns.soundTransform = new SoundTransform(_volume);
            _ns.bufferTime = _buffer_time;
            _ns.client = {};
            _ns.bufferTimeMax = 0;
            _ns.client.onMetaData = metadata_handler;
            //_ns.client.onImageData = system_on_imagedata;
            _ns.addEventListener(NetStatusEvent.NET_STATUS, ns_status_handler);
                
            if (_url.indexOf("http") == 0) 
            {
                //media_conn.connect
                _ns.close();
                _ns.play(_url, -1);
            } 
            else 
            {
                var streamName:String = _url.substr(_url.lastIndexOf("/") + 1);
                if (this._is_live)
                {
                    _ns.play(streamName, -1);
                }
                else
                {
                    _ns.play(streamName);
                }
            }
           
            trace("width:" + _width + "height:" + _height);
			_video = new Video(stage.stageWidth, stage.stageHeight);
            //trace("_width:", _width, "height:", _height);
            _video.attachNetStream(_ns);
            _video.smoothing = true;
			addChild(_video);    
            //__draw_black_background(stage.stageWidth, stage.stageHeight);
            //setChildIndex(_video, 0);
		}
		
		//播放
		public function play():void
		{
			Log.log("baseplayer Play");
			this.stop();
			_nc = new NetConnection();
			_nc.client = { };
			_nc.client.onBWDone = function():void { };
			_nc.addEventListener(NetStatusEvent.NET_STATUS, nc_status_handler);
			
			
            if (this._url.indexOf("http") == 0) 
            {
                this._nc.connect(null);
            } 
            else 
            {
                var tcUrl:String = this._url.substr(0, this._url.lastIndexOf("/"));
                this._nc.connect(tcUrl);
            }
		}
		
		//暂停
		public function pause():void
		{
			if (this._ns)
			{
				_ns.pause();
				_play_status = PlayStatus.PAUSED;
				Log.log("play status change:" + _play_status);
				if (ExternalInterface.available)
				{
					ExternalInterface.call(Callback._js_on_player_status, Config._js_id, _play_status);
				}
			}
		}
		
		//恢复
		public function resume():void 
		{
			if (this._ns && _play_status == PlayStatus.PAUSED)
			{
				this._ns.resume();
				this._play_status = PlayStatus.PLAYING;
				Log.log("play status change:" + _play_status);
				if (ExternalInterface.available)
				{
					ExternalInterface.call(Callback._js_on_player_status, Config._js_id, _play_status);
				}
			}
		}
		
		//设置画面占比
        public function set_fs_size(refer:String, percent:int):void 
        {
            _user_fs_refer = refer;
            _user_fs_percent = percent;
        }
		
		//设置视频比例
        public function set_dar(num:int, den:int):void 
        {
            _user_dar_num = num;
            _user_dar_den = den;
            
            flash.utils.setTimeout(__execute_user_set_dar, 0);
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
		
		private function __get_video_size_object():Object 
        {
            var obj:Object = 
            {
                width: _video.width,
                height: _video.height
            };
            
            // override with metadata size.
            if (this._metadata.hasOwnProperty("width")) 
            {
                obj.width = this._metadata.width;
            }
            if (this._metadata.hasOwnProperty("height")) 
            {
                obj.height = this._metadata.height;
            }
            
            // override with codec size.
            if (_video.videoWidth > 0) 
            {
                obj.width = _video.videoWidth;
            }
            if (_video.videoHeight > 0) 
            {
                obj.height = _video.videoHeight;
            }
            
            return obj;
        }
		
		//更新视频尺寸
		public function update_video_size():void
		{
			if (this._video)
			{
				this._video.width = _width;
				this._video.height = _height;
			}
		}
		
		private function __update_video_size(_num:int, _den:int, _w:int, _h:int, _sw:int, _sh:int):void 
        {
            if (!this._video || _den <= 0 || _num <= 0) 
            {
                return;
            }
            
            // set DAR.
            // calc the height by DAR
            var _height:int = _w * _den / _num;
            if (_height <= _h) 
            {
                this._video.width = _w;
                this._video.height = _height;
            } 
            else 
            {
                // height overflow, calc the width by DAR
                var _width:int = _h * _num / _den;
                
                this._video.width = _width;
                this._video.height = _h;
            }
            
            // align center.
            this._video.x = (_sw - this._video.width) / 2;
            this._video.y = (_sh - this._video.height) / 2;
            
        }
		
		//设置buffertimer
		public function set_bt(bt:Number):void
		{
			_ns.bufferTime = bt;
		}
		
		//停止
		public function stop():void
		{
			if (this._video) 
            {
                this.removeChild(this._video);
                this._video = null;
            }
            if (this._ns) 
            {
                this._ns.close();
                this._ns = null;
            }
            if (this._nc) 
            {
                this._nc.close();
                this._nc = null;
            }
			_play_status = PlayStatus.STOP;
			Log.log("play status change:" + _play_status);
			if (ExternalInterface.available)
			{
				ExternalInterface.call(Callback._js_on_player_status, Config._js_id, _play_status);
			}
		}
		
		/**
		 * 搜索
		 * @param pos
		 * 
		 */		
		public function seek(position:Number):void
		{
			if (_ns)
			{
				//TODO增加seek事件的处理函数
				_ns.seek(position);
			}
		}
		
		/*
		 * 设置音量 
		 */
		public function set_volume(volume:Number):void
		{
			Log.log("set volume");
			if (volume < 0 || volume > 1.0)
            {
                return;
            }
			if (_ns)
			{
				_volume = volume;
				_ns.soundTransform = new SoundTransform(volume);
			}
		}
		
		/**
		 * 获取音量 
		 * @return 
		 * 
		 */		
		public function get volume():Number
		{
			return _volume;
		}
		/**
		 * 设置音量 
		 * @param volume 0-100
		 * 
		 */		
		public function set volume(v:Number):void
		{
			_volume = v;
		}
		
		/**
		 * 是否静音 
		 * @return 
		 * 
		 */		
		public function get mute():Boolean
		{
			return false;
		}
		/**
		 * 设置静音 
		 * @param bool
		 * 
		 */		
		public function set mute(bool:Boolean):void
		{
			
		}
		/**
		 * 当前播放位置 
		 * @return 
		 * 
		 */		
		public function get position():Number
		{
			return 0;
		}
		
		/**
		 * 缓冲百分比
		 * @return 0-100
		 * 
		 */		
		public function get bufferPercent():Number
		{
			return 0;
		}
		
		/**
		 * 获取当前播放状态 
		 * @return 
		 * 
		 */		
		public function get playStat():String
		{
			return _play_status;
		}
		
		/**
		 * 重新设置大小 
		 * @param w
		 * @param h
		 * 
		 */		
		public function resize(w:Number, h:Number):void
		{
			
		}
		
		/*
		 * 释放 NetStream 对象存放的所有资源
		 */
		public function dispose():void
		{
			
		}
		
		//视频需要进度条的回调
		public function on_enter_frame(e:Event):void
        {
        }
		
	}

}