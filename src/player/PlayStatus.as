package player 
{
	/**
	 * 播放器播放状态 
	 * @author pzx
	 * 
	 */	
	public class PlayStatus
	{
		/**
		 *视频停止状态，一般是正常的停止行为，比如手动停止、文件播放结束
		 */		
		public static var STOP:String = "stop";
		/**
		 *首次播放加载中 
		 */		
		public static var LOADING:String = "loading";
		/**
		 *二次缓冲中 
		 */		
		public static var BUFFERING:String = "buffering";
		/**
		 *视频播放中 
		 */		
		public static var PLAYING:String = "playing";
		/**
		 *视频暂停 
		 */		
		public static var PAUSED:String = "pause";
		/**
		 *视频搜索中 
		 */		
		public static var SEEKING:String = "seeking";
		/**
		 *处于错误中 
		 */		
		public static var ONERROR:String = "onError";
	}
}