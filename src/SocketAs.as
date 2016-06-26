// ActionScript file

import air.net.SocketMonitor;

import asFile.BlockPic;

import flash.errors.IOError;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.ServerSocketConnectEvent;
import flash.net.InterfaceAddress;
import flash.net.NetworkInfo;
import flash.net.NetworkInterface;
import flash.net.ServerSocket;
import flash.net.Socket;



private static var serverSocket:ServerSocket = new ServerSocket();
private static var clientSocket:Socket;
private static var attackSocket:Socket;


//private var _clients:Array = [];
private var localIP:String;
private var clientIP:String;
private var serverIP:String;
private var localPort:int=25251;
private var isConnected:Boolean=false;
private var ip:Array=new Array();


//获取ip地址函数
private function getIP():String
{
	var networkInfo:NetworkInfo=NetworkInfo.networkInfo
	var interfaces:Vector.<NetworkInterface>=networkInfo.findInterfaces();
	ip=new Array();
	
	if( interfaces != null ) 
	{ 
		for each ( var interfaceObj:NetworkInterface in interfaces ) 
		{ 
			if(interfaceObj.active==false)
				continue;
			for each ( var address:InterfaceAddress in interfaceObj.addresses ) 
			{
				if(address.ipVersion !="IPv4"||address.address=="127.0.0.1")
					continue;
				ip.push(address.address);
				trace( "  address: "         + address.address );
			} 
		}
	}
	for(var ipn:int=0;ipn<ip.length;ipn++)
	{
		if(String(ip[ipn]).indexOf("172.") !=-1||String(ip[ipn]).indexOf("173.") !=-1)
		{return ip[ipn];trace("我方ip：",ip[ipn])}
	}
	if(ip.length !=0)
	{return ip[0];trace("我方ip：",ip[0])}
	else
		return "";
}

//判断ip是否为有效的ip地址
private function testIP(ip:String):Boolean
{
	var ipNum:Array=ip.split('.');
	trace("testIP",ipNum)
	
	if(ipNum[0]==10||(ipNum[0]==192&&ipNum[1]==168))
		return false;
	
	if(ipNum[0]==172&&ipNum[1]>=16&&ipNum[1]<=31)
		return false;
	
	if(ipNum[0]==172||ipNum[0]==173)
		return true;
		
	else if(ipNum[0]>0&&ipNum[0]<127&&ipNum[3]>0&&ipNum[3]<255)
		return true;
		
	else if(ipNum[0]>=128&&ipNum[0]<=191&&ipNum[3]>0&&ipNum[3]<255)
		return true;
		
	else if(ipNum[0]>=192&&ipNum[0]<=223&&ipNum[3]>0&&ipNum[3]<255)
		return false;
	
	if(ipNum[0]==169&&ipNum[1]==254)
		return false;
		
	else
		return false;
}

/*
* 服务端代码
*/

//绑定服务器ip 开始监听端口
private function bind():void
{
	if( serverSocket.bound ) 
	{
		serverSocket.close();
		serverSocket = new ServerSocket();
		
	}
	serverSocket.bind( localPort , "0.0.0.0" );
	serverSocket.addEventListener( ServerSocketConnectEvent.CONNECT, onConnect );
	serverSocket.listen(1);
}

//当客户端成功连接服务端
private function onConnect( event:ServerSocketConnectEvent):void
{
	clientSocket = event.socket;
	if(!isConnected)
	{
		isConnected=true;trace("检测到连接")
		clientSocket.addEventListener( ProgressEvent.SOCKET_DATA, onClientSocketData );
	}
	
}

//当有数据通信时
private function onClientSocketData( event:ProgressEvent ):void
{
	var buffer:String = "";
	buffer=clientSocket.readUTFBytes(clientSocket.bytesAvailable);
	
	clientSocket.removeEventListener( ProgressEvent.SOCKET_DATA, onClientSocketData );
	
	var item:Socket = clientSocket;trace(item.remoteAddress);
	trace("对方ip",item.remoteAddress,"己方ip",getIP())
	if (!item || !(serverCode) ||item.remoteAddress!= BlockPic.DecodeID(buffer)) return;//*通讯*
	/**/
	item.writeUTFBytes(BlockPic.EncodeID(item.remoteAddress));
	item.flush();
	
	//开始游戏
	trace("服务端游戏开始")
	serverSocket.removeEventListener( ServerSocketConnectEvent.CONNECT, onConnect );
	clientIP=clientSocket.remoteAddress;
	clientSocket.close();
	serverSocket.close();
	if(attackSocket)
		attackSocket.close();
	
	newServer();
	
	gameStart("2");
	
}



/*
* 客户端代码
*/

//创建客户端连接服务端进行游戏
private function buildUpClient():void{
	var ip:String=BlockPic.DecodeID(login.code.text);
	if(ip==getIP())
		return;
	if(attackSocket !=null&&attackSocket.connected)
	{
		attackSocket.close();
	}
	attackSocket=new Socket();
	attackSocket.addEventListener(IOErrorEvent.IO_ERROR,onIOError);
	
	try{
		trace("对方ip",ip);
		attackSocket.connect(ip,localPort);//"127.0.0.1" DecodeID(attackCode.text)*通讯*
	}catch(err:IOError)
	{
		trace(err.message);
		trace("对方已切断网络连接，无法攻击！");
	}
	attackSocket.addEventListener(Event.CONNECT,onAttackConnect);
}
//客户端连接失败时
private function onIOError(e:IOErrorEvent):void
{
	//trace(e.message);
	trace("连接出错哒哟~");
}

private function onAttackConnect(event:Event):void
{
	if(serverCode=="")
		serverCode=BlockPic.EncodeID(getIP());
	trace("client",serverCode);
	attackSocket.writeUTFBytes(serverCode);
	attackSocket.flush();
	attackSocket.addEventListener(ProgressEvent.SOCKET_DATA,onSocketData);
}

private function onSocketData(event:ProgressEvent ):void
{
	var buffer:String = "";
	buffer=attackSocket.readUTFBytes(attackSocket.bytesAvailable);
	if(BlockPic.DecodeID(buffer)==attackSocket.localAddress)
	{
		//游戏开始
		trace("客户端游戏开始")
		serverIP=BlockPic.DecodeID(login.code.text);
		attackSocket.removeEventListener(Event.CONNECT,onAttackConnect);
		attackSocket.removeEventListener(ProgressEvent.SOCKET_DATA,onSocketData);
		attackSocket.close();
		gameStart("1");
	}else{
		
		attackSocket.close();
		if(serverSocket)
			serverSocket.close();
		if(clientSocket)
			clientSocket.close();
	}
}