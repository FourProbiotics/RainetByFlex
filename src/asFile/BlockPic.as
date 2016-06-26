package asFile
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.ui.Mouse;
	import flash.utils.Timer;
	
	import mx.controls.Image;
	import mx.core.UIComponent;
	
	
	
	
	public class BlockPic extends UIComponent
	{
		//判断动画是否结束
		public static var isFinished:Boolean=false;
		//图片组合
		private var image:TransImage;
		private var image2:Image=new Image();
		private var image3:Image=new Image();
		private var image4:Image=new Image();
		//字母
		private var wordA:TransImage;
		private var wordG:TransImage;
		private var wordM:TransImage;
		private var wordE:TransImage;
		private var wordS:TransImage;
		private var wordT:TransImage;
		private var wordR:TransImage;
		private var word_:TransImage;
		private var wordT2:TransImage;
		private var wordA2:TransImage;
		
		private var maskmode:Bitmap;
		private var blockArray:Array=new Array();
		private var enemyArray:Array=new Array();
		private var loader:Loader=new Loader();
		private var titleImage:TransImage;
		//Sound
		private var se_type1:Music=new Music("se/se03.mp3");
		private var se_type2:Music=new Music("se/se03.mp3");
		private var se_timeleap:Music=new Music("se/se05.mp3");
		private var se_noise:Music=new Music("se/se06.mp3");
		private var se_collision:Music=new Music("se/se04.mp3");
		private var se_move:Music=new Music("se/se07.mp3");
		private var se_move3:Music=new Music("se/se073.mp3");
		private var se_move5:Music=new Music("se/se075.mp3");
		private var se_rotate:Music=new Music("se/se09.mp3");
		
		private var ctrlTime:int=0;
		public var finalY:Number=0;
		
		
		public function BlockPic(bmpdata:BitmapData,mode:String="1")
		{
			super();
			image=new TransImage(bmpdata);
			image.x=image.getWidth()/2;trace(image.x,image.y)
			image.y=image.getHeight()/2;
			addImage(image2,"image/board1"+mode+".png");
			addImage(image4,"image/board2"+mode+".png");
			addImage(image3,"image/board3"+mode+".png");
			wordA=new TransImage("sys/a.png");
			wordG=new TransImage("sys/g.png");
			wordM=new TransImage("sys/m.png");
			wordE=new TransImage("sys/e.png");
			wordS=new TransImage("sys/s.png");
			wordT=new TransImage("sys/t.png");
			wordR=new TransImage("sys/r.png");
			word_=new TransImage("sys/_.png");
			wordT2=new TransImage("sys/t.png");
			wordA2=new TransImage("sys/a.png");
			
			for(var i:int=0;i<8;i++)
			{
				var tempblock:TransImage=new TransImage("image/block"+mode+".png");
				var tempenemy:TransImage=new TransImage("check/"+((mode=="2")?"G":"B")+"back.png");
				tempblock.setBackBitmapData3("check/"+((mode=="1")?"G":"B")+"back.png");
				tempblock.mouseEnabled=false;
				enemyArray.mouseEnabled=false;
				blockArray.push(tempblock);
				enemyArray.push(tempenemy);
			}
			
			loader.load(new URLRequest("image/board1"+mode+".png"));
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE,init);
			this.addChild(image);
		}
		//初始化
		private function init(e:Event):void
		{
			e.target.removeEventListener(Event.COMPLETE,init);
			var bitmap:Bitmap=Bitmap(loader.content);
			
			image.setBackBitmapData2(bitmap);
			image.rotateY(6,30);
			//绘制遮罩层
			var bmdTemp:BitmapData=new BitmapData(loader.content.width,1000);
			maskmode=new Bitmap(bmdTemp);
			
			rotateChange();
			
		}
		//旋转变换特效
		public function rotateChange():void
		{
			var t:Timer=new Timer(720,1);
			t.addEventListener(TimerEvent.TIMER,onRotateChange);
			t.start();
			//rotate sound
			se_rotate.play();
		}
		private function onRotateChange(e:TimerEvent):void
		{
			e.target.removeEventListener(TimerEvent.TIMER,onRotateChange);
			this.removeChild(image);
			//将图像向左上角移动，容器移向右下角
			image3.getChildAt(0).y =-image3.getChildAt(0).height/2;
			//image3.x +=500;//image3.getChildAt(0).height/2;
			image3.visible=false;
			//绑定遮罩
			image4.y=image2.height-image4.height;
			image4.mask=maskmode;
			maskmode.y =image3.height;

			//将图片添加到舞台
			this.addChild(image2);
			this.addChildAt(image3,0);
			this.addChildAt(image4,0);
			this.addChild(maskmode);
			
			myTimer(100,function(e:TimerEvent):void
			{
				var t:Timer=new Timer(20);
				t.addEventListener(TimerEvent.TIMER,moveChange);
				t.start();
			},1);
			//noise
			se_noise.play();
		}
		//平移及开始特效
		public function moveChange(e:TimerEvent):void
		{
			//平移
			if(image3&&image4.y-image2.y<image2.height-image3.height)
			{
				image2.y -=3;
				maskmode.y=image2.y+image3.height;
				image4.y +=5;

			}
			//展开
			else if(image3&&image3.rotationX >-180)
			{
				if(image3.visible==false)
				{
					//显示image3
					image3.y=image2.y+image2.height-image3.height/2;
					image3.visible=true;
					//取消遮罩
					image4.mask=null;
					this.removeChild(maskmode);
				}
				image3.rotationX -= 5;
				image2.y =image3.y-image2.height+(image3.height/2)*Math.cos(image3.rotationX*Math.PI/180);
				image4.y =image3.y-(image3.height/2)*Math.cos(image3.rotationX*Math.PI/180);
				image2.z=(image3.height/2)*Math.sin(image3.rotationX*Math.PI/180);
				image4.z=-(image3.height/2)*Math.sin(image3.rotationX*Math.PI/180);
			}
			//聚合
			else if(image2.y+image2.height < int(image4.y))
			{
				
				ctrlTime++;
				if(ctrlTime<20)
					return;
				else if(ctrlTime==20)
				{
					//collision
					se_noise.stop();
					se_collision.play();
				}
				
				if(image3.parent)
				{
					blockArray[1].x=70;
					blockArray[2].x=70*2;
					blockArray[3].x=70*3;
					blockArray[4].x=335;
					blockArray[5].x=70+335;
					blockArray[6].x=70*2+335;
					blockArray[7].x=70*3+335;
					
					for(var i:int=0;i<8;i++)
					{
						blockArray[i].y=image3.y;
						blockArray[i].x+=blockArray[i].width/2;
						this.addChildAt(blockArray[i],this.numChildren);
					}
					this.removeChild(image3);	
				}
				image2.y +=(image4.y-image2.y-image2.height>18)?12:(image4.y-image2.y-image2.height)/3*2;
				image4.y -=(image4.y-image2.y-image2.height>6)?6:(image4.y-image2.y-image2.height);
			}
			//显示文字
			else if(image3)
			{
				if(ctrlTime>0);
				else if(ctrlTime==0)
				{
					this.addChild(wordG);
					this.addChild(word_);
					wordG.x=.5*wordG.width;
					wordG.y=image3.y;
					word_.y=image3.y;
					word_.x=1.5*word_.width;
					//type sound
					se_type1.play();
				}
				else if(ctrlTime>-5);
				else if(ctrlTime==-5)
				{
					this.addChild(wordA);
					wordA.y=image3.y;
					wordA.x=1.5*wordA.width;
					word_.x +=word_.width;
					//type sound
					se_type2.play();
				}
				else if(ctrlTime>-10);
				else if(ctrlTime==-10)
				{
					this.addChild(wordM);
					wordM.y=image3.y;
					wordM.x=wordM.width*2.5;
					word_.x +=word_.width;
					//type sound
					se_type1.play();
				}
				else if(ctrlTime>-15);
				else if(ctrlTime==-15)
				{
					this.addChild(wordE);
					wordE.y=image3.y;
					wordE.x=wordE.width*3.5;
					word_.x +=55+word_.width;
					//type sound
					se_type1.play();
				}
				else if(ctrlTime>-20);
				else if(ctrlTime==-20)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-35);
				else if(ctrlTime==-35)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-50);
				else if(ctrlTime==-50)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-65);
				else if(ctrlTime==-65)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-80);
				else if(ctrlTime==-80)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-85);
				else if(ctrlTime==-85)
				{
					word_.visible= !(word_.visible);
					this.addChild(wordS);
					wordS.y=image3.y;
					wordS.x=wordS.width*4.5+55;
					word_.x +=word_.width;
					//type sound
					se_type1.play();
				}
				else if(ctrlTime>-90);
				else if(ctrlTime==-90)
				{
					this.addChild(wordT);
					wordT.y=image3.y;
					wordT.x=wordT.width*5.5+55;
					word_.x +=word_.width;
					//type sound
					se_type2.play();
				}
				else if(ctrlTime>-95);
				else if(ctrlTime==-95)
				{
					this.addChild(wordA2);
					wordA2.y=image3.y;
					wordA2.x=wordA2.width*6.5+55;
					word_.x +=word_.width;
					//type sound
					se_type1.play();
				}
				else if(ctrlTime>-100);
				else if(ctrlTime==-100)
				{
					this.addChild(wordR);
					wordR.y=image3.y;
					this.removeChild(wordG);
					wordA.x -=wordR.width;
					wordM.x -=wordR.width;
					wordE.x -=wordR.width;
					wordS.x -=wordR.width+55;
					wordT.x -=wordR.width;
					wordA2.x -=wordR.width;
					wordR.x =wordR.width*6.5+55;
					//type sound
					se_type2.play();
				}
				else if(ctrlTime>-105);
				else if(ctrlTime==-105)
				{
					this.addChild(wordT2);
					wordT2.y=image3.y;
					this.removeChild(wordA);
					wordR.x -=wordR.width;
					wordM.x -=wordR.width;
					wordE.x -=wordR.width;
					wordS.x -=wordR.width;
					wordT.x -=55+wordR.width;
					wordA2.x -=wordR.width;
					wordT2.x =wordT2.width*6.5+55;
					//type sound
					se_type1.play();
				}
				else if(ctrlTime>-110);
				else if(ctrlTime==-110)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-125);
				else if(ctrlTime==-125)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-140);
				else if(ctrlTime==-140)
				{
					word_.visible= !(word_.visible);
				}
				else if(ctrlTime>-150);
				else if(ctrlTime==-150)
				{
					TweenLite.to(blockArray[0],.70,{x:image4.x+64,y:image4.y+273});
					TweenLite.to(blockArray[1],.70,{x:image4.x+64+70,y:image4.y+273,delay:.1});
					TweenLite.to(blockArray[7],.70,{x:image4.x+64+70*7,y:image4.y+273,delay:.2});
					blockArray[0].rotateX(9,20);
					blockArray[1].rotateX(9,20);
					blockArray[7].rotateX(9,20);
					
					TweenLite.to(wordM,.70,{x:image4.x+64,y:image4.y+273});
					TweenLite.to(wordE,.70,{x:image4.x+64+70,y:image4.y+273,delay:.1});
					wordM.rotateX(9,20);
					wordE.rotateX(9,20);
					//move sound
					se_move3.play();
				}
				else if(ctrlTime>-160)
				{
					blockArray[4].x -=60/10;
					blockArray[5].x -=60/10;
					blockArray[6].x -=60/10;
					wordA2.x -=60/10;
					wordR.x -=60/10;
					wordT2.x -=60/10;
				}
				else if(ctrlTime >-240);
				else if(ctrlTime==-240)
				{
					TweenLite.to(blockArray[2],.70,{x:image4.x+64+70*2,y:image4.y+273});
					TweenLite.to(blockArray[3],.70,{x:image4.x+64+70*3,y:image4.y+273-70,delay:.1});
					TweenLite.to(blockArray[4],.70,{x:image4.x+64+70*4,y:image4.y+273-70,delay:.2});
					TweenLite.to(blockArray[5],.70,{x:image4.x+64+70*5,y:image4.y+273,delay:.3});
					TweenLite.to(blockArray[6],.70,{x:image4.x+64+70*6,y:image4.y+273,delay:.4});
					blockArray[2].rotateX(9,20);
					blockArray[3].rotateX(9,20);
					blockArray[4].rotateX(9,20);
					blockArray[5].rotateX(9,20);
					blockArray[6].rotateX(9,20);
					
					TweenLite.to(wordS,.70,{x:image4.x+64+70*2,y:image4.y+273});
					TweenLite.to(wordT,.70,{x:image4.x+64+70*3,y:image4.y+273-70,delay:.1});
					TweenLite.to(wordA2,.70,{x:image4.x+64+70*4,y:image4.y+273-70,delay:.2});
					TweenLite.to(wordR,.70,{x:image4.x+64+70*5,y:image4.y+273,delay:.3});
					TweenLite.to(wordT2,.70,{x:image4.x+64+70*6,y:image4.y+273,delay:.4});
					wordS.rotateX(9,20);
					wordT.rotateX(9,20);
					wordA2.rotateX(9,20);
					wordR.rotateX(9,20);
					wordT2.rotateX(9,20);
					//move sound
					se_move5.play();
				}
				else if(ctrlTime >-310);
				else if(ctrlTime ==-310)
				{
					for(var i:int=0;i<8;i++)
					{
						this.addChild(enemyArray[i]);
						enemyArray[i].x=64+70*i;
						enemyArray[i].alpha=0;
					}
					TweenLite.to(enemyArray[0],.70,{y:image2.y+198,alpha:1});
					TweenLite.to(enemyArray[1],.70,{y:image2.y+198,alpha:1});
					TweenLite.to(enemyArray[2],.70,{y:image2.y+198,alpha:1});
					TweenLite.to(enemyArray[3],.70,{y:image2.y+268,alpha:1});
					TweenLite.to(enemyArray[4],.70,{y:image2.y+268,alpha:1});
					TweenLite.to(enemyArray[5],.70,{y:image2.y+198,alpha:1});
					TweenLite.to(enemyArray[6],.70,{y:image2.y+198,alpha:1});
					TweenLite.to(enemyArray[7],.70,{y:image2.y+198,alpha:1});
					//move sound
					se_move5.play();
					
				}else if(ctrlTime >-380);
				else if(ctrlTime ==-380)
				{
					Mouse.show();
					isFinished=true;
					finalY=image2.y;
				}

				ctrlTime--;
			}
			else
				e.target.removeEventListener(TimerEvent.TIMER,moveChange);
		}
		
		
		/*
		 *可用于类外的静态工具函数 
		 *
		 **/
		
		//计时函数
		public static function myTimer(time:int,func:Function,count:int=0):Timer
		{
			var t:Timer=new Timer(time,count);
			t.addEventListener(TimerEvent.TIMER,func);
			if(count !=0)
			{
				t.addEventListener(TimerEvent.TIMER_COMPLETE,function(e:TimerEvent):void
				{
					t.stop();
					t.removeEventListener(TimerEvent.TIMER,func);
				},false,0,true);
			}
			t.start();
			return t;
		}
		//计时函数改版
		public static function freeTimer(time:int,func:Function,count:int=0):Timer
		{
			var t:Timer=new Timer(time,count);
			t.addEventListener(TimerEvent.TIMER,function(e:TimerEvent):void
			{
				func();
			},false,0,true);
			t.start();
			return t;
		}
		//加载图片
		public static function addImage(image:UIComponent,imageName:String):void
		{
			var l:Loader=new Loader();
			l.load(new URLRequest(imageName));
			l.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void
			{
				var bitmap:Bitmap=Bitmap(l.content);
				image.width=bitmap.width;
				image.height=bitmap.height;
				image.addChild(bitmap);
			});
		}
		
		//加载图片2
		public static function addImage2(image:Bitmap,imageName:String):void
		{
			var l:Loader=new Loader();
			l.load(new URLRequest(imageName));
			l.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void
			{
				var bitmap:Bitmap=Bitmap(l.content);
				image.width=bitmap.width;
				image.height=bitmap.height;
				image=bitmap;
			});
		}
		
		//id编码
		public static function EncodeID(Ip:String):String
		{
			var ID:String="";
			var ip:String=Ip;
			var startInt:int=0;
			var intArray:Array=new Array();
			
			for(var i:int=0;i<ip.length;i++)
			{
				if(ip.charCodeAt(i)==46)
				{
					var num:int=int(ip.slice(startInt,i));
					if(num>=94)
					{
						//ID +=String.fromCharCode(int(num/94)+34);trace(int(num/94)+34);
						intArray.push(int(num/94));
						num -=int(num/94)*94;
					}else{
						//ID +=String.fromCharCode(34);
						intArray.push(0);
					}
					//ID +=String.fromCharCode(int(num)+34);
					intArray.push(int(num));
					startInt=i+1;
				}else if(i==ip.length-1)
				{
					var num:int=int(ip.slice(startInt,i+1));
					if(num>=94)
					{
						//ID +=String.fromCharCode(int(num/94)+34);
						intArray.push(int(num/94));
						num -=int(num/94)*94;
					}else{
						//ID +=String.fromCharCode(34);
						intArray.push(0);
					}
					//ID +=String.fromCharCode(int(num)+34);
					intArray.push(int(num));
				}
				
			}
			
			for(var i:int =0;i<20;i++)
			{
				if(i<8)
				{
					ID +=String.fromCharCode(Math.ceil(Math.random()*intArray[i])+34);
				}else if(i<12)
				{
					ID +=String.fromCharCode(Math.ceil(Math.random()*94)+34);
				}else{
					ID +=String.fromCharCode(intArray[19-i]+34-ID.charCodeAt(19-i)+34);
				}
			}
			return ID;
		}
		
		//通信编码
		public static function EncodeMsg(msg:String):String
		{
			var ID:String="";
			var message:String=msg;
			var intArray:Array=new Array();
			
			for(var i:int=0;i<message.length;i++)
			{
				var num:int=message.charCodeAt(i);
				if(num>=94)
				{
					intArray.push(int(num/94));
					num -=int(num/94)*94;
				}else{
					intArray.push(0);
				}
				intArray.push(int(num));
				
			}
			
			for(var i:int =0;i<intArray.length*2+5;i++)
			{
				if(i<msg.length)
				{
					ID +=String.fromCharCode(Math.ceil(Math.random()*intArray[i])+34);
				}else if(i<msg.length+5)
				{
					ID +=String.fromCharCode(Math.ceil(Math.random()*94)+34);
				}else{
					ID +=String.fromCharCode(intArray[intArray.length*2+4-i]+34-ID.charCodeAt(intArray.length*2+4-i)+34);
				}
			}
			return ID;
		}
		
		
		
		//id解码
		public static function DecodeID(id:String):String
		{
			var trueCode:String="";
			var outArray:Array=new Array();
			
			for(var i:int=0;i<8;i++)
			{
				outArray.push(id.charCodeAt(i)+id.charCodeAt(19-i)-34);//id.charCodeAt(i)+id.charCodeAt(19-i)-34
				//trace(outArray[i]);
			}
			
			for(var i:int=0;i<8;i++)
			{
				if(i%2 !=0)
				{
					trueCode +=String(outArray[i]-34);
					if(i !=7)
						trueCode +='.';
				}else{
					outArray[i+1] +=(outArray[i]-34)*94;
				}
			}
			
			return trueCode;
		}
		
		//通信解码
		public static function DecodeMsg(id:String):String
		{
			var trueCode:String="";
			var outArray:Array=new Array();
			
			for(var i:int=0;i<(id.length-5)/2;i++)
			{
				outArray.push(id.charCodeAt(i)+id.charCodeAt(id.length-1-i)-34);
			}
			
			for(var i:int=0;i<outArray.length;i++)
			{
				if(i%2 !=0)
				{
					trueCode +=String.fromCharCode(outArray[i]-34);
				}else{
					outArray[i+1] +=(outArray[i]-34)*94;
				}
			}
			
			return trueCode;
		}

		
		//加密信息处理函数
		public static function handleMsg(code:String):Array
		{
			var temp:String=DecodeMsg(code);
			var msg:Array=new Array();
			var ip:String="";
			for(var i:int=0;i<temp.length;i++)
			{
				/*
				 *		前4个和后两个字符作为整型数字加入数组，中间字符累加后加入数组 
				*/
				if(i<4||i>temp.length-3)
					msg.push(temp.charCodeAt(i));
				else if(i==temp.length-3)
				{
					ip +=temp.charAt(i);
					msg.push(ip);
				}
				else
					ip +=temp.charAt(i);
			}
			return msg;
		}
		
		//转换ascii码为字符
		public static function asc(...parameters):String
		{
			var ascCode:String="";
			for(var i:int=0;i<parameters.length;i++)
			{
				if(parameters[i] is Number)
					ascCode +=String.fromCharCode(parameters[i]);
				else if(parameters[i] is String)
				{
					for(var j:int=0;j<parameters[i].length;j++)
					{
						ascCode +=parameters[i].charAt(j);
					}
				}
			}
			return EncodeMsg(ascCode);
		}
	}
}