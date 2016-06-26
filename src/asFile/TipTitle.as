package asFile
{
	import mx.core.UIComponent;
	
	import spark.components.Label;
	
	public class TipTitle extends UIComponent
	{
		private static var bar:TransImage=new TransImage("image/bar.png");
		private static var text:Label=new Label();
		
		public function TipTitle()
		{
			super();
			text.y=15;
			text.setStyle("fontSize",40);
			text.setStyle("color",0xffffff);
			this.visible=false;
			this.addChild(bar);
			this.addChild(text);
		}
		//设置显示文字
		public function setText(str:String):void
		{
			text.text=str;
			text.width=29*length();
			text.height=30;
		}
		
		//返回字符串长度
		public function length():int
		{
			return text.text.length;
		}
		
		//开始动画
		public function play(screenWidth:Number):void
		{
			bar.x=-bar.width;
			text.x=-text.width;
			this.visible=true;
			TweenLite.to(bar,.4,{x:screenWidth/2});
			TweenLite.to(text,.4,{x:(screenWidth-text.width)/2,delay:.4});
			TweenLite.to(bar,.4,{x:screenWidth+bar.width/2,delay:1.5,onComplete:reset,overwrite:0});
			TweenLite.to(text,.4,{x:screenWidth,delay:1.3,overwrite:0});
		}
		
		//重置
		private function reset():void
		{
			bar.x=-bar.width;
			this.visible=false;
		}
	}
}