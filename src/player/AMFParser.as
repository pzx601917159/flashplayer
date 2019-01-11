package player 
{
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author pzx
	 */
	//用来解析amf格式
	public class AMFParser 
	{
		public static const AMF_TYPE_NUMBER:int 		= 0;	//对应double类型
		public static const AMF_TYPE_BOOL:int 			= 1;	//对用bool类型
		public static const AMF_TYPE_STRING:int 		= 2;
		public static const AMF_TYPE_OBJECT:int 		= 3;
		public static const AMF_TYPE_MOVIECLIP:int 		= 4;
		public static const AMF_TYPE_NULL:int 			= 5;
		public static const AMF_TYPE_UNDEFINED:int 		= 6;
		public static const AMF_TYPE_REFERENCE:int 		= 7;
		public static const AMF_TYPE_MIXEDARRAY:int 	= 8;
		public static const AMF_TYPE_ENDOFOBJECT:int 	= 9;
		public static const AMF_TYPE_ARRAY:int 			= 10;
		public static const AMF_TYPE_DATA:int	 		= 11;
		public static const AMF_TYPE_LONGSTRING:int 	= 12;
		public static const AMF_TYPE_UNSUPPORTED:int 	= 13;
		public static const AMF_TYPE_RECORDSET:int 		= 14;
		public static const AMF_TYPE_XML:int 			= 15;
		public static const AMF_TYPE_TYPEDOBJECT:int 	= 16;
		public static const AMF_TYPE_AMF3DATA:int    	= 17;
		
		public function AMFParser() 
		{
		}
		
		//获取AMF数据类型
		static public function get_amf_type(bytes:ByteArray):int
		{
			return bytes.readByte();
		}
		
		//获取string
		static public function get_amf_string(bytes:ByteArray):String
		{
			//获取长度，再获取string
			var len:int = bytes.readShort();
			if (len > 0 || len <= bytes.bytesAvailable)
			{
				return bytes.readUTFBytes(len);
			}
			return null;			
		}
		
		static public function get_amf_array(bytes:ByteArray):Array
		{
			//trace("get amf array")
			var num:int = bytes.readInt();
			var arr:Array = new Array();
			var type:int;
			for (var i:int = 0; i < num;++i)
			{
				type = bytes.readByte();
				switch(type)
				{
					case AMF_TYPE_STRING:
						arr[i] = get_amf_string(bytes);
						break;
					case AMF_TYPE_NUMBER:
						arr[i] = bytes.readDouble();
						break;
				}
			}
			for (var i:int = 0; i < num;++i )
			{
				//trace(arr[i]);
			}
			return arr;
		}

		static public function parse_metadata(bytes:ByteArray):Object
		{
			var metadata:Object = new Object();
			var key:String = new String();
			var value:String = new String();
			var type:int = bytes.readByte();
			//trace("ttttttttttttttype:", type);
			//读取metadata的类型
			switch(type)
			{
				case AMF_TYPE_MIXEDARRAY:
					metadata = parse_mixedarray(bytes);
					if (metadata["filepositions"])
					{
						Config._file_positions = metadata["filepositions"]
					}
					if (metadata["times"])
					{
						Config._times = metadata["times"];
					}
					break;
				default:
					break;
			}
			return metadata;
		}
		
		//解析mixedarray，这里得到fileposition和times两个数组，用来存储拖拽相关的数
		static public function parse_mixedarray(bytes:ByteArray):Object
		{
			var obj:Object = new Object();
			var key:String = new String();
			//mixedarray里面成员的数量
			var num:int = bytes.readInt();
			//trace("mixed array num = :", num);
			var type:int;
			for (var i:int = 0; i < num;++i )
			{
				key = get_amf_string(bytes);
				//trace("key", key);
				type = bytes.readByte();
				//trace("xxxxxxxxxxxxxxxxxxxxx", type);
				switch(type)
				{
					case AMF_TYPE_STRING:
						var value_string:String = get_amf_string(bytes);
						//trace("valu", value_string);
						obj[key] = value_string;
						break;
					case AMF_TYPE_BOOL:
						var value_bool:Boolean = bytes.readBoolean();
						trace(value_bool);
						obj[key] = value_bool;
						break;
					case AMF_TYPE_NUMBER:
						var value_num:Number = bytes.readDouble();
						trace(value_num);
						obj[key] = value_num;
						break;
					//嵌套了object
					case AMF_TYPE_OBJECT:
						var new_obj:Object = new Object();
						var s:String = new String();
						var read_end_object:Boolean = false;
						while (!read_end_object)
						{
							s = get_amf_string(bytes);
							//trace("sssssssssssssss", s);
							type = bytes.readByte();
							//trace("ttttttttttttttt", type);
							switch(type)
							{
								case AMF_TYPE_ARRAY:
									var arr:Array = get_amf_array(bytes);
									new_obj[s] = arr;
									if (s == "filepositions")
									{
										Config._file_positions = arr;
									}
									else if (s == "times")
									{
										Config._times = arr;
									}
									break;
								case AMF_TYPE_ENDOFOBJECT:
									//00 00 09
									bytes.readUTFBytes(3);
									read_end_object = true;
									break;
							}
						}
						obj[key] = new_obj;
						break;
				}
				
			}
			//trace("ooooooooooooooooduration",obj["duration"]);
			return obj;
		}
		
	}

}