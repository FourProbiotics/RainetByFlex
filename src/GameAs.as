// ActionScript file
import asFile.BlockPic;
import asFile.Chess;
import asFile.ChoiceStype;
import asFile.Terminal;
import asFile.TweenLite;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.events.TimerEvent;

private var Yprepared:Boolean=false;
private var Iprepared:Boolean=false;
private var vNum:int=0;
private var lNum:int=0;
private var styleRecord:Array=new Array(0,0,0,0,0,0,0,0);
private var cvirus:ChoiceStype;
private var clink:ChoiceStype;


private function prepareGame():void
{
	this.addElement(tips);
	tips.x=checkboard.x+checkboard.width+250;
	tips.y=checkboard.y+checkboard.height+100;
	TweenLite.to(tips,.4,{y:this.height-300,alpha:1});
	tips.boxMode();
	setChess();
}

//设置棋子排列
private function setChess():void
{
	cvirus=new ChoiceStype("check/"+checkboard.Mode+"virus.png");
	clink=new ChoiceStype("check/"+checkboard.Mode+"link.png");
	clink.alpha=cvirus.alpha=.5;
	cvirus.addEventListener(MouseEvent.CLICK,decideStlye);
	clink.addEventListener(MouseEvent.CLICK,decideStlye);
	for(var i:int=1;i<9;i++)
	{
		checkboard.chessMap[i][(i==4||i==5)?7:8].addEventListener(MouseEvent.ROLL_OVER,onSetChess);
	}
	//当设置完毕时开始游戏
	BlockPic.myTimer(300,listenPrepared);
}
private function onSetChess(e:MouseEvent):void
{
	//over sound
	se_click1.play();
	
	e.currentTarget.removeEventListener(MouseEvent.ROLL_OVER,onSetChess);
	e.currentTarget.addEventListener(MouseEvent.ROLL_OUT,disSetChess);
	e.currentTarget.parent.addChild(e.currentTarget);
	if(vNum<4)
	{
		e.currentTarget.addChild(cvirus);
		cvirus.y =-45;
		cvirus.x =40;
	}
	if(lNum<4)
	{
		e.currentTarget.addChild(clink);
		clink.y =-45;
		clink.x =-40;
	}
	if(Iprepared)
		e.currentTarget.removeEventListener(MouseEvent.ROLL_OUT,disSetChess);
}
private function disSetChess(e:MouseEvent):void
{
	if(clink.parent)
		clink.parent.removeChild(clink);
	if(cvirus.parent)
		cvirus.parent.removeChild(cvirus);
	e.currentTarget.removeEventListener(MouseEvent.ROLL_OUT,disSetChess);
	if(!Iprepared)
		e.currentTarget.addEventListener(MouseEvent.ROLL_OVER,onSetChess);
}

private function decideStlye(e:MouseEvent):void
{
	var tempchess:Chess=e.currentTarget.parent;
	if(clink.parent)
		clink.parent.removeChild(clink);
	if(cvirus.parent)
		cvirus.parent.removeChild(cvirus);
	
	if(e.currentTarget==clink)
	{
		tempchess.setLink(1);
	}else{
		tempchess.setLink(2);
	}
	
	for(var i:int=1;i<9;i++)
	{
		if(checkboard.chessMap[i][(i==4||i==5)?7:8]==tempchess)
		{styleRecord[i-1]=tempchess.isLink;break;}
	}
	lNum=vNum=0;
	for(var i:int=0;i<8;i++)
	{
		if(styleRecord[i]==1)
			lNum++;
		else if(styleRecord[i]==2)
			vNum++;
	}
}

