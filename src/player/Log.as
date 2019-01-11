package player 
{
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	
	/**
	 * ...
	 * @author pzx
	 */
	//用来打印日志的类
	public class Log 
	{
		
		public function Log() 
		{
			
		}
		//输出日志到控制台
		static public function log(msg:String)
		{
			if (!Config._debug)
			{
				return;
			}
			msg = "[" + new Date() +"][sunlands-player]" + msg;
            
            if (!flash.external.ExternalInterface.available) 
            {
                flash.utils.setTimeout(log, 300, msg);
                return;
            }
            if (ExternalInterface.available)
            {
                ExternalInterface.call("console.log", msg);
            }
		}
		
	}

}