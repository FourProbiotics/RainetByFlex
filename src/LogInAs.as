import asFile.BlockPic;
import asFile.Music;
import asFile.TransImage;

import flash.desktop.Clipboard;
import flash.desktop.ClipboardFormats;
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.DatagramSocketDataEvent;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.geom.PerspectiveProjection;
import flash.geom.Point;
import flash.net.DatagramSocket;
import flash.system.Capabilities;
import flash.system.IME;
import flash.text.TextField;
import flash.ui.KeyLocation;

import mx.controls.Alert;
import mx.core.UIComponent;
import mx.events.CloseEvent;
	
	private var serverCode:String="";//自己的链接码
	private var userName:String="";//自己的昵称
	private var login:Login=new Login();
	private var pop:Pop=new Pop();
	private var container:UIComponent=new UIComponent();
	//背景图
	private var bg:TransImage=new TransImage("sys/background.png");
	//预加载音效
	private var se_click1:Music=new Music("se/se01.mp3");
	private var se_click2:Music=new Music("se/se02.mp3");
	private var se_hack:Music=new Music("se/se08.mp3");
	private var se_move:Music=new Music("se/se07.mp3");
	public static var bgm:Music=new Music;
	//调用本地进程
	private var nativeProcessStartupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo(); 
	private var cfile1:File=new File;
	private var cfile2:File=new File;
	private var process:NativeProcess;
	private var processArgs:Vector.<String>;
	//udp广播侦听
	private var udpHandler:DatagramSocket = new DatagramSocket();
	//用户文件
	private var stream:FileStream;
	private var userfile:File = new File();
	//日志文件
	private var logfile:File=new File();
	//向日葵
	private var sunlogin:String="/sunlogin/OrayRemoteShell.exe";
	
	public function init():void//初始化
	{
		
		nativeWindow.x=0;//将透明主窗口坐标设于屏幕左上角
		nativeWindow.y=0;
		nativeWindow.alwaysInFront=true;//将窗体永远置于最上层（一直可见）
		nativeWindow.width=Capabilities.screenResolutionX;//透明主窗体覆盖全屏幕
		nativeWindow.height=Capabilities.screenResolutionY;
		bg.width=nativeWindow.width;//背景图覆盖全屏
		bg.height=nativeWindow.height;
		bg.x=nativeWindow.width/2;
		bg.y=nativeWindow.height/2;
		this.addElement(bg);
		this.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN,closeFunc);
		this.addEventListener(MouseEvent.CLICK,activeWindow);
		//设置3d旋转焦点
		var p:PerspectiveProjection=new PerspectiveProjection(); 
		p.projectionCenter = new Point(nativeWindow.width/2,nativeWindow.height/2);
		this.transform.perspectiveProjection=p;
		//开始侦听链接码广播
		if( udpHandler.bound )
		{
			udpHandler.close();
			udpHandler = new DatagramSocket();
			
		}
		udpHandler.bind( 5568, "0.0.0.0" );
		udpHandler.addEventListener( DatagramSocketDataEvent.DATA, catchLink);
		udpHandler.receive();
		//开始作为服务器侦听攻击行为
		bind();
		//准备发送链接码广播
		cfile1.nativePath=File.applicationDirectory.nativePath + "/sys/broadcast173.exe";
		cfile2.nativePath=File.applicationDirectory.nativePath + "/sys/broadcast.exe"; 
		processArgs = new Vector.<String>(); 
		//加载、设置登录窗口
		handleLogin();
		//配置userfile
		userfile.nativePath=File.applicationDirectory.nativePath + "/sys/user_data.sav";
		stream = new FileStream();
		//新建日志文件
		logfile.nativePath=File.applicationDirectory.nativePath + "/sys/Game.log";
		
		//若没有此文件则新建
		if(!userfile.exists)
		{
			stream.open(userfile, FileMode.WRITE );
			stream.writeUTFBytes("Anonymous\n0\n0");
			stream.close();    //关闭FileStream对象  
		}else{
			//读取记录
			stream.open(userfile, FileMode.READ );
			if(stream.bytesAvailable==0)
			{
				stream.close();    //关闭FileStream对象
				stream.open(userfile,FileMode.WRITE);
				stream.writeUTFBytes("Anonymous\n0\n0");
				stream.close();    //关闭FileStream对象  
			}else{
				var str:String=stream.readUTFBytes(stream.bytesAvailable);
				var strArr:Array=str.split("\n");
				//将上次使用过的代号填入文本框内
				login.sign.text=strArr[0] as String;
				stream.close();    //关闭FileStream对象
			}
		}
	}
	//点击激活窗口
	private function activeWindow(e:MouseEvent):void
	{
		this.nativeApplication.activate();
	}
	//关闭应用程序
	private function closeFunc(e:KeyboardEvent):void
	{
		//当按下Esc键时关闭
		if(e.keyCode ==27)
		{
			Alert.yesLabel = "退出";  
			Alert.noLabel = "取消"; 
			Alert.show("确定要退出吗?", "退出", (Alert.YES | Alert.NO) , this, function(e:CloseEvent):void{
			
				if (e.detail==Alert.YES)
				{
					//关闭前发送逃跑信息
					try{
					
						CSSend(0,0,0,0,"run away",8,2);
				
					}catch(e:Error)
					{
						trace("连接异常");
					}
					//传递程序关闭事件
					sendExiting();
				}
			});
		}
		//当按下shift+空格时窗口最小化
		else if(e.keyCode==32&&e.shiftKey)
		{
			//this.nativeWindow.visible=!this.nativeWindow.visible;
			if(this.nativeWindow.displayState == "normal")
				this.nativeWindow.minimize();
		}
		else if(e.keyCode==40&&e.ctrlKey)
		{
			if(checkboard)
			{
				checkboard.scaleX=checkboard.scaleY=this.height/887;
				this.x=0;
			}
		}
		else if(e.keyCode==38&&e.ctrlKey)
		{
			if(checkboard)
				checkboard.scaleX=1;
		}
	}
	
	//关闭游戏前要处理的东西都在这里
	private function onExiting(e:Event):void
	{
		trace("要关闭了哟~");
		if(attackSocket&&attackSocket.connected)
			attackSocket.close();
		if(serverSocket&&serverSocket.bound)
			serverSocket.close();
		
		this.nativeApplication.exit();
	}
	
	
	//初始化登录窗口
	private function handleLogin():void
	 {
		
		login.x=(nativeWindow.width-login.width)/2;//图像居中
		login.y=(nativeWindow.height-login.height)/2;
		//设置按钮侦听
		login.bt1.addEventListener(MouseEvent.CLICK,onLink);
		login.bt2.addEventListener(MouseEvent.CLICK,onGetLink);
		login.bt3.addEventListener(MouseEvent.CLICK,onClear);
		login.bt4.addEventListener(MouseEvent.CLICK,onRuler);
		login.bt5.addEventListener(MouseEvent.CLICK,onAbout);
		login.bt6.addEventListener(MouseEvent.CLICK,onExit);
		login.sun.addEventListener(MouseEvent.CLICK,onSun);
		login.code.addEventListener(MouseEvent.CLICK,onActive);
		//用于解决textfield无法输入中文的bug
		login.sign.addEventListener(FocusEvent.FOCUS_IN, textFocusIn);
		
		this.addElement(login);
	 }
	//用于解决textfield无法输入中文的bug
	private function textFocusIn(e:FocusEvent):void
	{
		IME.enabled=true;
	}
	//用于弹出提示框
	private function showPop(txt:String,title:String=""):void
	{
		//创建一个承载弹出框的容器与登陆界面重合
		container.x=login.x;
		container.y=login.y;
		container.addChild(pop);
		this.addElement(container);
		pop.setTitle(title);
		pop.setText(txt);
		pop.setParen(login);
		pop.x=(login.width-pop.width)/2;
		pop.y=(login.height-pop.height)/2;
	}
	//用于打开文件
	private function openFile(filename:String):void
	{
		var file:File=new File();
		file.nativePath=File.applicationDirectory.nativePath + filename;
		trace("NativeProcess.isSupported: ",NativeProcess.isSupported ,file.nativePath);
		try{
			if(file.exists)
			{
				file.openWithDefaultApplication();
			}
		}catch(err:Error){
			trace("打开出错");
		}
	}
	//连线开始游戏
	private function onLink(e:MouseEvent):void
	{
		trace("login.sign.text:",login.sign.text)
		userName=(login.sign.text==""||login.sign.text=="null")?"Anonymous":login.sign.text;
		if(!(serverCode==login.code.text||login.code.text==""))
			buildUpClient();
		else
			trace("不能连接自己的电脑！");
	}
	//获取链接码
	private function onGetLink(e:MouseEvent):void
	{	
		var txt:String="";
		serverCode=getIP();
		
		//判断是否为向日葵局域网
		if(serverCode.charAt(0)=="1"&&serverCode.charAt(1)=="7"&&serverCode.charAt(2)=="3"&&serverCode.charAt(3)==".")
			nativeProcessStartupInfo.executable = cfile1;
		else
			nativeProcessStartupInfo.executable = cfile2;
			
		if(serverCode=="")
		{
			txt="获取链接码失败，请检查网络";
		}else if(testIP(serverCode))
		{
			serverCode=BlockPic.EncodeID(serverCode);
			txt="链接码已复制到剪贴板中并广播，现在可以发给别人对战了~";
			//udp广播链接码
			processArgs.push(serverCode); 
			nativeProcessStartupInfo.arguments = processArgs; 
			process = new NativeProcess();
			process.start(nativeProcessStartupInfo);
		}else{
			serverCode=BlockPic.EncodeID(serverCode);
			txt="链接码已复制到剪贴板中并广播，但该链接码可能只能进行局域网对战";
			//udp广播链接码
			processArgs.push(serverCode); 
			nativeProcessStartupInfo.arguments = processArgs; 
			process = new NativeProcess();
			process.start(nativeProcessStartupInfo);
		}
		Clipboard.generalClipboard.clear();
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT,serverCode);
		showPop(txt,"获取链接码");
	}
	//清除使用记录
	private function onClear(e:MouseEvent):void
	{
		stream = new FileStream();
		//清空记录
		stream.open(userfile, FileMode.WRITE );
		stream.writeUTFBytes("Anonymous\n0\n0");
		stream.close();    //关闭FileStream对象  
		login.sign.text="";//清除已读取的信息
		showPop("用户信息已清理完毕！");
	}
	//规则相关
	private function onRuler(e:MouseEvent):void
	{
		openFile("/txt/雷net规则.doc");
	}
	//关于作品/作者
	private function onAbout(e:MouseEvent):void
	{
		Alert.yesLabel="确定";//openFile("/txt/readme.txt");
		//Alert.buttonHeight=35;
		Alert.show("作者： 4君\n版本号： 0.409431(联机版)\n感谢各位提出的建议，然后祝大家新年快乐！\n第一届菲利斯杯圆满成功！^_^", "4君的话", (Alert.YES) , this);
	}
	//退出游戏
	private function onExit(e:MouseEvent):void
	{
		var event:Event=new Event(Event.EXITING, false, true);
		this.nativeApplication.addEventListener(Event.EXITING,onExiting);
		this.nativeApplication.dispatchEvent(event);
	}
	//自动获取剪贴板数据并清除剪贴板
	private function onActive(e:MouseEvent):void
	{
		var str:String=Clipboard.generalClipboard.getData(ClipboardFormats.TEXT_FORMAT) as String;
		if(str !=null)
			(e.target as TextField).text=str;
		Clipboard.generalClipboard.clear();
	}
	//打开向日葵
	private function onSun(e:MouseEvent):void
	{
		openFile(sunlogin);
	}
	//捕获局域网内生成的链接码
	private function catchLink(e:DatagramSocketDataEvent):Boolean
	{
		//若广播是自己发送的则忽略
		getIP();
		for(var i:int=0;i<ip.length;i++)
			if(e.srcAddress==ip[i])
				return false;
		trace("敌方ip：",e.srcAddress);
		var txt:String=e.data.readUTFBytes( e.data.bytesAvailable );
		showPop("已捕获链接码： "+txt,"捕获链接码");
		
		login.code.text=txt;
		return true;
	}