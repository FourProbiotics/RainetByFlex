import adobe.utils.ProductManager;

import asFile.BlockPic;
import asFile.Checkboard;
import asFile.Chess;
import asFile.MoveTips;
import asFile.Music;
import asFile.TipTitle;
import asFile.TransImage;
import asFile.TweenLite;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.errors.IOError;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.IOErrorEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.events.ServerSocketConnectEvent;
import flash.events.TimerEvent;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.Matrix;
import flash.net.ServerSocket;
import flash.net.Socket;
import flash.system.Capabilities;
import flash.utils.ByteArray;
import flash.utils.Timer;

import mx.core.FlexGlobals;
import mx.core.UIComponent;

import spark.components.Label;
import spark.components.WindowedApplication;

private var serverHost:String="";
private var Mode:String="";
private var bp:BlockPic;
private var checkboard:Checkboard;
private var talkBoard:Input=new Input;
private var tips:MoveTips;
private var winnum:int;
private var losenum:int;
private var EnemyMsg:Array=[];
public var acceptTalk:Boolean=true;
//提示横幅
private var tipbar:TipTitle=new TipTitle();
//标记结束
private var finished:Boolean=false;
//预加载图片资源
private var victory:TransImage=new TransImage("image/victory.png");
private var redback:TransImage=new TransImage("image/redback.png");
//原始的时间对象
private var preDate:Date=new Date();
//最后发送的数据
private var lastDate:Array=[];
//当回合接收到的数据数
private var dateRcvd:int=0;
//未收到结束标记时重传的计时器
private var reSendTimer:Timer;
//心跳接收参数
private var startReply:int=-1;


private function gameStart(mode:String):void
{
	//先断开udp广播侦听
	udpHandler.close();
	//清空上一局游戏的日志
	stream.open(logfile, FileMode.WRITE );
	stream.writeUTFBytes("");
	stream.close();
	//初始化游戏
	Mode=mode;
	//添加重发监听函数
	reSendTimer=new Timer(2000);
	reSendTimer.addEventListener(TimerEvent.TIMER,function(e:TimerEvent):void{
		
		if(startReply==-1)
		{
			if(lastDate.length>0)
				CSSend2(lastDate[lastDate.length-1]);
		}else{
			reSendTimer.reset();
			for(var i:int=startReply;i<lastDate.length-1;i++)
			{
				if(lastDate[i] != null)
				{
					BlockPic.myTimer(100*(i-startReply),function(e:TimerEvent):void{
						if(lastDate[i] !=null)
							CSSend2(lastDate[i]);
					},1);
				}
			}
			startReply=-1;
		}
	});
	
	tips=new MoveTips(Mode);
	checkboard=new Checkboard(Mode,tips);
	talkBoard=new Input;
	talkBoard.visible=false;
	//用于解决textfield无法输入中文的bug
	talkBoard.inputText.addEventListener(FocusEvent.FOCUS_IN, textFocusIn);
	//无效提示横幅的鼠标事件
	tipbar.mouseChildren=false;
	tipbar.mouseEnabled=false;
	//截图
	var bit:BitmapData=new BitmapData(login.width,login.height,true,0);
	//bit.draw(this,new Matrix(1,0,0,1,-login.x,-login.y));
	bit.draw(login);
	bp=new BlockPic(bit,Mode);
	bp.x=login.x;trace("login: ",login.x,login.y)
	bp.y=login.y;
	//移除全部组件
	this.removeAllElements();
	BlockPic.myTimer(200,onMoved);
	this.addElementAt(bp,0);
	//读取文件
	stream.open(userfile, FileMode.READ);
	//读文件
	var temp:String=stream.readUTFBytes(stream.bytesAvailable);
	var arr:Array=temp.split("\n",temp.length);
	winnum=int(arr[1]);
	losenum=int(arr[2]);
	stream.close();    //关闭FileStream对象  
	//当昵称不是默认值时写入文件
	if(userName !="Anonymous")
	{
		stream.open(userfile, FileMode.WRITE);
		stream.writeUTFBytes(userName+"\n"+arr[1]+"\n"+arr[2]);
		stream.close();    //关闭FileStream对象  
	}
	//bgm hack
	se_hack.play();
}

