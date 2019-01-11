package net 
{
	
	
	import org.httpclient.HttpClient;
	import com.adobe.net.URI;
	import org.httpclient.HttpRequest;
	import org.httpclient.HttpResponse;
	import org.httpclient.events.HttpRequestEvent;
	import org.httpclient.events.HttpResponseEvent;
	import org.httpclient.events.HttpStatusEvent;
	import org.httpclient.http.Get;
	
	/**
	 * ...
	 * @author pzx
	 */
	//封装http请求
	public class SunlandsHttp 
	{
		private var _http_client:HttpClient = null;
		public function SunlandsHttp() 
		{
		}
		
		public function get(url:String,http_data_callback:Function, http_complete_callback:Function, http_status_callback:Function)
		{
			_http_client = new HttpClient();
			var uri:URI = new URI(url);
			var request:HttpRequest = new Get();
			request.addHeader('User-Agent', 'VLC/2.2.8 LibVLC/2.2.8');
			//设置http的回调函数
			_http_client.listener.onData = http_data_callback;
			_http_client.listener.onComplete = http_complete_callback;
			_http_client.listener.onStatus = http_status_callback;
			
			_http_client.request(uri, request);
		}
		
		//添加range header
		public function get_with_range(url:String, bytes:Number, http_data_callback:Function, http_complete_callback:Function, http_status_callback:Function)
		{
			_http_client = new HttpClient();
			var uri:URI = new URI(url);
			var request:HttpRequest = new Get();
			request.addHeader('User-Agent', 'VLC/2.2.8 LibVLC/2.2.8');
			request.addHeader('Range', 'bytes=' + bytes.toFixed(0) + '-');
			request.addHeader('Icy-Metadata', "1");
			//设置http的回调函数
			_http_client.listener.onData = http_data_callback;
			_http_client.listener.onComplete = http_complete_callback;
			_http_client.listener.onStatus = http_status_callback;
			
			_http_client.request(uri, request);
		}
		
		public function close()
		{
			_http_client.close();
			_http_client = null;
		}
	}

}