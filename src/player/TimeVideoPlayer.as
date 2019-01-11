package player 
{
	import flash.geom.Rectangle;
	import player.VideoPlayer;
	import player.TimeVideoPlayer;
	import flash.net.NetStreamAppendBytesAction;
	import net.SunlandsHttp;
	import player.Log;
	import flash.events.NetStatusEvent;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.media.Video;
	
	/**
	 * ...
	 * @author pzx
	 */
	//支持通过时间戳参数seek的播放器
	//和videoplayer的不同只有seek的时候
	public class TimeVideoPlayer extends RangeVideoPlayer
	{
		
		public function TimeVideoPlayer() 
		{	
		}
		
		//播放
		override public function play():void
		{
			Log.log("range video Player");
			this.stop();
            if (this._url.indexOf("http") == 0) 
            {
                //this._nc.connect(null);
            } 
            else 
            {
				//不是http开头的直接报错
				Log.log("invalid format");
            }
			//建立http连接
			//从0开始获取
			if (_http_client)
			{
				_http_client.close();
				_http_client = null;
			}
			//清理资源
			_nc = new NetConnection();
			_nc.connect(null);
			_ns = new NetStream(_nc);
			_ns.addEventListener(NetStatusEvent.NET_STATUS, on_status);
			_ns.client = {};
			_ns.client.onMetadata = on_metadata;
			_ns.bufferTime = 3;
			_video = new Video(stage.stageWidth, stage.stageHeight);
			_video.attachNetStream(_ns);
			addChild(_video);
			
			_ns.play(null);
			_ns.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			_ns.addEventListener(NetStatusEvent.NET_STATUS, net_status_handler);
			
			_http_client = new SunlandsHttp();
			_http_client.get(_url, this.on_data, this.on_complete, this.on_http_status);
		}
		
		//这里的seek自己实现
		override public function seek(position:Number):void
		{
			Log.log("dddddddddddddddddddddddutation:" + _parser._metadata["duration"]);
			//如果没拿到_duration，则不允许range
			if (_parser._metadata["duration"] == undefined || _parser._metadata["duration"] < 0 || 
					position < 0 || position > _parser._metadata["duration"])
			{
				return;
			}
			Log.log("sssssssssssssssseek");
			_url += "&start=" + position;
			
			
			_ns.seek(0);
			_ns.appendBytesAction(NetStreamAppendBytesAction.RESET_SEEK);
			//新建http请求
			if (_http_client)
			{
				_http_client.close();
			}
			_http_client = new SunlandsHttp();
			_http_client.get(_url, this.on_data, this.on_complete, this.on_http_status);
		}
		
	}

}