private function onMoved(e:TimerEvent):void
{
	
	if(BlockPic.isFinished==true)
	{
		this.addElement(checkboard);
		checkboard.x=bp.x;
		checkboard.y=bp.y+bp.finalY;
		this.removeElement(bp);
		//用于装载弹幕的容器
		container=new UIComponent();
		container.width=this.width;
		container.height=this.height;
		this.addElement(container);
		
		if(Mode=="1")
			newClient();
		e.target.removeEventListener(TimerEvent.TIMER,onMoved);
		
		//游戏入口
		prepareGame();
	}
}

/*
*创建新的客户端socket
*/
private function newClient():void
{
	//创建客户端连接服务端进行游戏
	
	if(attackSocket !=null&&attackSocket.connected)
	{
		attackSocket.close();
	}
	attackSocket=new Socket();
	attackSocket.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
	
	try{
		serverHost=BlockPic.DecodeID(login.code.text);
		attackSocket.connect(serverHost,localPort+2);//DecodeID(attackCode.text)
	}catch(err:IOError)
	{
		trace(err.message);
		trace("对方已切断网络连接，无法攻击！");
	}
	attackSocket.addEventListener(Event.CONNECT,onAttackConnect2);
}

private function onAttackConnect2(event:Event):void
{
	//发送玩家信息
	CSSend(winnum,losenum,0,0,userName,1,1);trace("客户端发送玩家信息：",winnum,losenum,userName);
	//监听消息
	attackSocket.addEventListener(ProgressEvent.SOCKET_DATA,onSocketData2);
}

private function onSocketData2(event:ProgressEvent ):void
{
	var buffer:ByteArray =new ByteArray();
	attackSocket.readBytes( buffer, 0, attackSocket.bytesAvailable );
	
	//当回合接收数据数+1
	dateRcvd++;
	
	//当接收到确认信息时清空累计计数
	var data:Array=BlockPic.handleMsg(buffer.toString());
	actionAct(data);
	
	//记录所有接收到的信息
	saveLog(buffer.toString(),2);
}

/*
* 创建新的服务端socket连接
*/

private function newServer():void
{
	trace("开始新服务端")
	serverSocket=new ServerSocket();
	serverSocket.bind( localPort+2 , "0.0.0.0" );
	//serverSocket.bind( localPort , getIP() );
	serverSocket.addEventListener( ServerSocketConnectEvent.CONNECT, onConnect2 );
	serverSocket.listen(1);
}

//当客户端成功连接服务端
private function onConnect2( event:ServerSocketConnectEvent):void
{
	clientSocket = event.socket;
	clientSocket.addEventListener( ProgressEvent.SOCKET_DATA, onClientSocketData2 );
	//传递玩家信息
	if(userName=="")
		userName="Anonymous";
	CSSend(winnum,losenum,0,0,userName,1,1);trace("服务端发送玩家信息：",winnum,losenum,userName);
}

