package asFile
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	
	import mx.controls.Image;
	import mx.core.UIComponent;

	/**
	 * 用于此程序中大部分外部图片转为组件
	 */

	
	public class TransImage extends UIComponent
	{
		
		private var Tx:Number=0;
		private var Ty:Number=0;
		private var Rx:Number=0;
		private var Ry:Number=0;
		private var Rz:Number=0;
		private var timer:Timer;
		private var transTimeX:int=0;
		private var transTimeY:int=0;
		private var rotateTimeX:int=0;
		private var rotateTimeY:int=0;
		private var rotateTimeZ:int=0;
		private var maxTime:int=0;
		private var midTime:Boolean=false;
		
		protected var image:Bitmap;
		protected var cbitmapdata:BitmapData;
		private var backdata:BitmapData;
		private var l:Loader;
		
		public function TransImage(bit:Object)
		{
			super();
			if(bit is Bitmap)
			{
				image=Bitmap(bit);
				image.x=-image.width/2;
				image.y=-image.height/2;
				this.addChild(image);
			}else if(bit is BitmapData)
			{
				image=new Bitmap(bit as BitmapData);
				image.x=-image.width/2;
				image.y=-image.height/2;
				this.addChild(image);
			}else if(bit is Image)
			{
				var bmpData:BitmapData=new BitmapData(bit.width,bit.height,true,0);
				bmpData.draw(Image(bit));
				image=new Bitmap(bmpData);
				image.x=-image.width/2;
				image.y=-image.height/2;
				this.addChild(image);
			}else if(bit is String)
			{
				l=new Loader();
				l.load(new URLRequest(String(bit)));
				//l.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void{trace(e.toString())});  
				l.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoaded);
			}
		}
		private function onLoaded(e:Event):void
		{
			var bmd:BitmapData=new BitmapData(l.content.width,l.content.height,true,0);
			bmd.draw(l);
			image=new Bitmap(bmd);
			image.x=-image.width/2;
			image.y=-image.height/2;
			backdata=image.bitmapData;
			this.addChild(image);
			this.width=image.width;
			this.height=image.height;
			l.contentLoaderInfo.removeEventListener(Event.COMPLETE,onLoaded);
		}
		
		//返回宽
		public function getWidth():Number
		{
			return image.width;
		}
		
		//返回高
		public function getHeight():Number
		{
			return image.height;
		}
		
		public  function moveX(tx:Number,time:Number):void
		{
			Tx=(tx-this.x);
			timer=new Timer(20,time/20);
			timer.addEventListener(TimerEvent.TIMER,startMoveX);
			transTimeX=0;
			maxTime=time/20;
			timer.start();
		}
		public  function moveY(ty:Number,time:Number):void
		{
			Ty=(ty-this.y);
			timer=new Timer(20,time/20);
			timer.addEventListener(TimerEvent.TIMER,startMoveY);
			transTimeY=0;
			maxTime=time/20;
			timer.start();
		}
		
		private  function startMoveX(e:TimerEvent):void
		{
			transTimeX++;
			this.x +=6*Tx*(-Math.pow(transTimeX,2)+maxTime*transTimeX)/(Math.pow(maxTime,3));
		}
		
		private  function startMoveY(e:TimerEvent):void
		{
			transTimeY++;
			this.y +=6*Ty*(-Math.pow(transTimeY,2)+maxTime*transTimeY)/(Math.pow(maxTime,3));
		}
		
		public  function rotateX(speed:Number,time:int=0):void
		{
			Rx=speed;
			rotateTimeX=0;
			timer=new Timer(20,time);
			timer.addEventListener(TimerEvent.TIMER,onRotateX);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onRotateXcomplete);
			timer.start();
		}
		private function onRotateX(e:TimerEvent):void
		{
			if(!midTime)
			{
				this.rotationX +=Rx;
				//this.alpha -=Rx/250;
			}
			else
			{
				this.rotationX +=Rx;
				//this.alpha +=Rx/250;
			}
			if((this.rotationX>=90||this.rotationY<=-90)&&!midTime)
			{
				changeBitmap();
				this.rotationX +=180;
				midTime=!midTime;
			}
		}
		private function onRotateXcomplete(e:TimerEvent):void
		{
			midTime=false;
			e.target.removeEventListener(TimerEvent.TIMER,onRotateX);
			e.target.removeEventListener(TimerEvent.TIMER_COMPLETE,onRotateXcomplete);
		}
		
		public  function rotateY(speed:Number,time:int=0):void
		{
			Ry=speed;
			rotateTimeY=0;
			timer=new Timer(20,time);
			timer.addEventListener(TimerEvent.TIMER,onRotateY);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onRotateYcomplete);
			timer.start();
		}
		public function backY(speed:Number=18,time:int=10):void
		{
			setBackBitmapData(backdata);
			Ry=speed;
			rotateTimeY=0;
			timer=new Timer(20,time);
			timer.addEventListener(TimerEvent.TIMER,onRotateY);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onRotateYcomplete);
			timer.start();
		}
		private function onRotateY(e:TimerEvent):void
		{
			if(!midTime)
			{
				this.rotationY +=Ry;
			}
			else
			{
				this.rotationY +=Ry;
			}
			if((this.rotationY>=90||this.rotationY<=-90)&&!midTime)
			{
				changeBitmap();
				this.rotationY +=180;
				midTime=!midTime;
			}
		}
		private function onRotateYcomplete(e:TimerEvent):void
		{
			midTime=false;
			e.target.removeEventListener(TimerEvent.TIMER,onRotateY);
			e.target.removeEventListener(TimerEvent.TIMER_COMPLETE,onRotateYcomplete);
		}
		
		public  function rotateZ(speed:Number,time:int=0):void
		{
			Rz=speed;
			rotateTimeZ=0;
			timer=new Timer(20,time);
			timer.addEventListener(TimerEvent.TIMER,onRotateZ);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE,onRotateZcomplete);
			timer.start();
		}
		private function onRotateZ(e:TimerEvent):void
		{
			this.rotationZ +=Rz;
		}
		private function onRotateZcomplete(e:TimerEvent):void
		{
			midTime=false;
			e.target.removeEventListener(TimerEvent.TIMER,onRotateZ);
			e.target.removeEventListener(TimerEvent.TIMER_COMPLETE,onRotateZcomplete);
		}
		
		public  function setBackBitmapData(cbit:BitmapData):void
		{
			cbitmapdata=cbit;
		}
		public  function getBackBitmapData():BitmapData
		{
			return cbitmapdata;
		}
		public  function setBackBitmapData2(cbit:Bitmap):void
		{
			cbitmapdata=cbit.bitmapData;
		}
		public  function setBackBitmapData3(cbit:String):void
		{
			var l:Loader=new Loader();
			l.load(new URLRequest(String(cbit)));
			l.contentLoaderInfo.addEventListener(Event.COMPLETE,onBackLoaded);
		}
		private function onBackLoaded(e:Event):void
		{
			cbitmapdata=Bitmap(e.target.content).bitmapData;
			e.target.removeEventListener(Event.COMPLETE,onBackLoaded);
		}
		
		public function changeBitmap():void
		{
			var temp:BitmapData=this.image.bitmapData;
			this.image.bitmapData=cbitmapdata;
			cbitmapdata=temp;
		}
		
		//拉伸图像
		public function setSize(w:Number,h:Number):void
		{
			image.width=w;
			image.height=h;
		}
	}
}