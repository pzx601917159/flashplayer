/*****************************************************
*  
*  Copyright 2009 Adobe Systems Incorporated.  All Rights Reserved.
*  
*****************************************************
*  The contents of this file are subject to the Mozilla Public License
*  Version 1.1 (the "License"); you may not use this file except in
*  compliance with the License. You may obtain a copy of the License at
*  http://www.mozilla.org/MPL/
*   
*  Software distributed under the License is distributed on an "AS IS"
*  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
*  License for the specific language governing rights and limitations
*  under the License.
*   
*  
*  The Initial Developer of the Original Code is Adobe Systems Incorporated.
*  Portions created by Adobe Systems Incorporated are Copyright (C) 2009 Adobe Systems 
*  Incorporated. All Rights Reserved. 
*  
*****************************************************/
package org.osmf.net.httpstreaming.flv
{
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import player.AMFParser;
	
	[ExcludeClass]
	
	/**
	 * @private
	 */ 
	public class FLVParser
	{
		public var _metadata:Object = null;
		//是否从文件头解析
		public function FLVParser(startWithFileHeader:Boolean)
		{
			super();
			//保存数据的
			savedBytes = new ByteArray();
			if (startWithFileHeader)
			{
				state = FLVParserState.FILE_HEADER;
			}
			else
			{
				state = FLVParserState.TYPE;
			}
		}
		
		public function flush(output:IDataOutput):void
		{
			output.writeBytes(savedBytes);
		}
		
		//解析flv
		public function parse(input:IDataInput, consumeAll:Boolean, onEachFLVTag:Function):void
		{
			var continueParsing:Boolean = true;
			var source:IDataInput;
			
			var date:Date = new Date();
			while (continueParsing)
			{
				switch (state)
				{
					//解析flv的header
					case FLVParserState.FILE_HEADER:
						//必须大于flv头部的长度，9个字节
						source = byteSource(input, FLVHeader.MIN_FILE_HEADER_BYTE_COUNT);
						if (source != null)
						{
							flvHeader = new FLVHeader();
							flvHeader.readHeader(source);
							trace("flv parse header complete");
							state = FLVParserState.FILE_HEADER_REST;
						}
						else
						{
							continueParsing = false;
						}
						break;
						
					case FLVParserState.FILE_HEADER_REST:
						source = byteSource(input, flvHeader.restBytesNeeded);
						if (source != null)
						{
							flvHeader.readRest(source);
							state = FLVParserState.TYPE;
						}
						else
						{
							continueParsing = false;
						}
						break;
					//解析flv的tag type
					case FLVParserState.TYPE:
			
						source = byteSource(input, 1); // just the first byte of the header
						if (source != null)
						{
							var type:int = source.readByte();
							
							switch (type)
							{
								case FLVTag.TAG_TYPE_AUDIO:
								case FLVTag.TAG_TYPE_ENCRYPTED_AUDIO:
									currentTag = new FLVTagAudio(type);
									break;
								case FLVTag.TAG_TYPE_VIDEO:
								case FLVTag.TAG_TYPE_ENCRYPTED_VIDEO:
									currentTag = new FLVTagVideo(type);
									break;
								case FLVTag.TAG_TYPE_SCRIPTDATAOBJECT:
								case FLVTag.TAG_TYPE_ENCRYPTED_SCRIPTDATAOBJECT:
									trace("script data");
									currentTag = new FLVTagScriptDataObject(type);
									break;
								default:
									currentTag = new FLVTag(type);	// the generic case
									break;
							}
							state = FLVParserState.HEADER;//接下来解析tag header，这个是状态机
						}
						else
						{
							continueParsing = false;
						}
						break;
						
					case FLVParserState.HEADER:
				
						source = byteSource(input, FLVTag.TAG_HEADER_BYTE_COUNT - 1); // first byte was read in previous state,上个状态机已经读了一个字节
						if (source != null)
						{
							currentTag.readRemainingHeader(source);	
							if (currentTag.dataSize)
							{
								state = FLVParserState.DATA;
							}
							else
							{
								state = FLVParserState.PREV_TAG;
							}
						}
						else
						{
							continueParsing = false;
						}
						break;
						
					case FLVParserState.DATA:
					
						source = byteSource(input, currentTag.dataSize);
						if (source != null)
						{
							currentTag.readData(source);
							if (currentTag.tagType == FLVTag.TAG_TYPE_SCRIPTDATAOBJECT)
							{
								trace("-----------------------");
								//打印metadata的信息
								//trace("-----------script data:", currentTag.data.toString());
								var data:ByteArray = new ByteArray();
								data.writeBytes(currentTag.data);
								trace("data.bytesAvalible", data.bytesAvailable);
								data.position = 0;
								trace("data.bytesAvalible", data.bytesAvailable);
								if (data.bytesAvailable > 0)
								{
									switch(data.readByte())
									{
										case AMFParser.AMF_TYPE_STRING:
											var s:String = AMFParser.get_amf_string(data);
											trace("--------------s:", s);
											if (s == "onMetaData")
											{
												trace("pppppppppppppparse metadata");
												if (_metadata == null)
												{
													_metadata = AMFParser.parse_metadata(data);
												}
												trace("_mmmmmmmmmmmmmmmmmmmmetadata", _metadata["user_data"]);
											}
											break;
										default:
											break;
									}
								}
							}
							state = FLVParserState.PREV_TAG;
						}
						else
						{
							continueParsing = false;
						}
						break;
						
					case FLVParserState.PREV_TAG:
		
						source = byteSource(input, FLVTag.PREV_TAG_BYTE_COUNT);
						if (source != null)
						{
							currentTag.readPrevTag(source);
							state = FLVParserState.TYPE;
							continueParsing = onEachFLVTag(currentTag);
						}
						else
						{
							continueParsing = false;
						}
						break;
					
					default:
						throw new Error("FLVParser state machine in unknown state");
						break;
				} // switch
			} // while continueParsing
			
			if (consumeAll)
			{
				input.readBytes(savedBytes, savedBytes.length);
			}
		} // parse

		//参数1:输入数据 参数2：需要的字节数
		private function byteSource(input:IDataInput, numBytes:int):IDataInput
		{
			//必须要大于规定的字节数
			if (savedBytes.bytesAvailable + input.bytesAvailable < numBytes)
			{
				return null;
			}
			
			if (savedBytes.bytesAvailable)
			{
				var needed:int = numBytes - savedBytes.bytesAvailable;
				if (needed > 0)
				{
					input.readBytes(savedBytes, savedBytes.length, needed);
				}
				return savedBytes;
			}
			
			savedBytes.length = 0;
			
			return input;
		}

		private var state:String;					//状态
		private var savedBytes:ByteArray;			//已经解析的bytes
		private var currentTag:FLVTag = null;		//当前的tag
		private var flvHeader:FLVHeader; 			//flv头
		public var metadata:Object = new Object(); 	//用来存储metadata
	}
}