//当有数据通信时
private function onClientSocketData2( event:ProgressEvent ):void
{
	var buffer:ByteArray =new ByteArray();
	clientSocket.readBytes( buffer, 0, clientSocket.bytesAvailable );
	
	//当回合接收数据数+1
	dateRcvd++;
	//当接收到确认信息时清空累计计数
	var data:Array=BlockPic.handleMsg(buffer.toString());
	actionAct(data);
	
	//记录所有接收到的信息
	saveLog(buffer.toString(),2);
}
/*
*
*
*				具体流程处理函数,所有网络接收到的数据都集中在这里处理
*
*
*/
//用于处理收到的信息 
private function actionAct(mode:Array):void
{trace("捕获数据：",mode)
	
	if(finished)
		return;
	
	//对手信息
	if(mode[5]==1&&mode[6]==1)
	{
		tips.EnemyWin=mode[0];
		tips.EnemyLose=mode[1];
		tips.EnemyName=(mode[4]=="")?"Anonymous":mode[4];
	}
	//开启超速回线
	else if(mode[5]==3&&mode[6]==0)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		tips.setTerminal(-1,0);
		checkboard.chessMap[9-mode[0]][9-mode[1]].speedup();
		checkboard.showTC(2,9-mode[0],9-mode[1]);
	}
		//关闭超速回线
	else if(mode[5]==3&&mode[6]==1)
	{
		tips.setTerminal(-1,1);
		checkboard.chessMap[9-mode[0]][9-mode[1]].speeddown();
	}
		//开启防火墙
	else if(mode[5]==4&&mode[6]==0)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		tips.setTerminal(-1,-1,0);
		checkboard.findFireWall(9-mode[2],9-mode[3]);
		checkboard.showTC(3,9-mode[2],9-mode[3]);
	}
		//关闭防火墙
	else if(mode[5]==4&&mode[6]==1)
	{
		tips.setTerminal(-1,-1,1);
		checkboard.cancelFireWall(checkboard.Mode=="G"?"B":"G");
	}
		//接收checker信息
	else if(mode[5]==5&&mode[6]==0)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		tips.setTerminal(0);
		var temp:int=checkboard.getIdentity(mode[0],mode[1]);
		CSSend(temp,mode[0],
			mode[1],mode[2],"",5,1);
		checkboard.showTC(1,9-mode[0],9-mode[1]);
	}
		//接收探查反馈信息
	else if(mode[5]==5&&mode[6]==1)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		checkboard.chessMap[mode[1]][mode[2]].setLink(mode[0]);
		checkboard.showTC(1,mode[0],mode[1]);
		checkboard.moveTurn=false;
		checkboard.myTurn=false;
	}
		//棋子交换
	else if(mode[5]==6)
	{
		tips.setTerminal(-1,-1,-1,0);
		//确认交换时
		if(mode[6]==1)
		{
			var tempChess:Chess=checkboard.chessMap[9-mode[0]][9-mode[1]];
			checkboard.chessMap[9-mode[0]][9-mode[1]]=checkboard.chessMap[9-mode[2]][9-mode[3]];
			checkboard.chessMap[9-mode[2]][9-mode[3]]=tempChess;
		}
		checkboard.notFoundMessage(9-mode[0],9-mode[1],9-mode[2],9-mode[3],mode[6]);
		checkboard.showTC(4,9-mode[0],9-mode[1]);
	}
		//棋子移动
	else if(mode[5]==7&&mode[6]==0)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		moveChess(9-mode[0],9-mode[1],9-mode[2],9-mode[3]);
	}
		//棋子受到攻击
	else if(mode[5]==7&&mode[6]==1)
	{
		CSSend(mode[0],mode[1],
			mode[2],mode[3],"",11,checkboard.chessMap[9-mode[2]][9-mode[3]].isLink);
		capture(9-mode[2],9-mode[3],checkboard.chessMap[9-mode[2]][9-mode[3]].isLink);
		moveChess(9-mode[0],9-mode[1],9-mode[2],9-mode[3]);
	}
		//棋子进入服务器
	else if(mode[5]==7&&mode[6]==3)
	{
		checkboard.entered(9-mode[0],9-mode[1],mode[2]);
	}
		//游戏结束
	else if(mode[5]==8 && (mode[6]==0||mode[6]==1||mode[6]==2) )
	{
		//记录棋子身份参数
		var chessId:Array=[mode[0],mode[1],mode[2],mode[3]];
		//统计己方棋子身份
		var larr:Array=new Array();
		for(var i:int=0;i<8;i++)
			if(checkboard.myTeam[i].isLink==1)
				larr.push(i);
		//游戏结束前结束一系列侦听
		CSSend(larr[0],larr[1],larr[2],larr[3],"",8,(mode[6]==0)?1:0);
		finished=true;
		tips.removeEventListener(MouseEvent.CLICK,tcMode);
		this.removeEventListener(MouseEvent.RIGHT_CLICK,cancelTerminal);
		//翻开对方牌面
linkPoint:for(var i:int=0;i<8;i++)
		{
			var chess:Chess=checkboard.yourTeam[i] as Chess;
			//若棋子身份已被标记则跳出循环
			if(chess.isLink!=0)
				continue linkPoint;
			//判断是否为link
			for(var j:int=0;j<4;j++)
			{
				if(i==7-chessId[j])
				{
					chess.setLink(1);
					continue linkPoint;
				}
			}
			//确认为virus
			chess.setLink(2);	
		}
		//停止bgm
		bgm.bgmStop();
		//断开连接
		if(attackSocket&&attackSocket.connected)
		{
			attackSocket.removeEventListener(ProgressEvent.SOCKET_DATA,onSocketData2);
			attackSocket.close();
		}
		if(clientSocket)
		{
			clientSocket.removeEventListener( ProgressEvent.SOCKET_DATA, onClientSocketData2 );
			clientSocket=null;
		}
		if(serverSocket&&serverSocket.bound)
		{
			serverSocket.close();
		}
		if(mode[6]==1)
		{
			tips.setTip("result","胜利！");trace("胜利")
			//当游戏胜利时记录
			winnum++;
			stream = new FileStream();
			//写入信息
			stream.open(userfile, FileMode.WRITE );
			stream.writeUTFBytes(userName+"\n"+winnum+"\n"+losenum);
			stream.close();    //关闭FileStream对象  
			onWin();
		}else if(mode[6]==0){
			tips.setTip("result","失败！");
			//当游戏失败时记录
			losenum++;
			stream = new FileStream();
			//写入信息
			stream.open(userfile, FileMode.WRITE );
			stream.writeUTFBytes(userName+"\n"+winnum+"\n"+losenum);
			stream.close();    //关闭FileStream对象  
			onLose();
		}else if(mode[6]==2){
			tips.setTip("result:","对手逃跑，胜利！");
			//当游戏胜利时记录
			winnum++;
			stream = new FileStream();
			//写入信息
			stream.open(userfile, FileMode.WRITE );
			stream.writeUTFBytes(userName+"\n"+winnum+"\n"+losenum);  
			stream.close();    //关闭FileStream对象 
			onWin();
		}
	}
	//接收消息
	else if(mode[5]==10&&mode[6]==0)
	{
		if(!acceptTalk)
			return;
		shot(mode[4] as String,(Mode=="2")?0xffff00:0x0000ff);
	}
	//攻击反馈
	else if(mode[5]==11)
	{
		var c:Chess = checkboard.chessMap[mode[2]][mode[3]];
		if(c == null || c.getType() == checkboard.Mode)
			return;
		
		capture(mode[2],mode[3],mode[6]);
		moveChess(mode[0],mode[1],mode[2],mode[3]);
	}
	else if(mode[5]==12 && mode[6]==0)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		if(lastDate.length != 0)
		{
			for(var i:int=mode[0];i<lastDate.length;i++)
			{
				BlockPic.myTimer(500*(i-mode[0]),function(e:TimerEvent):void{
					if(lastDate[i] !=null)
						CSSend2(lastDate[i]);
				},1);
			}
		}
	}
		//回合开始
	else if(mode[5]==2&&mode[6]==3)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		if(dateRcvd >0)
			dateRcvd--;
		//确认回合开始
		CSSend(dateRcvd,0,0,0,"",20,0);
		
		
		if(checkboard.myTurn==false)
		{
			BlockPic.myTimer(250,listenEnd);
			checkboard.moveTurn=true;
			checkboard.myTurn=true;
			lastDate=[];
			tcTurn();
			//展开tc面板
			if(!tips.out_s1)
				tips.SwitchOn(1);
		}
	}
		//游戏开始
	else if(mode[5]==2&&mode[6]==1)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		checkboard.moveTurn=true;
		checkboard.myTurn=true;
		BlockPic.myTimer(250,listenEnd);
		dateRcvd=0;
		lastDate=[];
		tcTurn();
		tips.setTip("tips: ","我方先攻");
		//展开tc面板
		if(!tips.out_s1)
			tips.SwitchOn(1);
	}
	else if(mode[5]==2&&mode[6]==2)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		
		tips.setTip("tips: ","对方先攻");
	}
		//设置棋子完毕
	else if(mode[5]==0 && mode[6]==1)
	{
		if(mode[4] != "blank")
		{
			dateRcvd--;
			CSSend(dateRcvd,0,0,0,"",12,0);
			return;
		}
		Yprepared=true;
	}
	else if(mode[5]==20 && mode[6]==0)
	{
		dateRcvd=0;
		startReply=mode[0];
	}
	else
	{
		dateRcvd--;
		CSSend(dateRcvd,0,0,0,"",12,0);
	}
}

