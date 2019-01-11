package flvparser 
{
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author pzx
	 */
	//flvparser 用来解析flv文件
	public class flvparser 
	{
		var _buffer:ByteArray = new ByteArray();
		public function flvparser() 
		{
			
		}
		
		public function parse(buffer:ByteArray)
		{
			_buffer.writeBytes(_buffer)
			//还有数据就进行解析
			if (_buffer.bytesAvailable > 0)
			{
				
			}
		}
	}

}