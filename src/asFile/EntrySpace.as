package asFile
{
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.core.UIComponent;
	
	public class EntrySpace extends UIComponent
	{
		private var ball:TransImage=new TransImage("check/选中1.png");
		private var circle:TransImage=new TransImage("check/选中2.png");
		private var circleSpeed:Number=0.01;
		private var t:Timer=new Timer(20);
		
		public function EntrySpace()
		{
			super();
			this.addChild(ball);
			this.addChild(circle);
			this.alpha=.5;
			circle.mouseEnabled=false;
			t.addEventListener(TimerEvent.TIMER,onTimer);
			this.addEventListener(MouseEvent.ROLL_OVER,changeAlpha);
			
		}
		
		private function onTimer(e:TimerEvent):void
		{
			circle.rotationY +=7.2;
		}
		
		private function changeAlpha(e:MouseEvent):void
		{
			TweenLite.to(this,.3,{alpha:1});
			t.start();
			this.addEventListener(MouseEvent.ROLL_OUT,changeAlpha2);
		}
		private function changeAlpha2(e:MouseEvent):void
		{
			this.removeEventListener(MouseEvent.ROLL_OUT,changeAlpha2);
			t.stop();
			TweenLite.to(this,.3,{alpha:.5});
			TweenLite.to(circle,.3,{rotationY:0});
		}
	}
}