package asFile
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.net.URLRequest;
	
	public class MyBitmap extends Bitmap
	{
		public function MyBitmap(stress:String)
		{
			super();
			var l:Loader=new Loader();
			l.load(new URLRequest(stress));
			l.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void
			{
				var bitmap:Bitmap=Bitmap(l.content);
				this.width=bitmap.width;
				this.height=bitmap.height;
				this=bitmap;
			});
		}
	}
}