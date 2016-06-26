package asFile
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	/**
	 * 棋子类
	 */
	
	public class Chess extends TransImage
	{
		public var speedUp:Boolean=false;
		public var notfound:Boolean=false;
		public var isLink:int=0;
		private var transspeed:Number=-0.02;
		private var l:Loader;
		private var Type:String="";
		private var chessName:String="";
		private var link:BitmapData=new BitmapData(70,70,true,0x00000000);
		private var virus:BitmapData=new BitmapData(70,70,true,0x00000000);
		private var nFound:BitmapData=new BitmapData(70,70,true,0x00000000);
		private var focus1:TransImage;
		private var focus2:TransImage;
		private var speedLogo:TransImage;
		private var notFound:TransImage;
		private var lineBoost:TransImage;
		private var checker:TransImage;
		//预加载音效
		private static var se_click1:Music=new Music("se/se01.mp3");
		private static var se_move:Music=new Music("se/se07.mp3");
		
		public function Chess(type:String)
		{
			super("check/"+type+"back.png");
			Type=type;
			
			if(type=="B")
			{
				setFace(link,"check/Blink.png");
				setFace(virus,"check/Bvirus.png");
			}else if(type=="G")
			{
				setFace(link,"check/Glink.png");
				setFace(virus,"check/Gvirus.png");
			}
			BlockPic.myTimer(2000,init,1);
			
		}
		
		private function init(e:TimerEvent):void
		{
			focus1=new TransImage("check/focus1.png");
			focus2=new TransImage("check/focus2.png");
			speedLogo=new TransImage("check/speed.png");
			if(Type=="B")
			{
				chessName="check/Bback.png";
				notFound=new TransImage("check/Bnotfound.png");
				lineBoost=new TransImage("check/Blineboost.png");
				checker=new TransImage("check/Bviruschecker.png");
				setFace(nFound,"check/Bnotfound.png");
			}else if(Type=="G")
			{
				chessName="check/Gback.png";
				notFound=new TransImage("check/Gnotfound.png");
				lineBoost=new TransImage("check/Glineboost.png");
				checker=new TransImage("check/Gviruschecker.png");
				setFace(nFound,"check/Gnotfound.png");
			}
			speedLogo.mouseEnabled=false;
			focus1.mouseEnabled=false;
			focus2.mouseEnabled=false;
			notFound.mouseEnabled=false;
			lineBoost.mouseEnabled=false;
			checker.mouseEnabled=false;
		}
		
		//返回类别
		public function getType():String
		{
			return Type;
		}
		
		//设置卡面
		public function setLink(islink:int):void
		{
			this.isLink=islink;
			if(islink==1)
				setBackBitmapData(link);
			else if(islink==2)
				setBackBitmapData(virus);
			this.rotateY(18,10);
		}
		
		
		//设置notFound
		public function setNotFound():void
		{
			setBackBitmapData(nFound);
			this.rotateY(18,10);
			notfound=true;
		}
		
		//取消notFound
		public function cancelNotFound():void
		{//trace("getBackBitmapData",getBackBitmapData())
			if(notfound)
			{
				this.rotateY(18,10);
				notfound=false;
			}
		}
		
		private function setFace(bmd:BitmapData,fileName:String):void
		{
			var loader:Loader=new Loader();
			loader.load(new URLRequest(fileName));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void
			{
				var bitmap:Bitmap=Bitmap(loader.content);
				bmd.draw(bitmap);
			});
		}
		
		//添加加速标志
		public function speedup():void
		{
			speedUp=true;
			TweenLite.to(speedLogo,.4,{autoAlpha:.5});
			BlockPic.myTimer(20,logoalphachange);
		}
		//取消加速标志
		public function speeddown():void
		{
			speedLogo.alpha=1;
			TweenLite.to(speedLogo,.4,{autoAlpha:0});
			speedUp=false;
		}
		
		private function logoalphachange(e:TimerEvent):void
		{
			speedLogo.alpha +=transspeed;
			if(speedLogo.alpha >=.5)
			{
				speedLogo.alpha=.5;
				transspeed=-transspeed;
			}else if(speedLogo.alpha <=0)
			{
				speedLogo.alpha=0;
				transspeed=-transspeed;
			}
			this.addChild(speedLogo);
		}
		
		public function onfocus1():void
		{
			se_click1.play();//se
			if(focus1.parent==null)
				this.addChild(focus1);
		}
		public function disfocus1():void
		{
			if(focus1.parent !=null)
				this.removeChild(focus1);
		}
		public function onfocus2():void
		{
			se_click1.play();//se
			if(focus2.parent==null)
			{
				this.addChild(focus2);
			}
		}
		public function disfocus2():void
		{
			if(focus2.parent !=null)
				this.removeChild(focus2);
		}
		public function lineOver():void
		{
			se_click1.play();//se
			this.addChild(lineBoost);lineBoost.alpha=.6;
		}
		public function lineOut():void
		{
			if(lineBoost.parent !=null)
				this.removeChild(lineBoost);
		}
		public function notFoundOver():void
		{
			se_click1.play();//se
			this.addChild(notFound);notFound.alpha=.6;
		}
		public function notFoundOut():void
		{
			if(notFound.parent !=null)
				this.removeChild(notFound);
		}
		public function checkerOver():void
		{
			se_click1.play();//se
			this.addChild(checker);checker.alpha=.6;
		}
		public function checkerOut():void
		{
			if(checker.parent !=null)
				this.removeChild(checker);
		}
	}
}