//服务端发送信息
public static function ServerSend(n1:int,n2:int,n3:int,n4:int,str:String,s1:int,s2:int):void
{
	try{
		clientSocket.writeUTFBytes(BlockPic.asc(n1,n2,n3,n4,str,s1,s2));
		clientSocket.flush();
	}catch(err:IOError){
		trace("服务端数据发送异常");
	}
	trace("服务端发送数据了：",n1,n2,n3,n4,str,s1,s2);
}

//客户端发送信息
public static function ClientSend(n1:int,n2:int,n3:int,n4:int,str:String,s1:int,s2:int):void
{
	try{
		attackSocket.writeUTFBytes(BlockPic.asc(n1,n2,n3,n4,str,s1,s2));
		attackSocket.flush();
	}catch(err:IOError){
		trace("客户端数据发送异常");
	}
	trace("客户端发送数据了：",n1,n2,n3,n4,str,s1,s2);
}

//通用通信方式
public function CSSend(n1:int,n2:int,n3:int,n4:int,str:String,s1:int,s2:int):void
{
	//判断如果是告知回合开始的信息则启动计时器
	if(s1==2&&s2==3)
		reSendTimer.start();
	
	//保存上一步数据
	if(str=="" && s1 != 10)
	{
		str="blank";
		lastDate.push(BlockPic.asc(n1,n2,n3,n4,"blank",s1,s2));
	}
	else
		lastDate.push(BlockPic.asc(n1,n2,n3,n4,str,s1,s2));
	//记录到日志文件
	saveLog(lastDate[lastDate.length-1],1);
	//发送数据
	if(Mode=="2")
	{
		ServerSend(n1,n2,n3,n4,str,s1,s2);
	}
	else if(Mode=="1")
	{
		ClientSend(n1,n2,n3,n4,str,s1,s2);
	}
}

