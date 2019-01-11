package player 
{
	/**
	 * ...
	 * @author pzx
	 */
	//提供控制接口
	public class Control 
	{
		//构造
		public function Control() 
		{
		}
		
		//播放
		public function js_call_play(obj:Object)
		{
		}
		
		//停止
		public function js_call_stop():void 
		{
			
		}
		
		//暂停
		public function js_call_pause():void
		{
		}
		
		//恢复
		public function js_call_resume():void 
		{
			
		}
		
		//设置视频比例
        public function js_call_set_dar(num:int, den:int):void 
		{
			
		}
		
		//设置画面占比
        public function js_call_set_fs_size(refer:String, percent:int):void 
		{
			
		}
		
		//设置buffer_time
		public function js_call_set_bt(buffer_time:Number):void 
		{
			
		}
		
		//设置音量
		public function js_call_set_volume(volume:Number):void
		{
			
		}
		
		//拖拽进度条
        private function js_call_seek_video(seekPoint:Number):void
		{
			
		}
	}

}