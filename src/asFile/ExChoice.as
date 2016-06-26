package asFile
{
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	
	/**
	 * 用于显示404 not found的交换选项
	 */
	
	public class ExChoice extends UIComponent
	{
		private var choice1:TransImage=new TransImage("sys/switch.png");
		private var choice2:TransImage=new TransImage("sys/nswitch.png");
		
		public function ExChoice()
		{
			super();
			choice1.alpha=0;
			choice2.alpha=0;
			choice1.x=-315;
			choice2.y=-105;
			choice1.x=315;
			choice2.y=105;
			this.addChild(choice1);
			this.addChild(choice2);
			this.visible=false;
		}
		
		public function appear():void
		{
			this.visible=true;
			this.width=parent.width;
			this.height=parent.height;
			
			TweenLite.to(choice1,.3,{alpha:.5,x:0});
			TweenLite.to(choice2,.3,{alpha:.5,x:0,onComplete:mousehandle});
		}
		
		public function disappear():void
		{
			TweenLite.to(this,.3,{autoAlpha:0});
		}
		
		
		public function btnPress(target:Object):int
		{
			if(target !=choice1&&target !=choice2)
				return 0;
			else if(target !=choice2)
				return 1;
			else
				return 2;
		}
		
		private function mousehandle():void
		{
			this.addEventListener(MouseEvent.MOUSE_OVER,onOver);
			this.addEventListener(MouseEvent.MOUSE_OUT,onOut);
		}
		
		private function onOver(e:MouseEvent):void
		{
			if(e.target !=choice1&&e.target !=choice2)
				return;
			TweenLite.to(e.target,.3,{alpha:1});
		}
		
		private function onOut(e:MouseEvent):void
		{
			if(e.target !=choice1&&e.target !=choice2)
				return;
			TweenLite.to(e.target,.3,{alpha:.5});
		}
	}
}