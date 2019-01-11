package 
{
	import flash.display.Sprite;
	import player.BasePlayer;
	import player.Config;
	import player.Callback;
	import flash.events.Event;
	import flash.display.StageScaleMode;
	import flash.system.Security;
	import flash.utils.Timer;
	import flash.external.ExternalInterface;
	import flash.ui.ContextMenuItem;
	import flash.events.ContextMenuEvent;
	import flash.display.StageDisplayState;
	import flash.ui.ContextMenu;
    import flash.ui.ContextMenuBuiltInItems;
    import flash.ui.ContextMenuClipboardItems;
    import flash.ui.ContextMenuItem;
    import flash.events.ContextMenuEvent;
	import player.Log;
	import player.LivePlayer;
	import player.RangeVideoPlayer;
	import player.TimeVideoPlayer;
	import player.VideoPlayer;
	import flash.events.MouseEvent;
	import player.TimeVideoPlayer2;
	
	/**
	 * ...
	 * @author pzx
	 */
	public class SunPlayer extends Sprite
	{
		//基础的player
		private var _player:player.BasePlayer = null;
		//右键菜单相关
		private var _menuItemVersion:ContextMenuItem = null;
		//右键菜单相关
		private var _menuItemFullScreenModel:ContextMenuItem = null;
		//mask用来支持单机全屏功能
		public var _control_fs_mask:Sprite = new Sprite();
		
		public function SunPlayer() 
		{
			Log.log("construct");
			if (!this.stage) 
            {
                this.addEventListener(Event.ADDED_TO_STAGE, this.system_on_add_to_stage);
            } 
            else 
            {
                this.system_on_add_to_stage(null);
            }
		}
		
		//画一个黑色的背板
		private function __draw_black_background(_width:int, _height:int):void 
        {
            // draw black bg.
            this.graphics.beginFill(0x00, 1.0);
            this.graphics.drawRect(0, 0, _width, _height);
            this.graphics.endFill();
            
            // draw the fs mask.
            this._control_fs_mask.graphics.beginFill(0xff0000, 0);
            this._control_fs_mask.graphics.drawRect(0, 0, _width, _height);
            this._control_fs_mask.graphics.endFill();
        }
		
		private function user_on_click_video(evt:MouseEvent):void 
        {   
            // enter fullscreen to get the fullscreen size correctly.
            if (this.stage.displayState == StageDisplayState.FULL_SCREEN) 
            {
                this.stage.displayState = StageDisplayState.NORMAL;
                _player._width = this.stage.stageWidth;
                _player._height = this.stage.stageHeight;
				_player.update_video_size();
				_menuItemFullScreenModel.enabled = false;
                
            } 
            else 
            {
                this.stage.displayState = StageDisplayState.FULL_SCREEN;
                _player._width = this.stage.stageWidth;
                _player._height = this.stage.stageHeight;
				_player.update_video_size();
				_menuItemFullScreenModel.enabled = true;
            }
        }
		
		//注意这个右键菜单要放在playerBase中
		private function system_on_add_to_stage(evt:Event):void 
        {
			this.addChild(this._control_fs_mask);
            this._control_fs_mask.buttonMode = true;
            this._control_fs_mask.addEventListener(MouseEvent.CLICK, user_on_click_video);
			
			Log.log("system_on_add_to_stage");
            this.removeEventListener(Event.ADDED_TO_STAGE, this.system_on_add_to_stage);
            this.stage.scaleMode = StageScaleMode.EXACT_FIT;
            Security.allowDomain("*");
			//Security.loadPolicyFile("http://1253751088.vod2.myqcloud.com/crossdomain.xml");
            
            var flashvars:Object = this.root.loaderInfo.parameters;            
            Config._js_id = flashvars.id;
			Config._is_live = flashvars.is_live;
			//Config._debug = flashvars.debug;
			Config._debug = 1;
			Config._is_live = 1;
			Log.log("is_live:" + Config._is_live);
			Log.log("debug:" + Config._debug);
			if (Config._is_live)
			{
				//直播的播放器使用自己实现的http range
				//_player = new LivePlayer();
				_player = new RangeVideoPlayer();
			}
			else
			{
				//使用netstream
				_player = new VideoPlayer();
				//使用http range
				//_player = new RangeVideoPlayer();
				//使用start=xxx
				//_player = new TimeVideoPlayer2();
			}
			addChild(_player);
			Callback._js_on_player_ready 		= flashvars.on_player_ready;
            Callback._js_on_player_metadata 	= flashvars.on_player_metadata;
            Callback._js_on_player_timer 		= flashvars.on_player_timer;
            Callback._js_on_player_empty 		= flashvars.on_player_empty;
            Callback._js_on_player_full 		= flashvars.on_player_full;
			//deprecated
            //Callback._js_on_player_stop 		= flashvars.on_player_stop;
			Callback._js_on_update_loaded_video = flashvars.on_update_loaded_video;
			Callback._js_on_update_media_time 	= flashvars.on_update_media_time;
			Callback._js_on_player_status       = flashvars.on_player_status;
			
			create_right_menu();
			
            flash.utils.setTimeout(this.system_on_js_ready, 0);
			//play( { "url":"rtmp://10.247.62.68/live/livestream", "width":400, "height":300, "buffer_time":3, "volume":1.0 } );
			//play({"url":"http://1253751088.vod2.myqcloud.com/351633e7vodgzp1253751088/b68464165285890780586259046/f0.flv?t=5b9162fa&us=d0961978&sign=bd04caef7d9a447c2b199b6f4e7d037f", "is_live":1, "width":800, "height":600, "buffer_time":3, "volume":1.0});
			//play( { "url":"http://10.247.62.68:8081/live/livestream.flv", "width":400, "height":300, "buffer_time":3, "volume":1.0 } );
			play( { "url":"http://pull-ws-dev-live.sunlands.com/bb76c352fe19e763a88b3c60e00a3e575f4e2a2c.flv?wsSecret=d133d96e30f56b1cad0473e6d0ccdb9d&wsABSTime=5c24e0f8", "width":400, "height":300, "buffer_time":3, "volume":1.0 } );
            
        }
		
		//右键菜单功能
		private function create_right_menu():void 
        {
            _menuItemVersion = new ContextMenuItem(Config._version, false, false);
            //_menuItemFullScreenModel = new ContextMenuItem("切换全屏模式", false, true);
			_menuItemFullScreenModel = new ContextMenuItem("切换全屏模式", false, false);
			if (this.stage.displayState == StageDisplayState.FULL_SCREEN) 
            {
				_menuItemFullScreenModel.enabled = true;
			}
            var customItems:Array = new Array();
            customItems.push(_menuItemVersion);
            customItems.push(_menuItemFullScreenModel);
			this.contextMenu = new ContextMenu();
            this.contextMenu.hideBuiltInItems();
			
            this.contextMenu.customItems = customItems;
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
		
		//设置js可以调用的函数
        private function system_on_js_ready():void 
        {
			Log.log("-------system_on_js_ready");
            if (!flash.external.ExternalInterface.available)
            {
				Log.log("js not ready, try later");
                flash.utils.setTimeout(this.system_on_js_ready, 1000);
                return;
            }
            
            if (flash.external.ExternalInterface.available)
            {	
				//注意这里要先new出来player才行
                flash.external.ExternalInterface.addCallback("__play", this.play);
				Log.log("js is ready2");
                flash.external.ExternalInterface.addCallback("__stop", _player.stop);
                flash.external.ExternalInterface.addCallback("__pause", _player.pause);
                flash.external.ExternalInterface.addCallback("__resume", _player.resume);
				//TODO
				flash.external.ExternalInterface.addCallback("__set_dar", _player.set_dar);
                flash.external.ExternalInterface.addCallback("__set_fs", _player.set_fs_size);
                flash.external.ExternalInterface.addCallback("__set_bt", _player.set_bt);
                flash.external.ExternalInterface.addCallback("__set_volume", _player.set_volume);
                flash.external.ExternalInterface.addCallback("__seek_video", _player.seek);
				
				Log.log("-------on js ready");
                flash.external.ExternalInterface.call(Callback._js_on_player_ready, Config._js_id);
            }
        }
		
		//播放的接口
		public function play(obj:Object)
		{
			Log.log("js call play");
			_player.init(obj);
			_player.play();
			//画一个黑色的背板
			__draw_black_background(stage.stageWidth, stage.stageHeight);
            setChildIndex(_player, 0);
			//不是在直播需要添加缓冲更新的回调
			if (!Config._is_live)
			{
				stage.addEventListener(Event.ENTER_FRAME, _player.on_enter_frame);
			}
		}
		
	}

}