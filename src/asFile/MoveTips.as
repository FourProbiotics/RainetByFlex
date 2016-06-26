package asFile
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.text.ReturnKeyLabel;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	
	import spark.components.Label;

	/**
	 * 棋盘外的可移动操作界面
	 */
	
	public class MoveTips extends UIComponent
	{
		//棋盘模式
		public var kind:String;
		public var tipMode:String="box";
		public var gamestart:Boolean=false;
		//tips载体元件
		public var tip:Tip=new Tip();
		//tc数组
		public var tc:Array=new Array();
		//对手信息
		public var EnemyName:String;
		public var EnemyWin:int;
		public var EnemyLose:int;
		//文本框
		private var tipTitle:Label;
		private var tipBody:Label;
		private var tcMessage:Label;
		private var EnemyMsg:Label;
		//字体格式
		private var myformat1:TextFormat;
		private var myformat2:TextFormat;
		//tc
		private var checker:Terminal;
		private var boost:Terminal;
		private var wall:Terminal;
		private var nFound:Terminal;
		//对方tc使用情况
		private var dChecker:int=1;
		private var dLine:int=1;
		private var dWall:int=1;
		private var dChange:int=1;
		//计时器及颜色
		private var second:Number=60;
		private var color:int;
		private var t:Timer=new Timer(1000);
		//信息栏缩放标记
		public var out_s1:Boolean=true;
		private var out_s2:Boolean=true;
		private var out_s3:Boolean=true;
		private var out_s4:Boolean=true;
		
		//绑定字体
		[Embed(source="/fonts/font16.ttf",embedAsCFF="false", fontName="myFont1")] 
		public var bar1:String;
		[Embed(source="/fonts/US.ttf",embedAsCFF="false", fontName="myFontUS")] 
		public var bar2:String;

		
		public function MoveTips(mode:String)
		{
			super();
			if(mode=="1")
			{
				kind="G";
				color=0xffff00;
			}
			else
			{
				kind="B";
				color=0x0000ff;
			}
			
			myformat1 = new TextFormat();
			myformat1.font = "myFontUS";
			myformat1.bold=true;
			
			myformat2 = new TextFormat();
			myformat2.font = "myFont1";
			myformat2.bold=true;
			
			checker=new Terminal("check/"+kind+"viruschecker.png");
			boost=new Terminal("check/"+kind+"lineboost.png");
			wall=new Terminal("check/"+kind+"firewall.png");
			nFound=new Terminal("check/"+kind+"notfound.png");
			tc.push(checker,boost,wall,nFound);
			//提示标题
			tipTitle=new Label();
			tipTitle.setStyle("textFormat",myformat1);
			tipTitle.setStyle("color",color);
			tipTitle.setStyle("fontSize","16"); 
			tipTitle.text = "tips:";
			tipTitle.x = -215; tipTitle.y = 35;
			//提示标签
			tipBody=new Label();
			tipBody.setStyle("textFormat",myformat2);
			tipBody.setStyle("color",color);
			tipBody.setStyle("fontSize",16);
			tipBody.text = "请布置阵型";
			tipBody.x = -215;tipBody.y = 60;
			//tc信息
			tcMessage=new Label();
			tcMessage.setStyle("textFormat",myformat1);
			tcMessage.setStyle("color",color);
			tcMessage.setStyle("fontSize","12"); 
			tcMessage.text = "";
			tcMessage.x=30;tcMessage.y=-150;
			//对手信息
			EnemyMsg=new Label();
			EnemyMsg.setStyle("textFormat",myformat1);
			EnemyMsg.setStyle("color",0xffffff-color);
			EnemyMsg.setStyle("fontSize","12"); 
			EnemyMsg.text = "";
			EnemyMsg.x=25;EnemyMsg.y=-190;
			//设置label大小
			tipTitle.width = 120;
			tipTitle.height = 30;
			tipBody.width = 120;
			tipBody.height = 128;
			tcMessage.width = 120;
			tcMessage.height = 128;
			EnemyMsg.width = 128;
			EnemyMsg.height = 60;
			checker.y=boost.y=wall.y=nFound.y=-80;
			checker.visible=boost.visible=wall.visible=nFound.visible=false;
			//加载子元件
			this.addChild(tip);
			this.addChild(tipTitle);
			this.addChild(tipBody);
			this.addChild(EnemyMsg);
			this.addChild(tcMessage);
			this.addChild(wall);
			this.addChild(nFound);
			this.addChild(boost);
			this.addChild(checker);
			this.alpha=0;
			this.mouseEnabled=false;
			//添加侦听
			tip.circle.addEventListener(MouseEvent.MOUSE_DOWN,onDrag);
			tip.s1.addEventListener(MouseEvent.CLICK,onSDown);
			tip.s2.addEventListener(MouseEvent.CLICK,onSDown);
			tip.s3.addEventListener(MouseEvent.CLICK,onSDown);
			tip.s4.addEventListener(MouseEvent.CLICK,onSDown);
			tip.btn_bgm.addEventListener(MouseEvent.CLICK,volumeChange);
			tip.btn_talk.addEventListener(MouseEvent.CLICK,onTalk);
			tip.btn_refuse.addEventListener(MouseEvent.CLICK,onRefuse);
			tip.btn_exit.addEventListener(MouseEvent.CLICK,btnExit);
			SwitchOn(1);
			SwitchOn(2);
			SwitchOn(4);
		}
		
		//弹幕开关
		private function onRefuse(e:MouseEvent):void
		{
			FlexGlobals.topLevelApplication.acceptTalk=!(FlexGlobals.topLevelApplication.acceptTalk);
		}
		
		//收放信息栏侦听函数
		private function onSDown(e:MouseEvent):void
		{
			var target:Object=e.target;
			if(target==tip.s1)
			{
				SwitchOn(1);
			}
			else if(target==tip.s2)
			{
				SwitchOn(2);
			}
			else if(target==tip.s3)
			{
				SwitchOn(3);
			}
			else if(target==tip.s4)
			{
				SwitchOn(4);
			}
		}
		
		//发送弹幕信息
		private function onTalk(e:MouseEvent):void
		{
			FlexGlobals.topLevelApplication.showTalk();
		}
		
		//bgm音量调节
		private function volumeChange(e:MouseEvent):void
		{
			Lei_Net.bgm.bgmVolume();
		}
		
		//关闭按钮
		private function btnExit(e:MouseEvent):void
		{
			//参数:显示文本,标题,显示操作按钮
			Alert.yesLabel = "退出";  
			Alert.noLabel = "取消"; 
			Alert.show("确定要退出吗?", "退出", (Alert.YES | Alert.NO) , this, alertClick);
		}
		
		//alert事件实现函数
		private function alertClick(e:CloseEvent):void
		{
			//当点击退出时
			if (e.detail==Alert.YES)
			{
				//关闭前发送逃跑信息
				try{
					if(kind=="B")
						Lei_Net.ServerSend(0,0,0,0,"run away",8,2);
					else if(kind=="G")
						Lei_Net.ClientSend(0,0,0,0,"run away",8,2);
				}catch(e:Error)
				{
					trace("连接异常");
					//传递程序关闭事件
					var event:Event=new Event(Event.EXITING, false, true);
					FlexGlobals.topLevelApplication.sendExiting();
				}
			}
			else  
				;  
		}
		
		//控制缩放显示效果
		public function SwitchOn(num:int):void
		{
			switch(num)
			{
				case 1:
					tip.switchOn(tip.s1);
					out_s1=!out_s1;
					//游戏开始后才执行
					if(!gamestart) return;
					if(!out_s1)
					{
						TweenLite.to(checker,.4,{autoAlpha:0});
						TweenLite.to(boost,.4,{autoAlpha:0});
						TweenLite.to(wall,.4,{autoAlpha:0});
						TweenLite.to(nFound,.4,{autoAlpha:0});
						
						this.removeEventListener(MouseEvent.CLICK,FlexGlobals.topLevelApplication.tcMode);
					}else{
						wall.scaleX=wall.scaleY=.9;
						nFound.scaleX=nFound.scaleY=.9;
						boost.scaleX=boost.scaleY=.9;
						checker.scaleX=checker.scaleY=.9;
						TweenLite.to(checker,.4,{autoAlpha:(checker.paused)?.4:checker.nowAlpha,x:-190,y:-170.5});
						TweenLite.to(boost,.4,{autoAlpha:(boost.paused)?.4:boost.nowAlpha,x:-128,y:-170.5});
						TweenLite.to(wall,.4,{autoAlpha:(wall.paused)?.4:wall.nowAlpha,x:-190,y:-108.5});
						TweenLite.to(nFound,.4,{autoAlpha:(nFound.paused)?.4:nFound.nowAlpha,x:-128,y:-108.5});
						
						this.addEventListener(MouseEvent.CLICK,FlexGlobals.topLevelApplication.tcMode);
					}
					break;
				case 2:
					tip.switchOn(tip.s2);
					out_s2=!out_s2;
					//游戏开始后才执行
					if(!gamestart) return;
					if(!out_s2)
					{
						TweenLite.to(EnemyMsg,.4,{alpha:0});
						TweenLite.to(tcMessage,.4,{alpha:0});
					}else{
						TweenLite.to(EnemyMsg,.4,{alpha:1});
						TweenLite.to(tcMessage,.4,{alpha:1});
					}
					break;
				case 3:
					out_s3=!out_s3;
					tip.switchOn(tip.s3);
					if(!out_s3)
					{
						TweenLite.to(tipTitle,.4,{alpha:0});
						TweenLite.to(tipBody,.4,{alpha:0});
					}else{
						TweenLite.to(tipTitle,.4,{alpha:1});
						TweenLite.to(tipBody,.4,{alpha:1});
					}
					break;
				case 4:
					out_s4=!out_s4;
					tip.switchOn(tip.s4);
					break;
			}
		}
		
		public function setTerminal(checker:int=-1,line:int=-1,wall:int=-1,change:int=-1):void
		{
			if(checker !=-1)
				dChecker=checker;
			if(line !=-1)
				dLine=line;
			if(wall !=-1)
				dWall=wall;
			if(change !=-1)
				dChange=change;
		}
		
		public function showTerminal():void
		{
			listMode();
			resume();
			for(var i:int=0;i<4;i++)
				tc[i].alpha=0;
			if(out_s1)
			{
				wall.scaleX=wall.scaleY=.9;
				nFound.scaleX=nFound.scaleY=.9;
				boost.scaleX=boost.scaleY=.9;
				checker.scaleX=checker.scaleY=.9;
				TweenLite.to(checker,.4,{delay:.8,autoAlpha:checker.nowAlpha,x:-190,y:-170.5});
				TweenLite.to(boost,.4,{delay:.8,autoAlpha:boost.nowAlpha,x:-128,y:-170.5});
				TweenLite.to(wall,.4,{delay:.8,autoAlpha:wall.nowAlpha,x:-190,y:-108.5});
				TweenLite.to(nFound,.4,{delay:.8,autoAlpha:nFound.nowAlpha,x:-128,y:-108.5});
			}
		}
		
		//设置提示信息
		public function setTip(title:String,body:String):void
		{
			tipTitle.text=title;
			tipBody.text=body;
		}
		
		public function resume():void
		{
			for(var i:int=0;i<4;i++)
			{
				if(tc[i].haveUsed==false)
					tc[i].resume();
				else
					tc[i].change();
			}
		}
		
		public function boxMode():void
		{
			tipTitle.alpha=0;
			tipBody.alpha=0;
			EnemyMsg.alpha=0;
			tcMessage.alpha=0;
			tipMode="box";
			TweenLite.to(tipTitle,.4,{alpha:1});
			TweenLite.to(tipBody,.4,{alpha:1});
		}
		//开始tc阶段
		public function listMode():void
		{
			tipMode="list";
			
			//显示对手信息
			EnemyMsg.text="对手id： "+EnemyName+"\n胜率： \t"+EnemyWin.toString()+"胜  "+EnemyLose.toString()+"败";trace(EnemyMsg.text)
			tcMessage.text="敌方终端卡信息：\n"+"Virus Checker:"+dChecker.toString()+
				"\nLine Boost:"+dLine.toString()+"\nFire Wall:"+dWall.toString()+"\n404 Not Found:"+dChange.toString();
			resume();
		}
		//结束tc阶段
		public function l2bMode():void
		{
			tipMode="box";trace("l2bMode")
			checker.pause();
			boost.pause();
			wall.pause();
			nFound.pause();
		}
		public function pannelMode():void
		{
			tipMode="pannel";
			TweenLite.to(tipTitle,.4,{alpha:0});
			TweenLite.to(tipBody,.4,{alpha:0});
			TweenLite.to(EnemyMsg,.4,{alpha:0});
			TweenLite.to(tcMessage,.4,{alpha:0});
		}
		
		//设置时间
		public function setTime(t:int):void
		{
			if(t >10)
			{
				t--;
			}else if(t >0)
			{
				t--;
			}
		}
		
		private function onDrag(e:MouseEvent):void
		{
			this.startDrag();
			tip.circle.removeEventListener(MouseEvent.MOUSE_DOWN,onDrag);
			tip.circle.addEventListener(MouseEvent.MOUSE_UP,disDrag);
		}
		
		private function disDrag(e:MouseEvent):void
		{
			this.stopDrag();
			tip.circle.addEventListener(MouseEvent.MOUSE_DOWN,onDrag);
			tip.circle.removeEventListener(MouseEvent.MOUSE_UP,disDrag);
		}
	}
}