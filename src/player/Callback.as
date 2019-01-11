package player 
{
	/**
	 * ...
	 * @author pzx
	 */
	// 回调类，用来管理回调函数
	public class Callback 
	{
		// 回调函数
		static public var _js_on_player_ready:String = null;
        static public var _js_on_player_metadata:String = null;
        static public var _js_on_player_timer:String = null;
        static public var _js_on_player_empty:String = null;
        static public var _js_on_player_full:String = null;
        static public var _js_on_player_stop:String = null;
		static public var _js_on_update_loaded_video:String = null;
		static public var _js_on_update_media_time:String = null;
		static public var _js_on_player_status:String = null;
		
		// 构造
		public function Callback() 
		{
			
		}
		
		// 初始化回调函数
		static public function init(flashvars:Object)
		{
			_js_on_player_ready 		= flashvars.on_player_ready;
            _js_on_player_metadata 		= flashvars.on_player_metadata;
            _js_on_player_timer 		= flashvars.on_player_timer;
            _js_on_player_empty 		= flashvars.on_player_empty;
            _js_on_player_full 			= flashvars.on_player_full;
            _js_on_player_stop 			= flashvars.on_player_stop;
			_js_on_update_loaded_video 	= flashvars.on_update_loaded_video;
			_js_on_update_media_time 	= flashvars.on_update_media_time;
			_js_on_player_status 		= flashvars.on_player_status;
		}
		
	}

}