private function listenPrepared(e:TimerEvent):void
{
	if(Yprepared)
	{
		tips.setTip("Tip:","对手已准备完成");
	}
	
	if(vNum==4&&lNum==4)
	{
		if(Iprepared==false)
		{
			cvirus.removeEventListener(MouseEvent.CLICK,decideStlye);
			clink.removeEventListener(MouseEvent.CLICK,decideStlye);
			if(clink.parent)
				clink.parent.removeChild(clink);
			if(cvirus.parent)
				cvirus.parent.removeChild(cvirus);
			
			//将布局信息发送给对方
			var myLink:Array=new Array();
			for(var i:int=0;i<checkboard.myTeam.length;i++)
				if((checkboard.myTeam[i] as Chess).isLink==1)
					myLink.push(i);
			CSSend(myLink[0],myLink[1],myLink[2],myLink[3],"",1,2);
			
			if(Mode=="1")
			{
				CSSend(int(Math.random()*10),int(Math.random()*10),
					int(Math.random()*10),int(Math.random()*10),"",0,1);
			}else{
				CSSend(int(Math.random()*10),13,
					int(Math.random()*10),7,"",0,1);
			}
			Iprepared=true;
			//战报记录自己的棋子布局
			var myteamId:Array=new Array();
			for(var i:int=0;i<checkboard.myTeam.length;i++)
				myteamId[i]=(checkboard.myTeam[i] as Chess).isLink;
			saveLog(myteamId.toString(),0);	
		}
		
		if(Yprepared)
		{
			//tips设置开始标记
			tips.gamestart=true;
			//bgm
			se_hack.stop();
			bgm.playBgm();
			//移除准备阶段侦听
			e.target.removeEventListener(TimerEvent.TIMER,listenPrepared);
			//开始心跳包计时
			//heartTimer.start();
			//游戏开始提示
			var gs:dualaccess=new dualaccess;
			gs.x=this.width/2;gs.y=this.height/2;
			this.addElement(gs);
			if(Mode=="2")
				BlockPic.myTimer(200,guessFinger,1);
		}else
			tips.setTip("Tip:","请等待对手");
	}
}

//随机决定先攻
private function guessFinger(e:TimerEvent):void
{
	//生成随机数决定先攻
	var num:Number=Math.random()*10;
	//判断先攻
	if(num<5)
	{
		//向对方发送先攻信息，即对方先攻
		CSSend(7,9,6,12,"",2,1);
		
	}else{
		//向对方发送后攻信息，即我放先攻
		CSSend(7,9,6,12,"",2,2);
		
		//展开tc面板
		tips.setTip("tips: ","我方先攻");
		if(!tips.out_s1)
			tips.SwitchOn(1);
		//初始化变量，准备开局
		checkboard.moveTurn=true;
		checkboard.myTurn=true;
		dateRcvd=0;
		lastDate=[];
		BlockPic.myTimer(250,listenEnd);
		tcTurn();
	}
}

/*
* 时刻监听棋盘并发送数据
*
*/
private function listenEnd(e:TimerEvent):void
{
	//判断胜负
	if(checkboard.message==null&&checkboard.Winner() !=0)
	{
		var larr:Array=new Array(); 
		for(var i:int=0;i<8;i++)
			if(checkboard.myTeam[i].isLink==1)
				larr.push(i);
		checkboard.message=[larr[0],larr[1],larr[2],larr[3],8,checkboard.Winner()-1];
	}
	if(checkboard.message !=null)
	{
		//进入移动阶段
		if(checkboard.message[4]==7)
		{
			//提示符收起
			tips.removeEventListener(MouseEvent.CLICK,tcMode);
				tips.l2bMode();
		}
			//决胜信息
		else if(checkboard.message[4]==8)
		{
			e.target.removeEventListener(TimerEvent.TIMER,listenEnd);
		}
		CSSend(checkboard.message[0],checkboard.message[1],checkboard.message[2],checkboard.message[3],
			"",checkboard.message[4],checkboard.message[5]);
		checkboard.message=null;
	}
	else if(checkboard.myTurn==false)
	{
		//将结束标记
		checkboard.moveTurn=false;
		checkboard.myTurn=false;
		dateRcvd=0;
		for(var i:int=0;i<4;i++)
			checkboard.entryMap[i].visible=false;
		//lineboost回退
		checkboard.stopLineCommand2();
		//停止终端卡功能，复原终端卡
		checkboard.stopLineCommand();
		checkboard.stopWallCommand();
		checkboard.stopFoundCommand();
		checkboard.stopcheckerCommand();
		checkboard.tcMode=0;
		//发送结束回合的信息
		BlockPic.myTimer(50,function(e:TimerEvent):void{
			CSSend(0,0,
				0,0,"",2,3);
		},1);
		//提示符收起
		this.removeEventListener(MouseEvent.RIGHT_CLICK,cancelTerminal);
		tips.l2bMode();
		e.target.removeEventListener(TimerEvent.TIMER,listenEnd);
	}
}

/*
* 
*用于处理收到信息的函数
*/

