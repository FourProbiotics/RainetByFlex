package asFile
{
	import flash.events.MouseEvent;

	/**
	 * 终端卡按钮
	 */
	public class Terminal extends TransImage
	{
		public var haveUsed:Boolean=false;
		public var canUse:Boolean=true;
		public var paused:Boolean=false;
		public var nowAlpha:Number=1;
		//se
		private static var se_click2:Music=new Music("se/se02.mp3");
		
		public function Terminal(bit:Object)
		{
			super(bit);
			this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,onOut);
		}
		
		public function used():void
		{
			TweenLite.to(this,.4,{alpha:.4});
			this.removeEventListener(MouseEvent.MOUSE_OVER,onOver);
			haveUsed=true;
			nowAlpha=.4;
		}
		
		public function pause():void
		{
			paused=true;
			TweenLite.to(this,.4,{alpha:.4});
			this.removeEventListener(MouseEvent.MOUSE_OVER,onOver);
		}
		
		public function resume():void
		{
			paused=false;
			nowAlpha=1;
			TweenLite.to(this,.4,{alpha:nowAlpha});
			this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
			haveUsed=false;
		}
		
		public function change():void
		{
			paused=false;
			TweenLite.to(this,.4,{alpha:nowAlpha});
			if(this.canUse)
				this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
		}
		
		private function onOver(e:MouseEvent):void
		{
			this.scaleX=this.scaleY=1;
			se_click2.play();
		}
		
		private function onOut(e:MouseEvent):void
		{
			this.scaleX=this.scaleY=.9;
		}
	}
}