public function CSSend2(data:String):void
{
	var sdata:Array=BlockPic.handleMsg(data);
	if(sdata[5]==2)
	{
		CSSend2(lastDate[lastDate.length-2]);
		return;
	}
	
	if(Mode=="2")
	{
		if(clientSocket==null)
			return;
		clientSocket.writeUTFBytes(data);trace("服务端发送数据了：",data);
		clientSocket.flush();
	}
	else if(Mode=="1")
	{
		if(attackSocket==null)
			return;
		attackSocket.writeUTFBytes(data);trace("客户端发送数据了：",data);
		attackSocket.flush();
	}
}

//显示/隐藏对话框
public function showTalk():void
{
	if(!talkBoard.parent||talkBoard.visible==false)
	{
		this.addElement(talkBoard);
		talkBoard.x=checkboard.x+checkboard.width/2-talkBoard.width/2;
		talkBoard.y=checkboard.y+1000;
		talkBoard.visible=false;
		TweenLite.to(talkBoard,.4,{y:checkboard.y+600,autoAlpha:1});
		//发送聊天信息侦听
		talkBoard.addEventListener(KeyboardEvent.KEY_UP,keySend);
		talkBoard.send.addEventListener(MouseEvent.CLICK,buttonSend);
	}else{
		TweenLite.to(talkBoard,.4,{y:checkboard.y+1000,autoAlpha:0});
	}
}
//隐藏对话框
public function hideTalk():void
{
	TweenLite.to(talkBoard,.4,{y:checkboard.y+1000,autoAlpha:0});
}

private function keySend(e:KeyboardEvent):void
{
	//当不是回车按下时退出函数
	if(e.keyCode !=13)
		return;
	//若连接异常则不显示发送信息
	try{
		sendTalk(talkBoard.inputText.text);
		shot(talkBoard.inputText.text);
	}catch(e:Error){
		trace("连接异常");	
	}
	talkBoard.inputText.text="";
	e.target.removeEventListener(KeyboardEvent.KEY_UP,keySend);
	hideTalk();
}

private function buttonSend(e:MouseEvent):void
{
	try{
		sendTalk(talkBoard.inputText.text);
		shot(talkBoard.inputText.text);
	}catch(e:Error){
		trace("连接异常");	
	}
	talkBoard.inputText.text="";
	e.target.removeEventListener(MouseEvent.CLICK,buttonSend);
	hideTalk();
}

//发送对话
private function sendTalk(str:String):void
{
	CSSend(1,1,1,1,str,10,0);
}

//发射弹幕
public function shot(str:String,nowcolor:int=0,pos:int=30,sp:int=1,delay:Number=0):void
{
	//设置弹幕标签
	var label:Label=new Label();
	var color:int;
	//Mode==2代表己方是蓝色棋子，1代表绿色
	if(Mode=="2"&&nowcolor==0)
		color=0x0000ff;
	else if(nowcolor==0)
		color=0xffff00;
	else
		color=nowcolor;
	this.addElement(label);
	label.text=str;
	var fontsize:int=int(Math.random()*20+25);
	label.setStyle("fontSize",fontsize);
	label.setStyle("color",color);
	label.setStyle("fontWeight","bold");
	label.x=this.width;
	label.y=Math.random()*this.height/3+pos;
	//设置弹幕大小
	label.width=(fontsize+1)*label.text.length;
	label.height=fontsize;
	//侦听label创建完成
	label.addEventListener(Event.ADDED,function(e:Event):void{
		
		var bitData:BitmapData;
		var bitMsg:Bitmap;
		//将标签转化为bitmap并添加到container上
		bitData=new BitmapData(label.width,label.height,true,0);
		bitData.draw(label as UIComponent);
		bitMsg=new Bitmap(bitData as BitmapData);
		container.addChild(bitMsg);
		bitMsg.x=label.x;
		bitMsg.y=label.y;
		label.removeEventListener(Event.ADDED,shotHandle);
		FlexGlobals.topLevelApplication.removeElement(label);
		//发射弹幕
		TweenLite.to(bitMsg,10-sp,{x:-label.width,ease:asFile.Linear.easeNone,delay:delay});
		TweenLite.to(bitMsg,.5,{autoAlpha:0,delay:10-sp+delay,overwrite:0});
		
	},false,0,true);
}

