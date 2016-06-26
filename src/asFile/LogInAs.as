// ActionScript file

package asFile{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeProcess;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.system.Capabilities;
	import flash.text.TextField;
	
	import mx.core.UIComponent;
	
	import asFile.Music;
	
	private var serverCode:String="";//自己的链接码
	private var userName:String="";//自己的昵称
	private var login:Login=new Login();
	private var pop:Pop=new Pop();
	private var container:UIComponent=new UIComponent();
	//预加载音效
	private var se_click1:Music=new Music("se/se01.mp3");
	private var se_click2:Music=new Music("se/se02.mp3");
	private var se_hack:Music=new Music("se/se08.mp3");
	private var se_move:Music=new Music("se/se07.mp3");
	private var bgm:Music=new Music;
	
	
	public function init():void//初始化
	{
		
		nativeWindow.x=0;//将透明主窗口坐标设于屏幕左上角
		nativeWindow.y=0;
		nativeWindow.alwaysInFront=true;//将窗体永远置于最上层（一直可见）
		nativeWindow.width=Capabilities.screenResolutionX;//透明主窗体覆盖全屏幕
		nativeWindow.height=Capabilities.screenResolutionY;
		this.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN,closeFunc);
		this.addEventListener(MouseEvent.CLICK,activeWindow);
		//设置3d旋转焦点
		var p:PerspectiveProjection=new PerspectiveProjection(); 
		p.projectionCenter = new Point(nativeWindow.width/2,nativeWindow.height/2);
		this.transform.perspectiveProjection=p;
		//开始作为服务器侦听攻击行为
		bind();
		//加载、设置登录窗口
		handleLogin();
		//加载bgm
		bgm.addBgm("bgm/bgm01.mp3");
		bgm.addBgm("bgm/bgm02.mp3");
		bgm.addBgm("bgm/bgm03.mp3");
	}
	
	//定时激活窗口
	private function activeWindow(e:MouseEvent):void
	{
		this.nativeApplication.activate();
	}
	//关闭应用程序
	private function closeFunc(e:KeyboardEvent):void
	{
		if(e.keyCode !=27)
			return;
		var event:Event=new Event(Event.EXITING, false, true);
		this.nativeApplication.addEventListener(Event.EXITING,onExiting);
		this.nativeApplication.dispatchEvent(event);
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
		login.code.addEventListener(MouseEvent.CLICK,onActive);
		
		this.addElement(login);
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
		file.nativePath=File.applicationDirectory.nativePath + filename;trace(NativeProcess.isSupported ,file.nativePath);
		try{
			if(file.exists)
			{
				//var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				//info.executable = file;
				//var process:NativeProcess = new NativeProcess();
				//process.start(info);
				file.openWithDefaultApplication();
			}
		}catch(err:Error){
			trace("打开出错");
		}
	}
	//连线开始游戏
	private function onLink(e:MouseEvent):void
	{
		userName=(login.sign.text=="")?"Stranger":login.sign.text;
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
		if(serverCode=="")
		{
			txt="获取链接码失败，请检查网络";
		}else if(testIP(serverCode))
		{
			serverCode=BlockPic.EncodeID(serverCode);
			txt="链接码已复制到剪贴板中，现在可以发给别人对战了~";
		}else{
			serverCode=BlockPic.EncodeID(serverCode);
			txt="链接码已复制到剪贴板中，但该链接码可能只能进行局域网对战";
		}
		Clipboard.generalClipboard.clear();
		Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT,serverCode);
		showPop(txt,"获取链接码");
	}
	//清除使用记录
	private function onClear(e:MouseEvent):void
	{
		var file:File = new File();
		file.nativePath=File.applicationDirectory.nativePath + "/sys/user_data.sav";//若没有此文件则新建
		var stream:FileStream = new FileStream();    //清空记录
		stream.open(file, FileMode.WRITE);
		stream.writeUTFBytes("");  
		stream.close();    //关闭FileStream对象  
		showPop("用户信息已清理完毕！");
	}
	//规则相关
	private function onRuler(e:MouseEvent):void
	{
		openFile("/txt/rule.txt");
	}
	//关于作品/作者
	private function onAbout(e:MouseEvent):void
	{
		openFile("/txt/readme.txt");
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
}