private var tc:Terminal//用于指向正在处理的终端卡
private function moveChess(x1:int,y1:int,x2:int,y2:int):void
{
	checkboard.moveChess(x1,y1,x2,y2);
}

private function capture(x1:int,y1:int,isLink:int):void
{
	checkboard.capture(x1,y1,isLink);
}

//使用tc的函数
private function tcTurn():void
{
	tips.showTerminal();
	this.addEventListener(MouseEvent.RIGHT_CLICK,cancelTerminal);
	BlockPic.myTimer(800,function(e:TimerEvent):void
	{
		tips.addEventListener(MouseEvent.CLICK,tcMode);
	},1);
}

//tc模式
public function tcMode(e:MouseEvent):void
{
	//非tc获得事件时退出
	if(!(e.target is Terminal))
		return;
	//tc无法再使用时退出
	tc=Terminal(e.target);
	if((tc==tips.tc[0]||tc==tips.tc[3])&&tc.haveUsed==true)
		return;
	
	//取消棋子的选中状态和可移动模式
	for(var i:int=1;i<9;i++)
	{
		for(var j:int=1;j<9;j++)
		{
			if(checkboard.chessMap[i][j] is Chess)
				checkboard.chessMap[i][j].disfocus2();
		}
	}
	for(var k:int=0;k<4;k++)
		checkboard.entryMap[k].visible=false;
	
	//获得选中的tc信息并让其他tc暂停
	var type:int=0;
	for(var i:int=0;i<4;i++)
	{
		if(tips.tc[i]==tc)
			type=i;
		else
			tips.tc[i].pause();
	}
	
	//根据不同的tc执行不同的代码
	if(type==0&&tc.haveUsed==false)
	{
		checkboard.tcAction(1);
		//tc.canUse=false;tc.used();
		this.addEventListener(MouseEvent.RIGHT_CLICK,cancelTerminal);
	}
	else if(type==1&&tc.haveUsed==false)
	{
		checkboard.tcAction(2);
		this.addEventListener(MouseEvent.RIGHT_CLICK,cancelTerminal);
	}
	else if(type==1)
	{
		checkboard.disLineBoost2();tc.resume();
	}
	else if(type==2&&tc.haveUsed==false)
	{
		checkboard.tcAction(3);
		this.addEventListener(MouseEvent.RIGHT_CLICK,cancelTerminal);
	}
	else if(type==2)
	{
		checkboard.cancelFireWall(checkboard.Mode);tc.resume();
	}
	else if(type==3&&tc.haveUsed==false)
	{
		checkboard.tcAction(4);
		this.addEventListener(MouseEvent.RIGHT_CLICK,cancelTerminal);
	}
	//移除tc侦听器并等待恢复
	tips.removeEventListener(MouseEvent.CLICK,tcMode);
	BlockPic.myTimer(250,listenTerminal);
}

//关闭tc模式
public function cancelTerminal(e:MouseEvent):void
{trace("tcMode:",checkboard.tcMode)
	if(checkboard.tcMode==0||checkboard.tcMode==-1||checkboard.tcMode==-2
		||checkboard.tcMode==-3||checkboard.tcMode==-4||checkboard.tcMode==5)
		return;
	tips.addEventListener(MouseEvent.CLICK,tcMode);
	checkboard.stopLineCommand();
	checkboard.stopWallCommand();
	checkboard.stopFoundCommand();
	checkboard.stopcheckerCommand();
	checkboard.tcMode=-1;
	//还原tc
	tips.resume();
	if(tc is Terminal)
		tc.resume();
}
//lineboost回退
public function cancelLineBoost(e:MouseEvent):void
{
	if(checkboard.tcMode !=5)
		return;
	this.removeEventListener(MouseEvent.RIGHT_CLICK,cancelLineBoost);
	checkboard.stopLineCommand2();
}
//判断tc阶段结束
private function listenTerminal(e:TimerEvent):void
{
	if(checkboard.tcMode !=0&&checkboard.tcMode !=-2)
		return;
	e.target.removeEventListener(TimerEvent.TIMER,listenTerminal);
	tips.l2bMode();
}

//手动设置终端卡的使用状态
public function setTerminal(i:int,used:Boolean):void
{
	if(used==true)
		tips.tc[i].used();
	else
		tips.tc[i].resume();
}