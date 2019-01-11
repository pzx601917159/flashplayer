package player 
{
	/**
	 * ...
	 * @author pzx
	 */
	public class Config 
	{
		static public const _version:String = "SunlandsPlayer v1.0.1 2018.8.15";
		static public var _is_live:int = 0;
		static public var _js_id:String = null;
		static public const _progress_bar_time:int = 1000;//进度条1秒钟更新一次
		static public var _buffer_time:Number = 3;//默认视频的buffer_time为5s
		static public var _debug:int = 0;
		//点播用来拖拽的两个数组
		static public var _file_positions:Array = new Array();
		static public var _times:Array = new Array();
		public function Config() 
		{
		}
	}

}