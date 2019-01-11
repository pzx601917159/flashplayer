package player 
{
	import flash.events.TimerEvent;
	import player.BasePlayer;
	import flash.external.ExternalInterface;
	import flash.events.Event;
	import player.Config;
	import player.Callback;
	import flash.utils.Timer;
	import flash.events.NetStatusEvent;
	import flash.media.Video;
	/**
	 * ...
	 * @author pzx
	 */
	//video player 使用自己的http
	public class VideoPlayer extends player.BasePlayer
	{
		//视频时长属性
		public var _duration:Number = 0;
		//点播的其实序列号
		private var _start_sequence:Number = 0;
		//进度条更新的定时器
		private var _progress_bar_timer:Timer = new Timer(Config._progress_bar_time);
		public function VideoPlayer()
		{
			_is_live = false;
			//TODO开始播放再start
			this._progress_bar_timer.addEventListener(TimerEvent.TIMER, this.on_progress_bar_time);
		}
		
		private function on_progress_bar_time(evt:TimerEvent):void 
        {
			Log.log("on_progress_bar_time:" + _ns.time);
			trace("on_progress_bar_time:" + _ns.time);
			//if (_ns.time == 0)
			if (ExternalInterface.available)
            {
                flash.external.ExternalInterface.call(Callback._js_on_update_media_time, Config._js_id, _ns.time);
            }
        }
		
		//暂停
		override public function pause():void
		{
			super.pause();
			_progress_bar_timer.stop();
		}
		
		//恢复
		override public function resume():void 
		{
			super.resume();
			_progress_bar_timer.start();
		}
		
		override public function ns_status_handler(evt:NetStatusEvent):void
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
				_progress_bar_timer.start();
				_play_status = PlayStatus.PLAYING;
				if (_video)
				{
					_video.clear();
					_video = null;
				}
				_video = new Video(stage.stageWidth, stage.stageHeight);
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
				_progress_bar_timer.stop();
				_play_status = PlayStatus.STOP;
				//点播不需要释放
				//stop();
				if (ExternalInterface.available)
				{
					ExternalInterface.call(Callback._js_on_player_status, Config._js_id, _play_status);
				}
			}
			else if (evt.info.code == "NetStream.Seek.InvalidTime")
			{
				trace(evt.info.details);
				_progress_bar_timer.start();
			}
			else if (evt.info.code == "NetStream.Seek.Notify")
			{
				_progress_bar_timer.start();
			}
			else if (evt.info.code == "NetStream.Seek.Failed")
			{
				_progress_bar_timer.start();
			}
			else if (evt.info.code == "NetStream.Buffer.Full")
			{    
			}
			// TODO: FIXME: failed event.
		}
		
		//视频的metadata需要duration
		override public function metadata_handler(metadata:Object):void 
		{
			super.metadata_handler(metadata);
            
            var time:Number = 0;
            // for js.
            var obj:Object = get_video_size_object();
            var key:String;
            for (key in metadata)
            {
                obj[key] = metadata[key];
                if (key == "user_data")
                {
                    time = Number(metadata[key]);
                    obj[key] = time;
                }
				//duration点播才需要
                if (key == "duration")
                {
                    _duration = Number(metadata[key]);
                }
            }
            obj["user_time"] = _ns.time;
            if (_duration > 0 )
            {
                obj["totoal_time"] = _duration;
            }
			
            if (ExternalInterface.available)
            {
                var code:int = flash.external.ExternalInterface.call(Callback._js_on_player_metadata, Config._js_id, obj);
                if (code != 0) 
                {
                    throw new Error("callback on_player_metadata failed. code=" + code);
                }
            }
			
		}
		
		//视频需要进度条的回调
		override public function on_enter_frame(e:Event):void
        {
			trace("on enter frame");
            if (!this._is_live && _ns)
            {
                if (ExternalInterface.available)
                {
                    ExternalInterface.call(Callback._js_on_update_loaded_video, Config._js_id, (_ns.bytesLoaded / Number(_ns.bytesTotal)).toFixed(2));
                }
            }
            
            if (this._is_live || (_ns && _ns.bytesLoaded == _ns.bytesTotal))
            {
                stage.removeEventListener(Event.ENTER_FRAME,on_enter_frame);
            }
        }
		
		/**
		 * 搜索
		 * @param pos
		 * 
		 */		
		override public function seek(position:Number):void
		{
			if (_ns)
			{
				//TODO增加seek事件的处理函数
				_ns.seek(position);
				//防止点播进度条出现错误的情况
				_progress_bar_timer.stop();
			}
		}
	}

}

