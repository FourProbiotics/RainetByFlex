package asFile
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;

	public class Music
	{
		private static var bgmArr:Array=new Array();
		private var sound:Sound;
		private var channel:SoundChannel;
		//声道音量
		private static var transform:SoundTransform = new SoundTransform(0.6);
		//bgm
		private static var Bgm:Array;
		private var directory:File=new File();
		private var list:Array;
		//语音
		private static var Voice:Array=[new Sound(new URLRequest("voice/voice01.mp3")),
			new Sound(new URLRequest("voice/voice02.mp3")),new Sound(new URLRequest("voice/viruschecker.mp3")),
			new Sound(new URLRequest("voice/lineboost.mp3")),new Sound(new URLRequest("voice/firewall.mp3")),
			new Sound(new URLRequest("voice/notfound.mp3"))];
		private var currentBgm:int=0;
		
		public function Music(request:String=null)
		{
			if(Bgm==null)
			{
				//将bgm文件夹下的mp3文件作为背景音乐
				directory.nativePath=File.applicationDirectory.nativePath + "/bgm/";
				list = directory.getDirectoryListing();
				Bgm=new Array();
				for(var i:int=0;i<list.length;i++)
				{
					var bgmName:String=list[i].nativePath;
					//如果文件不是mp3格式则跳过
					if(bgmName.indexOf(".mp3") ==-1)
						continue;
					Bgm.push(new Sound(new URLRequest(bgmName)));
					trace(bgmName);
				}
			}
			if(request !=null)
				sound=new Sound(new URLRequest(request));
		}
		
		public function play(loops:int=0):void
		{
			try{
				channel=sound.play(0,loops);
			}catch(e:Error){
				trace(e.message);
			}
		}
		
		public function stop():void
		{
			if(channel)
				channel.stop();
		}
		
		public function addBgm(request:String):void
		{
			var bgm:Sound=new Sound(new URLRequest(request));
			Bgm.push(bgm);
		}
		
		public function playBgm():void
		{
			if(Bgm.length==0)
				return;
			if(channel)
			{
				channel.removeEventListener(Event.SOUND_COMPLETE,onBgmEnd);
				channel.stop();
				channel=null;
			}
			channel=(Bgm[currentBgm] as Sound).play(0);
			//channel.soundTransform.volume=.3;
			transform = channel.soundTransform;
			transform.volume = .6;  
			channel.soundTransform = transform;
			channel.addEventListener(Event.SOUND_COMPLETE,onBgmEnd);
		}
		
		public static function playVoice(i:int):void
		{
			(Voice[i] as Sound).play();
		}
		
		private function onBgmEnd(e:Event):void
		{
			currentBgm=(currentBgm+1)%Bgm.length;
			channel=(Bgm[currentBgm] as Sound).play(0);
			transform = channel.soundTransform;
			transform.volume = .6;  
			channel.soundTransform = transform;
			channel.addEventListener(Event.SOUND_COMPLETE,onBgmEnd);
		}
		
		public function bgmStop():void
		{
			if(channel)
			{
				channel.removeEventListener(Event.SOUND_COMPLETE,onBgmEnd);
				channel.stop();
				channel=null;
			}
		}
		//调节音量
		public function bgmVolume(rank:Number=-.2):void
		{
			transform.volume = (transform.volume+rank>=0)?(transform.volume+rank):(1+transform.volume+rank);
			channel.soundTransform = transform;
		}
	}
}