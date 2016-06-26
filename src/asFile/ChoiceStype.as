package asFile
{
	import flash.events.MouseEvent;

	/**
	 * 棋子移动的选项
	 */
	public class ChoiceStype extends TransImage
	{
		private var originY:Number;
		private var originX:Number;
		
		public function ChoiceStype(bit:Object)
		{
			super(bit);
			this.alpha=.5;
			this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
			this.addEventListener(MouseEvent.CLICK,onClick);
		}
		
		private function onOver(e:MouseEvent):void
		{
			this.alpha=.8;
			originY=this.y;
			originX=this.x;
			TweenLite.to(this,.2,{x:originX/2,y:originY/2});
			this.parent.addChild(this);
			this.addEventListener(MouseEvent.MOUSE_OUT,onOut);
		}
		
		private function onOut(e:MouseEvent):void
		{
			this.alpha=.5;
			TweenLite.to(this,.2,{x:originX,y:originY});
			this.removeEventListener(MouseEvent.MOUSE_OUT,onOut);
		}
		
		private function onClick(e:MouseEvent):void
		{
			TweenLite.to(this,.2,{x:0,y:0});
		}
	}
}