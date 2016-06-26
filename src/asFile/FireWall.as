package asFile
{
	import flash.events.MouseEvent;

	/**
	 * 防火墙卡设置选项
	 */
	public class FireWall extends TransImage
	{
		public var choosed:Boolean=false;
		public var Mode:String;
		public var inMap:Boolean=false;
		
		public function FireWall(mode:String,istrue:Boolean=false)
		{
			super("check/"+mode+"firewall.png");
			Mode=mode;
			inMap=istrue;
			if(istrue==false)
			{
				this.alpha=.1;
				this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
				this.addEventListener(MouseEvent.MOUSE_OUT,onOut);
				this.addEventListener(MouseEvent.CLICK,onClick1);
			}
		}
		
		public function resume():void
		{
			this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,onOut);
			this.addEventListener(MouseEvent.CLICK,onClick1);
			this.removeEventListener(MouseEvent.CLICK,onClick2);
			this.alpha=.1;
			choosed=false;
		}
		
		private function onOver(e:MouseEvent):void
		{
			this.alpha=.5;
		}
		
		private function onOut(e:MouseEvent):void
		{
			this.alpha=.1;
		}
		
		private function onClick1(e:MouseEvent):void
		{
			this.removeEventListener(MouseEvent.MOUSE_OVER,onOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT,onOut);
			this.addEventListener(MouseEvent.CLICK,onClick2);
			this.removeEventListener(MouseEvent.CLICK,onClick1);
			this.alpha=.75;
		}
		
		private function onClick2(e:MouseEvent):void
		{
			this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,onOut);
			this.addEventListener(MouseEvent.CLICK,onClick1);
			this.removeEventListener(MouseEvent.CLICK,onClick2);
			this.alpha=.1;
		}
	}
}