private function shotHandle(e:Event):void
{
	var bitData:BitmapData;
	var bitMsg:Bitmap;
	var label:Label=e.currentTarget as Label;
	//将标签转化为bitmap并添加到container上
	bitData=new BitmapData(label.width,label.height,true,0);
	bitData.draw(label as UIComponent);
	bitMsg=new Bitmap(bitData as BitmapData);
	container.addChild(bitMsg);
	bitMsg.x=800;
	bitMsg.y=200;
	label.removeEventListener(Event.ADDED,shotHandle);
	this.removeElement(label);
	trace(bitMsg,bitMsg.parent,bitMsg.width,bitMsg.height,bitMsg.x,bitMsg.y,bitMsg.visible,bitMsg.alpha)
	//trace(label,label.parent,label.width,label.height,label.x,label.y,label.visible,label.alpha)
}

//显示提示横幅
public function showTipBar(str:String):void
{
	this.addElement(tipbar);
	tipbar.setText(str);
	tipbar.play(this.width);
}

//获胜时执行
private function onWin():void
{
	//显示victory
	victory.x=this.width/2;
	victory.y=this.height/2;
	victory.alpha=0;
	this.addElement(victory);
	TweenLite.to(victory,2,{alpha:1});
	TweenLite.to(checkboard,10,{autoAlpha:0});
	TweenLite.to(tips,10,{autoAlpha:0,onComplete:reStart});
	//播放音效
	Music.playVoice(0);
}

//失败时执行
private function onLose():void
{
	//血迹
	var blood:TransImage=new TransImage("image/blood.png");
	blood.x=this.width/2;
	blood.y=this.height/2;
	//红色背景
	//设置屏幕大小
	redback.setSize(this.width*1.5,this.height*1.5);
	
	this.addElement(blood);
	blood.visible=false;
	this.addElement(redback);
	redback.alpha=0;
	//播放音效
	Music.playVoice(1);
	//出现大量红色弹幕
	for(var i:int=0;i<16;i++)//ffc60115
	{
		for(var j:int=0;j<this.height/50;j++)
		{
			shot("失败した失败した失败した",0xffc60115,j*35,Math.random()*3,Number(i)/2);
		}
	}
	//血迹2.5s后可见
	TweenLite.to(blood,2.5,{visible:true});
	//9s显示红色背景
	TweenLite.to(redback,12,{alpha:1.2,onComplete:reStart});
}

//重启应用程序
private function reStart():void
{
	var app:WindowedApplication = WindowedApplication(FlexGlobals.topLevelApplication);
	var mgr:ProductManager = new ProductManager("airappinstaller");
	mgr.launch("-launch "+app.nativeApplication.applicationID+" "+app.nativeApplication.publisherID);
	app.close();
}

//记录日志文件
//str:记录的信息
//type:记录信息发送方，1为自己，2为对方
public function saveLog(str:String,type:int):void
{
	//系统时间对象
	var data:Date=new Date();
	var t:Number=int(data.getTime()/100-preDate.getTime()/100);
	preDate=data;
	//写文件
	stream = new FileStream();
	stream.open(logfile, FileMode.APPEND );
	stream.writeUTFBytes(str+"\n\r");
	stream.writeUTFBytes(String.fromCharCode(type)+"\n\r");
	stream.writeUTFBytes(String.fromCharCode(t)+"\n\r");
	stream.close();trace("save log: "+BlockPic.handleMsg(str),t)
}

//发送关闭事件
public function sendExiting():void
{
	var event:Event=new Event(Event.EXITING, false, true);
	this.nativeApplication.addEventListener(Event.EXITING,onExiting);
	this.nativeApplication.dispatchEvent(event);
}