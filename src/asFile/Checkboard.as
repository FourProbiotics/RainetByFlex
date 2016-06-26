package asFile
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	
	public class Checkboard extends UIComponent
	{
		public var message:Array=null;
		public var moveTurn:Boolean=false;
		public var myTurn:Boolean=false;
		public var myTerminal:Array=[1,1,1,1];
		public var yourTerminal:Array=[1,1,1,1];
		public var chessMap:Array=new Array();
		public var myTeam:Array=new Array();
		public var yourTeam:Array=new Array();
		public var Mode:String;
		private var capturedMap:Array=new Array();
		public var entryMap:Array=new Array();
		private var wall:Array=new Array(null,
			new Array(),new Array(),new Array(),new Array(),
			new Array(),new Array(),new Array(),new Array());
		private var tempLoc:Array=null;
		private var l:Loader;
		private var focusChess:Chess=null;
		//双方棋子离场计数
		private var getv:int=0;
		private var getl:int=0;
		private var sendv:int=0;
		private var sendl:int=0;
		private var enterl:int=0;
		private var enterv:int=0;
		private var enteredl:int=0;
		private var enteredv:int=0;
		
		public var tcMode:int=0;
		private var tcMessage:Array=new Array();
		private var wallChess:FireWall;
		private var dwallChess:FireWall;
		private var exchange:ExChoice;
		private var tips:MoveTips;
		//预加载之后会用到的音频
		private var se_click1:Music=new Music("se/se01.mp3");
		private var se_click2:Music=new Music("se/se02.mp3");
		private var se_cmove:Music=new Music("se/se10.mp3");
		
		public function Checkboard(mode:String,movetips:MoveTips)
		{
			super();
			if(mode=="1")
				Mode="G";
			else
				Mode="B";
			wallChess=new FireWall(Mode,true);
			dwallChess=new FireWall(Mode=="G"?"B":"G",true);
			tips=movetips;
			
			for(var i:int=0;i<10;i++)
				chessMap.push(new Array());
			for(var i:int=0;i<2;i++)
				capturedMap.push(new Array());
			for(var i:int=0;i<4;i++)
			{
				var temp:EntrySpace=new EntrySpace();
				temp.addEventListener(MouseEvent.CLICK,moveAct);
				if(i==0||i==1)
					temp.rotation=90;
				entryMap.push(temp);
			}
			for(var i:int=1;i<9;i++)
			{
				for(var j:int=1;j<9;j++)
				{
					if(!((i==4||i==5)&&(j==1||j==8)))
					{
						var tempWall:FireWall=new FireWall(Mode);
						wall[i][j]=tempWall;
						tempWall.x=getX(i,j);tempWall.y=getY(i,j);
						tempWall.visible=false;
					}
				}
			}
			//加载棋盘图
			l=new Loader();
			l.load(new URLRequest("image/checkboard"+mode+".png"));
			l.contentLoaderInfo.addEventListener(Event.COMPLETE,addImage);
		}
		private function addImage(e:Event):void
		{
			var bitmap:Bitmap=Bitmap(l.content);
			this.width=bitmap.width;
			this.height=bitmap.height;
			this.addChild(bitmap);
			if(Mode=="B")
			{
				addChess(1,1,"G");
				addChess(2,1,"G");
				addChess(3,1,"G");
				addChess(4,2,"G");
				addChess(5,2,"G");
				addChess(6,1,"G");
				addChess(7,1,"G");
				addChess(8,1,"G");
				
			}else if(Mode=="G")
			{
				addChess(1,1,"B");
				addChess(2,1,"B");
				addChess(3,1,"B");
				addChess(4,2,"B");
				addChess(5,2,"B");
				addChess(6,1,"B");
				addChess(7,1,"B");
				addChess(8,1,"B");
			}
			addChess(1,8,Mode);
			addChess(2,8,Mode);
			addChess(3,8,Mode);
			addChess(4,7,Mode);
			addChess(5,7,Mode);
			addChess(6,8,Mode);
			addChess(7,8,Mode);
			addChess(8,8,Mode);
			
			this.addEventListener(MouseEvent.MOUSE_OVER,onFocus);
			this.addEventListener(MouseEvent.MOUSE_MOVE,moveBoard);
		}
		
		//添加棋子
		public function addChess(x:int,y:int,type:String):void
		{
			var chess:Chess=new Chess(type);
			chess.x=getX(x,y);
			chess.y=getY(x,y);
			this.addChild(chess);
			
			if(y>=0&&y<=9&&chessMap[x][y]==null)
			{
				chessMap[x][y]=chess;
				if(y==8||y==7||y==1||y==2)
				{
					if(type==Mode)
						myTeam.push(chess);
					else
						yourTeam.push(chess);
				}
			}
			else if(y==-1)
				capturedMap[0][x-1]=chess;
			else if(y==10)
				capturedMap[1][x-1]=chess;
		}
		
		//显示tc使用提示
		public function showTC(type:int,x:int,y:int):void
		{trace("TC卡发动！\n代号：",type,"\n坐标：",x,y)
			var str:String="";
			if(type==1)
			{
				str="Virus Checker 发动！";
			}else if(type==2)
			{
				str="Line Boost 发动！";
			}else if(type==3)
			{
				str="Fire Wall 发动！";
			}else{
				str="404 Not Found 发动！";
			}
			tips.setTip("Tip:","");
			//滚动提示
			FlexGlobals.topLevelApplication.showTipBar(str);
			//提示音频
			Music.playVoice(type+1);
		}
		//移动棋子
		public function moveChess(x:int,y:int,x2:int,y2:int):void
		{
			if(chessMap[x][y] == null)
				return;
			
			TweenLite.to(chessMap[x][y],.4,{x:getX(x2,y2),y:getY(x2,y2)});
			chessMap[x2][y2]=chessMap[x][y];
			chessMap[x][y]=null;trace("moveChess has done!")
		}
		
		//被捕获
		public function capture(x:int,y:int,isLink:int):void
		{
			var target:Chess=chessMap[x][y];
			//当被捕获的是自己的棋子时
			if(target !=null&&target.getType()==Mode)
			{
				target.disfocus2();
				target.checkerOut();
				if(target.speedUp)
				{
					target.speeddown();
					tips.tc[1].resume();
				}
				
				for(var i:int=0;i<8;i++)
				{
					if(capturedMap[0][i]==null)
					{
						target.setLink(isLink);
						TweenLite.to(target,.7,{x:getX(i+1,-1),y:getY(i+1,-1)});
						capturedMap[0][i]=target;
						chessMap[x][y]=null;
						target=null;
						break;
					}
				}
			}
			//捕获对手棋子时
			else if(chessMap[x][y] !=null)
			{
				target.disfocus2();
				target.checkerOut();
				target.speeddown();
				
				for(var i:int=0;i<8;i++)
				{
					if(capturedMap[1][i]==null)
					{
						target.setLink(isLink);
						TweenLite.to(target,.7,{x:getX(i+1,10),y:getY(i+1,10)});
						capturedMap[1][i]=target;
						target=null;
						break;
					}
				}
			}
		}

		//敌方进入服务器
		public function entered(x:int,y:int,isLink:int):void
		{
			chessMap[x][y].disfocus2();
			chessMap[x][y].isLink=isLink;
			chessMap[x][y].speeddown();
			moveChess(x,y,enteredl+enteredv+1,9);
		}
		//我方进入服务器
		public function enter(x:int,y:int,isLink:int):void
		{
			chessMap[x][y].disfocus2();
			chessMap[x][y].speeddown();
			moveChess(x,y,enterl+enterv+1,0);
		}
		
		//判断胜负
		//返回值1表示玩家胜利，2为玩家失败，0为未分胜负
		public function Winner():int
		{
			getv=0;getl=0;sendv=0;sendl=0;enterl=0;enteredl=0;enterv=0;enteredv=0;
			
			for(var i:int=0;i<capturedMap[0].length;i++)
			{
				if(capturedMap[0][i].isLink==1)
					sendl++;
				else
					sendv++;
			}
			
			for(var i:int=0;i<capturedMap[1].length;i++)
			{
				if(capturedMap[1][i].isLink==1)
					getl++;
				else
					getv++;
			}
			
			for(var i:int=1;i<=8;i++)
			{
				if(chessMap[i][0] !=null&&chessMap[i][0].isLink==1)
					enterl++;
				else if(chessMap[i][0] !=null&&chessMap[i][0].isLink==2)
					enterv++;
				if(chessMap[i][9] !=null&&chessMap[i][9].isLink==1)
					enteredl++;
				else if(chessMap[i][9] !=null&&chessMap[i][9].isLink==2)
					enteredv++;
			}
			if(enterl+getl==4||sendv+enteredv==4)
				return 1;
			else if(enteredl+sendl==4||getv+enterv==4)
				return 2;
			else
				return 0;
		}
		
		//使用终端卡
		//此函数为主mxml文件向 Checkboard。as 类文件传递终端消息的通道
		//其中mode=1表示病毒查杀，2表示超速回线，3表示防火墙，4表示查找失败
		public function tcAction(mode:int):void
		{
			tcMode=mode;
			if(tcMode==1)
			{
				this.addEventListener(MouseEvent.CLICK,checkerCommand);
				this.addEventListener(MouseEvent.MOUSE_OVER,checkerOver);
				this.addEventListener(MouseEvent.MOUSE_OUT,checkerOut);
				tips.setTip("Tip:","选择对方一枚棋子确认");
			}
			else if(tcMode==2)
			{
				this.addEventListener(MouseEvent.CLICK,lineBoostCommad);
				this.addEventListener(MouseEvent.MOUSE_OVER,lineBoostOver);
				this.addEventListener(MouseEvent.MOUSE_OUT,lineBoostOut);
				tips.setTip("Tip:","选择我方一枚棋子一回合可移动二次");
			}
			else if(tcMode==3)
			{
				for(var i:int=1;i<9;i++)
				{
					for(var j:int=1;j<9;j++)
					{
						if(wall[i][j] !=null&&chessMap[i][j]==null)
						{
							TweenLite.to(wall[i][j],.3,{autoAlpha:.1});
							this.addChild(wall[i][j]);
						}
					}
				}
				this.addEventListener(MouseEvent.CLICK,fireWallCommand);
				tips.setTip("Tip:","选择没有棋子放置的一处区域设置防火墙");
			}
			else if(tcMode==4)
			{
				this.addEventListener(MouseEvent.CLICK,notFoundCommand);
				this.addEventListener(MouseEvent.MOUSE_OVER,notFoundOver);
				this.addEventListener(MouseEvent.MOUSE_OUT,notFoundOut);
				tips.setTip("Tip:","选择我方两枚棋子交换/不交换");
			}

		}
		
		//棋盘移动
		private function moveBoard(evt:MouseEvent):void
		{
			if(this.y>0&&this.y+this.height<this.parent.height)
			{
				if(this.x!=this.parent.height/2-this.height/2)
					TweenLite.to(this,.4,{y:this.parent.height/2-this.height/2});
				return;
			}
			
			if(mouseY<this.parent.height/5&&this.y !=0)
				TweenLite.to(this,.7,{y:0});
			else if(mouseY>this.parent.height*4/5&&this.y !=this.parent.height-this.height)
				TweenLite.to(this,.7,{y:this.parent.height-this.height});
		}
	
		/*
		*
		*		棋子获取焦点				
		*		此函数为进行我方回合的主要函数
		*		
		*
		*							*/
		
		
		
		private function onFocus(evt:MouseEvent):void
		{
			var x:int=0;var y:int=0;
			
			if(!(evt.target is Chess)||moveTurn==false||myTurn==false||(tcMode !=0&&tcMode !=-1))
				return;
			for(var i:int=1;i<9;i++)
			{
				for(var j:int=1;j<9;j++)
				{
					if(chessMap[i][j] is Chess)
						chessMap[i][j].disfocus2();
					if(chessMap[i][j] ==evt.target)
					{
						x=i;y=j;
					}
				}
			}
			//隐藏所有移动按钮
			for(var k:int=0;k<4;k++)
				entryMap[k].visible=false;
			
			if(y>0&&y<9)
				evt.target.onfocus2();
			else
				return;
			if(x !=0&&chessMap[x][y].getType() !=this.Mode)
				return;
			
			//将棋子设为目标
			focusChess=chessMap[x][y];trace("focusChess: ",x,y)
			if(((x !=4&&x !=5)||(y !=1&&y !=8)))
			{
					//当不在服务器入口处时
					if(x>1&&(chessMap[x-1][y] ==null||(chessMap[x-1][y] is Chess&&chessMap[x-1][y].getType() !=this.Mode)))
					{
						this.addChild(entryMap[0]);
						entryMap[0].x=getX(x-1,y);
						entryMap[0].y=getY(x-1,y);
						entryMap[0].visible=true;
					}
					if(x<8&&(chessMap[x+1][y] ==null||(chessMap[x+1][y] is Chess&&chessMap[x+1][y].getType() !=this.Mode)))
					{
						this.addChild(entryMap[1]);
						entryMap[1].x=getX(x+1,y);
						entryMap[1].y=getY(x+1,y);
						entryMap[1].visible=true;
					}
					if(y>1&&(chessMap[x][y-1] ==null||(chessMap[x][y-1] is Chess&&chessMap[x][y-1].getType() !=this.Mode)))
					{
						this.addChild(entryMap[2]);
						entryMap[2].x=getX(x,y-1);
						entryMap[2].y=getY(x,y-1);
						entryMap[2].visible=true;
					}
					if(y<8&&(chessMap[x][y+1] ==null||(chessMap[x][y+1] is Chess&&chessMap[x][y+1].getType() !=this.Mode)))
					{
						this.addChild(entryMap[3]);
						entryMap[3].x=getX(x,y+1);
						entryMap[3].y=getY(x,y+1);
						entryMap[3].visible=true;
					}
			}else if((x ==4||x ==5)&&(y==1||y==8))
			{
				//在己方或对方服务器入口前时
				if(chessMap[x-1][y] ==null||(chessMap[x-1][y] is Chess&&chessMap[x-1][y].getType() !=this.Mode))
				{
					this.addChild(entryMap[0]);
					entryMap[0].x=getX(x-1,y);
					entryMap[0].y=getY(x-1,y);
					entryMap[0].visible=true;
				}
				if(chessMap[x+1][y] ==null||(chessMap[x+1][y] is Chess&&chessMap[x+1][y].getType() !=this.Mode))
				{
					this.addChild(entryMap[1]);
					entryMap[1].x=getX(x+1,y);
					entryMap[1].y=getY(x+1,y);
					entryMap[1].visible=true;
				}
				if(chessMap[x][y-1] ==null||(chessMap[x][y-1] is Chess&&chessMap[x][y-1].getType() !=this.Mode))
				{
					if(y==1)
					{
						this.addChild(entryMap[2]);
						entryMap[2].x=getX(6,0);
						entryMap[2].y=getY(6,0);
						entryMap[2].visible=true;
					}else{
						this.addChild(entryMap[2]);
						entryMap[2].x=getX(x,y-1);
						entryMap[2].y=getY(x,y-1);
						entryMap[2].visible=true;
					}
				}
				if(y == 1&&(chessMap[x][y+1] ==null||(chessMap[x][y+1] is Chess&&chessMap[x][y+1].getType() !=this.Mode)))
				{
					this.addChild(entryMap[3]);
					entryMap[3].x=getX(x,y+1);
					entryMap[3].y=getY(x,y+1);
					entryMap[3].visible=true;
				}
			}
		}
		
		//棋子收到移动指令时处理函数
		private function moveAct(e:MouseEvent):void
		{
			//move sound
			se_cmove.play();
			
			var x:int=returnX(e.currentTarget.x);
			var y:int=returnY(e.currentTarget.y);
			var x1:int=returnX(focusChess.x);
			var y1:int=returnY(focusChess.y);
			//记录临时移动
			tempLoc=[x1,y1];
			
			/*		发送消息		*/
			
			//攻击行为
			if(chessMap[x][y] !=null)
			{
				if(x1<1||x1>8||y1<0||y1>9)
				{
					tempLoc=null;
					return;
				}
				message=[x1,y1,x,y,7,1];
				//进行了攻击行为后无法走第二步
				moveTurn=false;
			}
			//进入对方server
			else if(y==0)
			{
				//解除lineboost状态（如果有的话）
				if(focusChess.speedUp)
				{
					disLineBoost(x1,y1);
					//设置tc按钮
					tips.tc[1].haveUsed=false;
				}
				message=[x1,y1,focusChess.isLink,int(Math.random()*10),7,3];
				moveChess(x1,y1,enterl+enterv+1,0);
				moveTurn=false;
			}
			else
			{
				message=[x1,y1,x,y,7,0];
				moveChess(x1,y1,x,y);
			}
			//隐藏所有移动按钮重新布局
			for(var i:int=0;i<4;i++)
				entryMap[i].visible=false;
			//判断是否存在加速标志
			if(focusChess.speedUp&&y !=0&&moveTurn==true)
			{
				//加载右键撤销动作侦听
				tcMode=5;
				//延时添加回退侦听
				BlockPic.myTimer(500,function(e:Event):void{
					FlexGlobals.topLevelApplication.addEventListener(MouseEvent.RIGHT_CLICK,FlexGlobals.topLevelApplication.cancelLineBoost);
				},1);
				//设置移动回合结束，无法移动其他棋子
				moveTurn=false;
				if(x>1&&(chessMap[x-1][y] ==null||(chessMap[x-1][y] is Chess&&chessMap[x-1][y].getType() !=this.Mode)))
				{
					this.addChild(entryMap[0]);
					entryMap[0].x=getX(x-1,y);
					entryMap[0].y=getY(x-1,y);
					BlockPic.myTimer(400,function():void{
						entryMap[0].visible=true;
					},1);
				}
				if(x<8&&(chessMap[x+1][y] ==null||(chessMap[x+1][y] is Chess&&chessMap[x+1][y].getType() !=this.Mode)))
				{
					this.addChild(entryMap[1]);
					entryMap[1].x=getX(x+1,y);
					entryMap[1].y=getY(x+1,y);
					BlockPic.myTimer(400,function():void{
						entryMap[1].visible=true;
					},1);
				}
				if(y>0&&(chessMap[x][y-1] ==null||(chessMap[x][y-1] is Chess&&chessMap[x][y-1].getType() !=this.Mode)))
				{
					if(y==1&&(x==4||x==5))
					{
						this.addChild(entryMap[2]);
						entryMap[2].x=getX(6,0);
						entryMap[2].y=getY(6,0);
						BlockPic.myTimer(400,function():void{
							entryMap[2].visible=true;
						},1);
					}else if(y !=1)
					{
						this.addChild(entryMap[2]);
						entryMap[2].x=getX(x,y-1);
						entryMap[2].y=getY(x,y-1);
						BlockPic.myTimer(400,function():void{
							entryMap[2].visible=true;
						},1);
					}
				}
				if(y<8&&(chessMap[x][y+1] ==null||(chessMap[x][y+1] is Chess&&chessMap[x][y+1].getType() !=this.Mode)))
				{
					this.addChild(entryMap[3]);
					entryMap[3].x=getX(x,y+1);
					entryMap[3].y=getY(x,y+1);
					BlockPic.myTimer(400,function():void{
						entryMap[3].visible=true;
					},1);
				}
				return;
			}
			//结束回合
			myTurn=false;
			//消除步移临时记录
			tempLoc=null;
			
			moveTurn=false;
		}
		
		/*
		 *			tc阶段的处理函数
		*
		*/
		
		//tc探查器
		private function checkerCommand(e:MouseEvent):void
		{
			var x:int=returnX(e.target.x);
			var y:int=returnY(e.target.y);
			if(!(e.target is Chess)||e.target.getType()==Mode||y<1||y>8)
				return;
			//设置tc按钮
			tips.tc[0].used();
			tips.tc[0].canUse=false;
			tcMode=-2;
			
			this.removeEventListener(MouseEvent.CLICK,checkerCommand);
			this.removeEventListener(MouseEvent.MOUSE_OVER,checkerOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT,checkerOut);
			
			message=[x,y,int(Math.random()*15),int(Math.random()*7),5,0];
		}
		
		//回应探查器
		public function getIdentity(x:int,y:int):int
		{
			var chess:Chess=chessMap[9-x][9-y];
			chess.checkerOver();
			return chess.isLink;
		}
		//鼠标悬浮效果
		private function checkerOver(e:MouseEvent):void
		{
			var y:int=returnY(e.target.y);
			if(!(e.target is Chess)||e.target.getType()==Mode||y<0||y>8)
				return;
			e.target.checkerOver();
		}
		private function checkerOut(e:MouseEvent):void
		{
			var y:int=returnY(e.target.y);
			if(!(e.target is Chess)||e.target.getType()==Mode||y<0||y>8)
				return;
			e.target.checkerOut();
		}
		//强行停止病毒探查
		public function stopcheckerCommand():void
		{
			if(tcMode==2||tcMode==3||tcMode==4)
				return;
			this.removeEventListener(MouseEvent.CLICK,checkerCommand);
			this.removeEventListener(MouseEvent.MOUSE_OVER,checkerOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT,checkerOut);
			for(var i:int=0;i<8;i++)
			{
				yourTeam[i].checkerOut();
			}
			tcMode=-1;
		}
		//tc超速回线
		private function lineBoostCommad(e:MouseEvent):void
		{
			var y:int=returnY(e.target.y);
			if(!(e.target is Chess)||e.target.getType() !=Mode||y<1||y>8)
				return;
			this.removeEventListener(MouseEvent.CLICK,lineBoostCommad);
			this.removeEventListener(MouseEvent.MOUSE_OVER,lineBoostOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT,lineBoostOut);
			e.target.lineOut();
			e.target.speedup();
			message=[returnX(e.target.x),returnY(e.target.y),
				int(Math.random()*12),int(Math.random()*12),3,0];
			showTC(2,message[0],message[1]);
			tcMode=-2;
			//设置tc按钮
			tips.tc[1].used();
			//使用终端卡后回合结束
			moveTurn=false;
			myTurn=false;
		}
		//强行停止超速回线
		public function stopLineCommand():void
		{
			if(tcMode==1||tcMode==3||tcMode==4)
				return;
			this.removeEventListener(MouseEvent.CLICK,lineBoostCommad);
			this.removeEventListener(MouseEvent.MOUSE_OVER,lineBoostOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT,lineBoostOut);
			for(var i:int=0;i<8;i++)
			{
				myTeam[i].lineOut();
			}
			tcMode=-1;
		}
		//强制停止装备lineboost棋子的移动
		public function stopLineCommand2():void
		{
			if(tcMode!=5)
				return;
			//隐藏所有移动按钮
			for(var k:int=0;k<4;k++)
				entryMap[k].visible=false;

			//移回原位
			if(tempLoc !=null&&focusChess)
			{
				//当棋子没有移动到位时返回重新执行
				if(returnX(focusChess.x)==0||returnY(focusChess.y)==-1)
				{
					stopLineCommand2();
					return;
				}
				FlexGlobals.topLevelApplication.CSSend(returnX(focusChess.x),returnY(focusChess.y),tempLoc[0],tempLoc[1],"",7,0);
				moveChess(returnX(focusChess.x),returnY(focusChess.y),tempLoc[0],tempLoc[1]);trace("倒退：",returnX(focusChess.x),returnY(focusChess.y),tempLoc[0],tempLoc[1])
			}
			//恢复tc卡使用权
			tips.resume();
			tips.addEventListener(MouseEvent.CLICK,FlexGlobals.topLevelApplication.tcMode);
			//回到移动阶段
			moveTurn=true;
			tcMode=-1;
		}
		//敌方加速
		public function useLineBoost(x:int,y:int):void
		{
			if(chessMap[x][y]&&chessMap[x][y] is Chess)
				chessMap[x][y].speedup();
		}
		//我方减速
		public function disLineBoost(x:int,y:int):void
		{
			chessMap[x][y].speeddown();
		}
		//回收line boost卡
		public function disLineBoost2():void
		{
			for(var i:int=0;i<8;i++)
			{
				if(myTeam[i].speedUp==true)
				{
					myTeam[i].speeddown();
					message=[returnX(myTeam[i].x),returnY(myTeam[i].y),int(Math.random()*9),int(Math.random()*9),3,1];
					//使用终端卡后回合结束
					tcMode=0;
					moveTurn=false;
					myTurn=false;
					return;
				}
			}
		}
		private function lineBoostOver(e:MouseEvent):void
		{
			var y:int=returnY(e.target.y);
			if(!(e.target is Chess)||e.target.getType() !=Mode||y<0||y>8)
				return;
			e.target.lineOver();
		}
		private function lineBoostOut(e:MouseEvent):void
		{
			var y:int=returnY(e.target.y);
			if(!(e.target is Chess)||e.target.getType() !=Mode||y<0||y>8)
				return;
			e.target.lineOut();
		}
		
		//tc防火墙
		private function fireWallCommand(e:MouseEvent):void
		{
			//目标不是防火墙或目标是已存在的（对方的）防火墙时返回
			if(!(e.target is FireWall)||e.target.inMap==true)
				return;
			
			var x:int;var y:int;
			x=returnX(e.target.x);y=returnY(e.target.y);
			wall[x][y].choosed=true;
			for(var i:int=1;i<=8;i++)
			{
				for(var j:int=1;j<=8;j++)
				{
					if(wall[i][j] !=null)
						TweenLite.to(wall[i][j],.3,{autoAlpha:0});
				}
			}
			chessMap[x][y]=wallChess;
			wallChess.x=e.target.x;
			wallChess.y=e.target.y;
			this.addChild(wallChess);
			//发送完成信息
			message=new Array();
			message.push(0,0,x,y,4,0);
			showTC(3,x,y);
			this.removeEventListener(MouseEvent.CLICK,fireWallCommand);
			tcMode=-2;
			//设置tc按钮
			tips.tc[2].used();
			//使用终端卡后回合结束
			moveTurn=false;
			myTurn=false;
		}
		
		//强行停止防火墙
		public function stopWallCommand():void
		{
			if(tcMode==1||tcMode==2||tcMode==4)
				return;
			this.removeEventListener(MouseEvent.CLICK,fireWallCommand);
			for(var i:int=1;i<9;i++)
			{
				for(var j:int=1;j<9;j++)
				{
					if(wall[i][j] !=null)
					{
						wall[i][j].resume();
						wall[i][j].visible=false;
					}
				}
			}
				tcMode=-1;
		}
		
		//敌方发动防火墙
		public function findFireWall(x1:int,y1:int):void
		{
			this.addChild(dwallChess);
			dwallChess.x=getX(x1,y1);dwallChess.y=getY(x1,y1);
			chessMap[x1][y1]=dwallChess;
		}
		//回收防火墙
		public function cancelFireWall(mode:String):void
		{
			for(var i:int=1;i<9;i++)
			{
				for(var j:int=2;j<8;j++)
				{
					if(chessMap[i][j] is FireWall&&chessMap[i][j].Mode==mode)
					{
						this.removeChild(chessMap[i][j]);
						chessMap[i][j]=null;
						//找到目标后判断执行的是否为tc命令
						if(mode==Mode)
						{
							message=[int(Math.random()*9),int(Math.random()*11),int(Math.random()*9),int(Math.random()*9),4,1];
							//使用终端卡后回合结束
							tcMode=0;
							moveTurn=false;
							myTurn=false;
						}
						//退出循环
						return;
					}
				}
			}
		}
		
		
		//404 not found
		private function notFoundCommand(e:MouseEvent):void
		{
			if(!(e.target is Chess)||e.target.getType() !=Mode||returnY((e.target as Chess).y)<=0||returnY((e.target as Chess).y)>=9)//处于捕获状态的棋子无法交换
				return;
			var x:int;var y:int;
			x=returnX(e.target.x);y=returnY(e.target.y);
			if(tcMessage.length==0)
			{
				tcMessage=[x,y];
				e.target.notFoundOut();
				e.target.setNotFound();
			}else if(tcMessage.length==2&&e.target==chessMap[tcMessage[0]][tcMessage[1]])
			{
				tcMessage=new Array();
				e.target.cancelNotFound();
			}else if(tcMessage.length==2)
			{
				tcMessage.push(x,y);
				/*
				 * 进行判断 是否交换位置	*/
				chessMap[x][y].notFoundOut();
				chessMap[x][y].setNotFound();

				this.removeEventListener(MouseEvent.CLICK,notFoundCommand);
				this.removeEventListener(MouseEvent.MOUSE_OVER,notFoundOver);
				this.removeEventListener(MouseEvent.MOUSE_OUT,notFoundOut);
				chooseEX();
			}
		}
		
		//出现交换选项
		private function chooseEX():void
		{
			exchange=new ExChoice();
			this.addChild(exchange);
			exchange.x=this.width/2;
			exchange.y=this.height/2;
			exchange.appear();
			exchange.addEventListener(MouseEvent.CLICK,pathDecided);
			this.addChild(exchange);
		}
		
		//收到404指令
		public function notFoundMessage(x1:int,y1:int,x2:int,y2:int,change:int):void
		{
			var chess1:Chess;
			var chess2:Chess;
			var result:int=change%2;
			var right:int=0;
			var spChange:int=0;
			if(x1<x2)
			{
				chess1=chessMap[x1][y1];
				chess2=chessMap[x2][y2];
			}else{
				chess1=chessMap[x2][y2];
				chess2=chessMap[x1][y1];
				right=1;
			}
			//消除checker标记
			chess1.checkerOut();
			chess2.checkerOut();
			//找出lineboost标记并消去
			if(chessMap[x1][y1].speedUp)
			{
				disLineBoost(x1,y1);
				spChange=1;
			}
			else if(chessMap[x2][y2].speedUp)
			{
				disLineBoost(x2,y2);
				spChange=2;
			}
			chess1.setNotFound();
			chess2.setNotFound();
			chess1.parent.addChild(chess1);
			chess2.parent.addChild(chess2);
			var dx:Number=chess2.x-chess1.x;var dy:Number=chess2.y-chess1.y;
			var centreX:Number=chess1.x+dx/2;var centreY:Number=chess1.y+dy/2;
			var r:Number=Math.sqrt(Math.pow(dx,2)/4+Math.pow(dy,2)/4);
			var deR:Number=r/40;
			BlockPic.myTimer(20,function(e:TimerEvent):void{
				if(r>0)
				{
					r -=deR;
					var angle1:Number=Math.atan2(chess1.y-centreY,chess1.x-centreX);
					var angle2:Number=Math.atan2(chess2.y-centreY,chess2.x-centreX);
					chess1.x=centreX+Math.cos(angle1+Math.PI/36)*r;
					chess1.y=centreY+Math.sin(angle1+Math.PI/36)*r;
					chess2.x=centreX+Math.cos(angle2+Math.PI/36)*r;
					chess2.y=centreY+Math.sin(angle2+Math.PI/36)*r;
				}else{
					//chess1chess2回到原状
					if(right==1)
					{
						var temp:Chess=chess1;
						chess1=chess2;
						chess2=temp;
					}
					if(result==1)
					{
						//重新放上lineboost标记
						if(spChange==1)
							useLineBoost(x2,y2);
						else if(spChange==2)
							useLineBoost(x1,y1);
					}else{
						//重新放上lineboost标记
						if(spChange==1)
							useLineBoost(x1,y1);
						else if(spChange==2)
							useLineBoost(x2,y2);
					}
					//显示位置回归
					TweenLite.to(chess1,.4,{x:getX(x1,y1),y:getY(x1,y1)});
					TweenLite.to(chess2,.4,{x:getX(x2,y2),y:getY(x2,y2)});
					//翻面
					chess1.backY();
					chess2.backY();
					e.target.stop();
				}
			});
		}
		
		//not found鼠标事件处理函数
		private function pathDecided(e:MouseEvent):void
		{
			var choose:int=exchange.btnPress(e.target);
			if(choose==0)
				return;
			//取消checker标记
			trace("tcMessage: "+tcMessage)
			chessMap[tcMessage[0]][tcMessage[1]].checkerOut();
			chessMap[tcMessage[2]][tcMessage[3]].checkerOut();
			//处理移动tips上的信息
			tips.tc[3].canUse=false;
			tips.tc[3].used();
			//传递交换信息
			if(choose==1)
			{
				message=[tcMessage[0],tcMessage[1],tcMessage[2],tcMessage[3],6,1];
				var temp:Chess=chessMap[tcMessage[0]][tcMessage[1]];
				chessMap[tcMessage[0]][tcMessage[1]]=chessMap[tcMessage[2]][tcMessage[3]];
				chessMap[tcMessage[2]][tcMessage[3]]=temp;
				trace("tcMessage12: ",(chessMap[tcMessage[0]][tcMessage[1]]==null),"tcMessage34: ",(chessMap[tcMessage[2]][tcMessage[3]]==null))
			}
			else
				message=[tcMessage[0],tcMessage[1],tcMessage[2],tcMessage[3],6,0];
			//显示提示
			showTC(4,tcMessage[0],tcMessage[1]);
			tcMode=-2;
			//使用终端卡后回合结束
			moveTurn=false;
			myTurn=false;
			exchange.disappear();
			exchange.removeEventListener(MouseEvent.CLICK,pathDecided);
			transPosition(choose);
		}
		//404 not Found交换位置动画
		private function transPosition(change:int):void
		{
			var chess1:Chess;var chess2:Chess;
			var result:int=change%2;
			var right:int=0;
			var spChange:int=0;
			var x1:int=tcMessage[0];var x2:int=tcMessage[2];
			var y1:int=tcMessage[1];var y2:int=tcMessage[3];
			tcMessage=new Array();
			//找出lineboost标记并消去
			if(chessMap[x1][y1].speedUp)
			{
				disLineBoost(x1,y1);
				spChange=1;
			}
			else if(chessMap[x2][y2].speedUp)
			{
				disLineBoost(x2,y2);
				spChange=2;
			}
			//判断两枚棋子的左右顺序
			if(x1<x2)
			{
				chess1=chessMap[x1][y1];
				chess2=chessMap[x2][y2];
			}else{
				chess1=chessMap[x2][y2];
				chess2=chessMap[x1][y1];
				right=1;
			}
			//交换动画
			chess1.parent.addChild(chess1);
			chess2.parent.addChild(chess2);
			var dx:Number=chess2.x-chess1.x;var dy:Number=chess2.y-chess1.y;
			var centreX:Number=chess1.x+dx/2;var centreY:Number=chess1.y+dy/2;
			var r:Number=Math.sqrt(Math.pow(dx,2)/4+Math.pow(dy,2)/4);
			var deR:Number=r/40;
			BlockPic.myTimer(20,function(e:TimerEvent):void{
				if(r>0)
				{
					r -=deR;
					var angle1:Number=Math.atan2(chess1.y-centreY,chess1.x-centreX);
					var angle2:Number=Math.atan2(chess2.y-centreY,chess2.x-centreX);
					chess1.x=centreX+Math.cos(angle1+Math.PI/36)*r;
					chess1.y=centreY+Math.sin(angle1+Math.PI/36)*r;
					chess2.x=centreX+Math.cos(angle2+Math.PI/36)*r;
					chess2.y=centreY+Math.sin(angle2+Math.PI/36)*r;
				}else{
					//chess1chess2回到原状
					if(right==1)
					{
						var temp:Chess=chess1;
						chess1=chess2;
						chess2=temp;
					}
					if(result==1)
					{
						//重新放上lineboost标记
						if(spChange==1)
							useLineBoost(x2,y2);
						else if(spChange==2)
							useLineBoost(x1,y1);
					}else{
						//重新放上lineboost标记
						if(spChange==1)
							useLineBoost(x1,y1);
						else if(spChange==2)
							useLineBoost(x2,y2);
					}
					//显示位置回归
					TweenLite.to(chess1,.4,{x:getX(x1,y1),y:getY(x1,y1)});
					TweenLite.to(chess2,.4,{x:getX(x2,y2),y:getY(x2,y2)});
					//翻面、消除notfound标记
					chess1.cancelNotFound();
					chess2.cancelNotFound();
					//停止计时器
					e.target.stop();
				}
			});
		}
		
		private function notFoundOver(e:MouseEvent):void
		{
			if(!(e.target is Chess)||e.target.getType() !=Mode||(tcMessage.length==2&&e.target==chessMap[tcMessage[0]][tcMessage[1]])
				||(tcMessage.length==4&&(e.target==chessMap[tcMessage[0]][tcMessage[1]]||e.target==chessMap[tcMessage[2]][tcMessage[3]])))
				return;
			e.target.notFoundOver();
		}
		
		private function notFoundOut(e:MouseEvent):void
		{
			if(!(e.target is Chess)||e.target.getType() !=Mode||(tcMessage.length==2&&e.target==chessMap[tcMessage[0]][tcMessage[1]])
				||(tcMessage.length==4&&(e.target==chessMap[tcMessage[0]][tcMessage[1]]||e.target==chessMap[tcMessage[2]][tcMessage[3]])))
				return;
			e.target.notFoundOut();
		}
		
		//强行停止404终端卡
		public function stopFoundCommand():void
		{
			if(tcMode==1||tcMode==2||tcMode==3)
				return;
			if(exchange&&exchange.parent)
				exchange.parent.removeChild(exchange);
			this.removeEventListener(MouseEvent.CLICK,notFoundCommand);
			this.removeEventListener(MouseEvent.MOUSE_OVER,notFoundOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT,notFoundOut);
			tcMessage=new Array();
			for(var i:int=0;i<8;i++)
			{
				myTeam[i].notFoundOut();
				//如果处于notfound状态，翻面
				myTeam[i].cancelNotFound();
			}
			tcMode=-1;
		}
		
		//坐标转换
		public static function getX(x:int,y:int):Number
		{
			var result:Number=0;
			if(y>0&&y<9)
				result=64+70*(x-1);
			else if(y==0&&x<3)
				result=71.5+80*(x-1);
			else if(y==0&&x<5)
				result=467+79*(x-3);
			else if(y==0)
				result=242+53.5*(x-5);
			else if(y==9&&x<3)
				result=71.5+80*(x-1);
			else if(y==9&&x<5)
				result=467+78*(x-3);
			else if(y==9)
				result=242+53.5*(x-5);
			else if(y==-1&&x<5)
				result=36+70*(x-1);
			else if(y==-1)
				result=371+70*(x-5);
			else if(y==10&&x<5)
				result=36+70*(x-1);
			else if(y==10)
				result=370.5+70*(x-5);
			return result;
			
		}
		public static function getY(x:int,y:int):Number
		{
			var result:Number=0;
			if(y>0&&y<9)
				result=198+70*(y-1);
			else if(y==0)
				result=118;
			else if(y==9)
				result=772;
			else if(y==-1)
				result=34.5;
			else if(y==10)
				result=851;
			return result;
		}
		public static function returnX(x:Number):int
		{
			for(var i:int=1;i<9;i++)
			{
				if(getX(i,1)==x||getX(i,0)==x)
					return i;
			}
			return 0;
		}
		public static function returnY(y:Number):int
		{
			for(var i:int=0;i<10;i++)
			{
				if(getY(1,i)==y)
					return i;
			}
			return -1;
		}
	}
}