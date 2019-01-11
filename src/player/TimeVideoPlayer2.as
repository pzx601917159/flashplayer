package player 
{
	
	import player.VideoPlayer;
	/**
	 * ...
	 * @author pzx
	 */
	public class TimeVideoPlayer2 extends VideoPlayer
	{
		
		public function TimeVideoPlayer2() 
		{
			
		}
		
		/**
		 * 搜索
		 * @param pos
		 * 
		 */		
		override public function seek(position:Number):void
		{
			_url += "&start=";
			_url += position.toString();
			_ns.play(_url);
		}
		
		
	}

}