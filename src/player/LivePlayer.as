package player 
{
	import player.BasePlayer;
	import flash.external.ExternalInterface;
	/**
	 * ...
	 * @author pzx
	 */
	// liveplayer的网络层全部使用netstream
	public class LivePlayer extends player.BasePlayer
	{	
		public function LivePlayer() 
		{
			_is_live = true;
		}
		
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
					trace("user_data", time);
                }
            }
            obj["user_time"] = time;
			obj["dropframes"] = _ns.info.droppedFrames;
			trace("dropframes:", _ns.info.droppedFrames);

            if (ExternalInterface.available)
            {
                var code:int = flash.external.ExternalInterface.call(Callback._js_on_player_metadata, Config._js_id, obj);
                if (code != 0) 
                {
                    throw new Error("callback on_player_metadata failed. code=" + code);
                }
            }
		}
		
	}

}