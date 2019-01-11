package player 
{
	
	import flash.utils.ByteArray;
	import net.SunlandsHttp;
	import org.httpclient.events.HttpDataEvent;
	import org.osmf.net.httpstreaming.flv.FLVTag;
	import org.osmf.net.httpstreaming.flv.FLVTagVideo;
	import flash.events.Event;
	import org.osmf.net.httpstreaming.flv.FLVParser;
	import n.h264.NALUnit;
	import com.codeazur.utils.BitArray;
	import org.osmf.net.httpstreaming.flv.FLVHeader;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.media.Video;
	import flash.net.NetStreamAppendBytesAction;
	import org.httpclient.events.HttpStatusEvent;
	import flash.events.NetStatusEvent;
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	
	/**
	 * ...
	 * @author pzx
	 */
	//支持http-range的播放器
	public class RangeVideoPlayer extends BasePlayer
	{
		public var _http_client:SunlandsHttp;
		public var _buffer:ByteArray = new ByteArray();
		private var intra_frames:Vector.<FLVTagVideo> = new Vector.<FLVTagVideo>();
		//用来解析flv
		public var _parser:FLVParser = new FLVParser(true);
		private var _seq_header:FLVTagVideo;
		private var _parsing:Boolean = false;
		//duration是通过metadata解析出来的
		public var _duration:Number = 0;
		//总的content_length，只初始化一次
		public var _content_length:Number = 0;
		//seek的content-length
		public var _seek_bytes:Number = 0;
		//当前加载的bytes
		public var _current_bytes:Number = 0;
		//进度条更新的定时器
		private var _progress_bar_timer:Timer = new Timer(Config._progress_bar_time);
		//seek的时间
		public var _seek_time:Number = 0;
		//当前时间
		public var _current_time:Number = 0;
		
		public function RangeVideoPlayer() 
		{
		}
		
		//播放
		override public function play():void
		{
			_seek_bytes = 0;
			_seek_time = 0;
			_progress_bar_timer.start();
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
			_http_client.get_with_range(_url, 0, this.on_data, this.on_complete, this.on_http_status);
		}
		
		public function on_metadata(metadata:Object):void
		{
			trace("ns--------------on metadata");
			for (var key in metadata)
			{
				trace("----------------" + key + metadata[key]);
			}
		}
		
		public function net_status_handler(evt:NetStatusEvent):void
		{
			if (evt.info.code == "Netstream.Play.Stop"){
				_ns.appendBytesAction(NetStreamAppendBytesAction.END_SEQUENCE);
			}
		}
		
		public function on_status(e:NetStatusEvent):void
		{
			//trace("=============================");
			trace(e.info.code);
			trace(e.info.code);
		}
		
		//接收到数据的处理
		public function on_data(event:HttpDataEvent):void 
		{
			//trace("-----on http data event");
			//只需要解析出来前面的索引文件即可
			//_buffer.writeBytes(event.bytes);
			_buffer = event.bytes;
			_buffer.position = 0;
			
			//trace("-------------------on http data event",_buffer.bytesAvailable);
			if (_buffer.bytesAvailable > 0)
			{
				_ns.appendBytes(_buffer);
				_current_bytes += _buffer.length;
				
			}
			//这里再自己解析一遍来获取索引文件和metadata时间
			/*解析metadata*/
			_parser.parse(_buffer, true, on_each_flvtag);
			_buffer.clear();
			
		};
		
		//处理每个tag
		private function on_each_flvtag(flv_tag:FLVTag):Boolean 
		{
			//视频
			if (flv_tag.tagType == FLVTag.TAG_TYPE_VIDEO) 
			{
				var video_tag:FLVTagVideo = flv_tag as FLVTagVideo;
				switch (video_tag.avcPacketType) 
				{
					case FLVTagVideo.AVC_PACKET_TYPE_NALU:
						//trace("flv nalu");
						intra_frames.push(video_tag);
						var data:ByteArray = video_tag.data;
						data.position = 0;
						data.readInt();
						//trace(data.bytesAvailable);
						//trace(data.readByte());
						if (data.readByte() != 65)
						{
							if (data.readByte() == 5)
							{
								trace(data.readByte());//判断这个是不是==0XFF
								trace("get sei iiiiiiiiiiiiiiiiiiiii");
								var sequence:String = data.readUTFBytes(16);
								trace(sequence);
							}
						}
						break;
					case FLVTagVideo.AVC_PACKET_TYPE_SEQUENCE_HEADER:
						_seq_header = video_tag;
						break;
				}
			}
			return true;
		}
				
		public function on_complete(e:Event):void
		{
			trace("-----oncomplete", e);
		}
		
		public function on_http_status(e:HttpStatusEvent):void 
		{
			trace("===================");
			trace("on http status", e.response.header.getValue("Content-Length"));
			if (_content_length == 0)
			{
				_content_length = Number(e.response.header.getValue("Content-Length"));
			}
		}
	}

}