package;

import GlitchShader.Fuck;
import openfl.filters.ShaderFilter;
import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.effects.FlxFlicker;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxGlitchEffect;
import flixel.addons.plugin.screengrab.FlxScreenGrab;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import openfl.filters.ShaderFilter;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import GlitchShader.GlitchShaderA;
import GlitchShader.GlitchShaderB;
import shaders.*;
#if sys
import sys.FileSystem;
#end
import SonicNumber.SonicNumberDisplay;
import flixel.tweens.FlxTween.FlxTweenManager;
using StringTools;

// used to save checkpoint data in songs w/ checkpoints!!
// this is so when you die, it goes back to the checkpoint and I dont have 50 different variables for checkpoint stuff, just 1 typedef!
typedef CheckpointData = {
	var time:Float;
	var score:Int;
	var combo:Int;
	var hits:Int;
	var totalPlayed:Int;
	var misses:Int;
	var sicks:Int;
	var goods:Int;
	var bads:Int;
	var shits:Int;
	var health:Float;

}

class PlayState extends MusicBeatState
{
	var targetHP:Float = 1;

	var noteRows:Array<Array<Array<Note>>> = [[],[],[]];

	var camGlitchShader:GlitchShaderB;
	var camFuckShader:Fuck;
	var camGlitchFilter:BitmapFilter;
	var camFuckFilter:BitmapFilter;

	var barrelDistortionShader:BarrelDistortionShader;
	var barrelDistortionFilter:BitmapFilter;
	var jigglyOiledUpBlackMen:WiggleEffect;
	var glitchinTime:Bool = false;

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Shit', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];

	public var piss:Array<FlxTween> = [];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;
	
	public var dadGhostTween:FlxTween = null;
	public var bfGhostTween:FlxTween = null;
	public var dadGhost:FlxSprite = null; // Come out come out wherever you are!
	public var bfGhost:FlxSprite = null; // Just kidding, I already found you!
	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;
	public var healthBarOver:FlxSprite;
	var songPercent:Float = 0;
	var fakeSongPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	public var fakeTimeBar:FlxBar;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camGame2:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var songNameHUD:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;
	var barSongLength:Float = 0; // hi neb i like ur code g :D
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	// HUD
	// TODO: diff HUD designs
	var isPixelHUD:Bool = false;
	var chaotixHUD:FlxSpriteGroup;

	var fcLabel:FlxSprite;
	var ringsLabel:FlxSprite;
	var hudDisplays:Map<String, SonicNumberDisplay> = [];
	var hudStyle:Map<String, String> = [
		"my-horizon" => "chaotix",
		"our-horizon" => "chaotix",
		"soulless-endeavors" => "chaotix",
		"long-sky" => "chotix"
	];
	// for the time counter
	var hudMinute:SonicNumber;
	var hudSeconds:SonicNumberDisplay;
	var hudMS:SonicNumberDisplay;
	//intro stuff
	var startCircle:FlxSprite;
	var startText:FlxSprite;
	var blackFuck:FlxSprite;
	var whiteFuck:FlxSprite;
	var whiteFuckDos:FlxSprite;
	var redFuck:FlxSprite;
	// chaotix shit
	// I AM WECHINDAAAAAAAAAA

	var vistaBG:FlxSprite;
	var vistaFloor:FlxSprite;
	var vistaGrass:FlxSprite;
	var vistaBush:FlxSprite;
	var vistaTree:FlxSprite;
	var vistaFlower:FlxSprite;

	var amyBop:FlxSprite;
	var charmyBop:FlxSprite;
	var espioBop:FlxSprite;
	var knuxBop:FlxSprite;
	var mightyBop:FlxSprite;
	var vectorBop:FlxSprite;
	// fucked mode!
	var fuckedBG:FlxSprite;
	var fuckedFloor:FlxSprite;
	var fuckedGrass:FlxSprite;
	var fuckedBush:FlxSprite;
	var fuckedTree:FlxSprite;
	var fuckedFlower:FlxSprite;
	var fuckedTails:FlxSprite;
	private var finalStretchTrail:FlxTrail;

	var amyBopFucked:FlxSprite;
	var charmyBopFucked:FlxSprite;
	var espioBopFucked:FlxSprite;
	var knuxBopFucked:FlxSprite;
	var mightyBopFucked:FlxSprite;
	var vectorBopFucked:FlxSprite;

	var fucklesBeats:Bool = true;
	var fuckedBar:Bool = false;
	// fuckles
	public var fucklesDrain:Float = 0;
	public var fucklesMode:Bool = false;
	public var drainMisses:Float = 0; // EEE OOO EH OO EE AAAAAAAAA
	// glad my comment above stayed lmao -neb
	//general stuff (statics n shit...)
	var theStatic:FlxSprite;  //THE FUNNY THE FUNNY!!!!
	var staticlol:StaticShader;
	var staticlmao:StaticShader;
	var staticOverlay:ShaderFilter;
	var glitchThingy:DistortGlitchShader;
	var glitchOverlay:ShaderFilter;
	private var staticAlpha:Float = 1;

	//duke shit
	//entrance (ee oo ayy eh)
	var entranceBG:FlxSprite;
	var entranceOver:FlxSprite;
	var entranceClock:FlxSprite;
	var entranceFloor:FlxSprite;
	var entranceIdk:FlxSprite;
	// spooky shit
	var entranceSpookyBG:FlxSprite;
	var entranceSpookyOver:FlxSprite;
	var entranceSpookyClock:FlxSprite;
	var entranceSpookyFloor:FlxSprite;
	var entranceSpookyIdk:FlxSprite;
	//soulless endevors (ee oo ayy eh)
	var soulSky:FlxSprite;
	var soulBalls:FlxSprite; 
	//Hahahaha its balls, get it
	var soulRocks:FlxSprite;
	var soulKai:FlxSprite;
	var soulFrontRocks:FlxSprite;
	var soulPixelBg:FlxSprite;
	var soulPixelBgBg:FlxSprite;
	//final frontier

	// aughhhhhhhhhhhhhhhh
	var hellBg:FlxSprite;
	// - healthbar based things for mechanic use (like my horizon lol)
	var healthMultiplier:Float = 1; // fnf
	var healthDrop:Float = 0;
	var dropTime:Float = 0;
	// - camera bullshit
	var dadCamThing:Array<Int> = [0, 0];
	var bfCamThing:Array<Int> = [0, 0];
	var cameramove:Bool = FlxG.save.data.cammove;
	//zoom bullshit
	public var wowZoomin:Bool = false;
	public var holyFuckStopZoomin:Bool = false;
	public var pleaseStopZoomin:Bool = false;
	public var ohGodTheZooms:Bool = false;
	//anim controller
	var animController:Bool = true;

	var scoreRandom:Bool = false;

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		blackFuck = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		startCircle = new FlxSprite();
		startText = new FlxSprite();

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camGame2 = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camGame2.bgColor.alpha = 0;
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camGame2);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		//trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'entrance':

				GameOverSubstate.characterName = 'bfii-death';

				defaultCamZoom = 0.65;

				camGlitchShader = new GlitchShaderB();
				camGlitchShader.iResolution.value = [FlxG.width, FlxG.height];
				camGlitchFilter = new ShaderFilter(camGlitchShader);

				camFuckShader = new Fuck();
				camFuckFilter = new ShaderFilter(camFuckShader);

				barrelDistortionShader = new BarrelDistortionShader();
				barrelDistortionFilter = new ShaderFilter(barrelDistortionShader);

				entranceBG = new FlxSprite(-325, -50);
				entranceBG.loadGraphic(Paths.image('entrance/bg', 'exe'));
				entranceBG.scrollFactor.set(0.6, 1);
				entranceBG.scale.set(1.1, 1.1);
				entranceBG.antialiasing = true;

				entranceClock = new FlxSprite(-450, -50);
				entranceClock.loadGraphic(Paths.image('entrance/clock', 'exe'));
				entranceClock.scrollFactor.set(0.8, 1);
				entranceClock.scale.set(1.1, 1.1);
				entranceClock.antialiasing = true;

				entranceIdk = new FlxSprite(-355, -50);
				entranceIdk.loadGraphic(Paths.image('entrance/idk', 'exe'));
				entranceIdk.scrollFactor.set(0.7, 1);
				entranceIdk.scale.set(1.1, 1.1);
				entranceIdk.antialiasing = true;

				entranceFloor = new FlxSprite(-375, -50);
				entranceFloor.loadGraphic(Paths.image('entrance/floor', 'exe'));
				entranceFloor.scrollFactor.set(1, 1);
				entranceFloor.scale.set(1.1, 1.1);
				entranceFloor.antialiasing = true;

				entranceOver = new FlxSprite(-325, -125);
				entranceOver.loadGraphic(Paths.image('entrance/over', 'exe'));
				entranceOver.scrollFactor.set(1.05, 1);
				entranceOver.scale.set(1.1, 1.1);
				entranceOver.antialiasing = true;

				//-- haha fuck you im hardcoding the stages!!!!!!!!

				entranceSpookyBG = new FlxSprite(-325, -50);
				entranceSpookyBG.loadGraphic(Paths.image('entrance/scary/bg2', 'exe'));
				entranceSpookyBG.scrollFactor.set(0.6, 1);
				entranceSpookyBG.scale.set(1.1, 1.1);
				entranceSpookyBG.antialiasing = true;
				entranceSpookyBG.visible = false;

				entranceSpookyClock = new FlxSprite(-450, -50);
				entranceSpookyClock.loadGraphic(Paths.image('entrance/scary/clock2', 'exe'));
				entranceSpookyClock.scrollFactor.set(0.8, 1);
				entranceSpookyClock.scale.set(1.1, 1.1);
				entranceSpookyClock.antialiasing = true;
				entranceSpookyClock.visible = false;

				entranceSpookyIdk = new FlxSprite(-355, -50);
				entranceSpookyIdk.loadGraphic(Paths.image('entrance/scary/idk2', 'exe'));
				entranceSpookyIdk.scrollFactor.set(0.7, 1);
				entranceSpookyIdk.scale.set(1.1, 1.1);
				entranceSpookyIdk.antialiasing = true;
				entranceSpookyIdk.visible = false;

				entranceSpookyFloor = new FlxSprite(-375, -50);
				entranceSpookyFloor.loadGraphic(Paths.image('entrance/scary/floor2', 'exe'));
				entranceSpookyFloor.scrollFactor.set(1, 1);
				entranceSpookyFloor.scale.set(1.1, 1.1);
				entranceSpookyFloor.antialiasing = true;
				entranceSpookyFloor.visible = false;

				entranceSpookyOver = new FlxSprite(-325, -125);
				entranceSpookyOver.loadGraphic(Paths.image('entrance/scary/over2', 'exe'));
				entranceSpookyOver.scrollFactor.set(1.05, 1);
				entranceSpookyOver.scale.set(1.1, 1.1);
				entranceSpookyOver.antialiasing = true;
				entranceSpookyOver.visible = false;

				add(entranceSpookyBG);
				add(entranceSpookyIdk);
				add(entranceSpookyClock);
				add(entranceSpookyFloor);
				
				add(entranceBG);
				add(entranceIdk);
				add(entranceClock);
				add(entranceFloor);

			case 'soulless':
				GameOverSubstate.characterName = 'bfii-death';

				defaultCamZoom = 0.68;

				soulSky = new FlxSprite(-246, -239);
				soulSky.loadGraphic(Paths.image('soulless/sky', 'exe'));
				soulSky.scrollFactor.set(0.3, 0.3);
				soulSky.scale.set(1, 1);
				soulSky.antialiasing = true;
				add(soulSky);

				soulBalls = new FlxSprite(-246, -239);
				soulBalls.loadGraphic(Paths.image('soulless/balls', 'exe'));
				soulBalls.scrollFactor.set(0.5, 0.5);
				soulBalls.scale.set(1, 1);
				soulBalls.antialiasing = true;
				add(soulBalls);

				soulRocks = new FlxSprite(-366, -239);
				soulRocks.loadGraphic(Paths.image('soulless/rocks', 'exe'));
				soulRocks.scrollFactor.set(0.7, 0.7);
				soulRocks.scale.set(1, 1);
				soulRocks.antialiasing = true;
				add(soulRocks);

				soulKai = new FlxSprite(-366, -239);
				soulKai.loadGraphic(Paths.image('soulless/metal', 'exe'));
				soulKai.scrollFactor.set(0.9, 0.9);
				soulKai.scale.set(1, 1);
				soulKai.antialiasing = true;
				add(soulKai);

				soulFrontRocks = new FlxSprite(-246, -239);
				soulFrontRocks.loadGraphic(Paths.image('soulless/rocksFront', 'exe'));
				soulFrontRocks.scrollFactor.set(1.0, 1.0);
				soulFrontRocks.scale.set(1.2, 1.2);
				soulFrontRocks.antialiasing = true;
				add(soulFrontRocks);

				//the actual bg
				soulPixelBgBg = new FlxSprite(300, 150);
				soulPixelBgBg.loadGraphic(Paths.image('soulless/pixelbg', 'exe'));
				soulPixelBgBg.scrollFactor.set(1, 1);
				soulPixelBgBg.antialiasing = false;
				soulPixelBgBg.scale.set(4, 4);
				soulPixelBgBg.visible = false;
				add(soulPixelBgBg);

				//THE FUNNY!!! THE FU
				soulPixelBg = new FlxSprite(300, 150);
				soulPixelBg.frames = Paths.getSparrowAtlas('soulless/stage_running', 'exe');
				soulPixelBg.animation.addByPrefix('idle', 'stage', 24, true);
				soulPixelBg.animation.play('idle');
				soulPixelBg.scrollFactor.set(1, 1);
				soulPixelBg.antialiasing = false;
				soulPixelBg.scale.set(4, 4);
				soulPixelBg.visible = false;
				add(soulPixelBg);


			case 'vista':
				// lol

				camGlitchShader = new GlitchShaderB();
				camGlitchShader.iResolution.value = [FlxG.width, FlxG.height];
				camGlitchFilter = new ShaderFilter(camGlitchShader);

				staticlol = new StaticShader();
				staticOverlay = new ShaderFilter(staticlol);
				staticlol.iTime.value = [0];
				staticlol.iResolution.value = [FlxG.width, FlxG.height];
				staticlol.alpha.value = [staticAlpha];
				staticlol.enabled.value = [false];

				camFuckShader = new Fuck();
				camFuckFilter = new ShaderFilter(camFuckShader);

				camGame.setFilters([staticOverlay, camFuckFilter]);

				GameOverSubstate.characterName = 'bfii-death';
				defaultCamZoom = 0.6;

				vistaBG = new FlxSprite(-450, -250);
				vistaBG.loadGraphic(Paths.image('chaotix/vistaBg', 'exe'));
				vistaBG.scrollFactor.set(0.6, 1);
				vistaBG.scale.set(1.1, 1.1);
				vistaBG.antialiasing = true;
				add(vistaBG);

				vistaFloor = new FlxSprite(-460, -230);
				vistaFloor.loadGraphic(Paths.image('chaotix/vistaFloor', 'exe'));
				vistaFloor.scrollFactor.set(1, 1);
				vistaFloor.scale.set(1.1, 1.1);
				vistaFloor.antialiasing = true;
				add(vistaFloor);

				vistaGrass = new FlxSprite(-460, -230);
				vistaGrass.loadGraphic(Paths.image('chaotix/vistaGrass', 'exe'));
				vistaGrass.scrollFactor.set(1, 1);
				vistaGrass.scale.set(1.1, 1.1);
				vistaGrass.antialiasing = true;
				add(vistaGrass);

				vistaBush = new FlxSprite(-460, -230);
				vistaBush.loadGraphic(Paths.image('chaotix/vistaBush', 'exe'));
				vistaBush.scrollFactor.set(0.9, 1);
				vistaBush.scale.set(1.1, 1.1);
				vistaBush.antialiasing = true;
				add(vistaBush);

				vistaTree = new FlxSprite(-460, -230);
				vistaTree.loadGraphic(Paths.image('chaotix/vistaTree', 'exe'));
				vistaTree.scrollFactor.set(0.9, 1);
				vistaTree.scale.set(1.1, 1.1);
				vistaTree.antialiasing = true;
				add(vistaTree);

				vistaFlower = new FlxSprite(-460, -230);
				vistaFlower.loadGraphic(Paths.image('chaotix/vistaFlower', 'exe'));
				vistaFlower.scrollFactor.set(0.9, 1);
				vistaFlower.scale.set(1.1, 1.1);
				vistaFlower.antialiasing = true;
				add(vistaFlower);

				amyBop = new FlxSprite(-150, 530);
				amyBop.frames = Paths.getSparrowAtlas('chaotix/bop/AmyBop', 'exe');
				amyBop.animation.addByPrefix('idle', 'AmyBop', 24, false);
				amyBop.scrollFactor.set(1, 1);
				amyBop.scale.set(1.0, 1.0);
				amyBop.antialiasing = true;

				charmyBop = new FlxSprite(900, 0);
				charmyBop.frames = Paths.getSparrowAtlas('chaotix/bop/CharmyBop', 'exe');
				charmyBop.animation.addByPrefix('danceLeft', 'CharmyBopLeft', 24, false);
				charmyBop.animation.addByPrefix('danceRight', 'CharmyBopRight', 24, false);
				charmyBop.scrollFactor.set(1, 1);
				charmyBop.scale.set(1.0, 1.0);
				charmyBop.antialiasing = true;
				add(charmyBop);

				vectorBop = new FlxSprite(1300, 80);
				vectorBop.frames = Paths.getSparrowAtlas('chaotix/bop/VectorBop', 'exe');
				vectorBop.animation.addByPrefix('idle', 'VectorBop', 24, false);
				vectorBop.scrollFactor.set(1, 1);
				vectorBop.scale.set(0.9, 0.9);
				vectorBop.antialiasing = true;
				add(vectorBop);

				espioBop = new FlxSprite(1800, 250);
				espioBop.frames = Paths.getSparrowAtlas('chaotix/bop/EspioBop', 'exe');
				espioBop.animation.addByPrefix('idle', 'EspioBop', 24, false);
				espioBop.scrollFactor.set(1, 1);
				espioBop.scale.set(1.0, 1.0);
				espioBop.antialiasing = true;
				add(espioBop);

				mightyBop = new FlxSprite(-350, 200);
				mightyBop.frames = Paths.getSparrowAtlas('chaotix/bop/MightyBop', 'exe');
				mightyBop.animation.addByPrefix('idle', 'MIGHTYBOP', 24, false);
				mightyBop.scrollFactor.set(1, 1);
				mightyBop.scale.set(1.0, 1.0);
				mightyBop.antialiasing = true;
				add(mightyBop);

				knuxBop = new FlxSprite(-600, 250);
				knuxBop.frames = Paths.getSparrowAtlas('chaotix/bop/KnuxBop', 'exe');
				knuxBop.animation.addByPrefix('idle', 'KNUXBOP', 24, false);
				knuxBop.scrollFactor.set(1, 1);
				knuxBop.scale.set(1.0, 1.0);
				knuxBop.antialiasing = true;	
				add(knuxBop);




				//the funny for the transformo shtuff

				whiteFuck = new FlxSprite(-800, -200).makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.BLACK);
				whiteFuck.alpha = 0;
				add(whiteFuck);

				redFuck = new FlxSprite(-800, -200).makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.RED);
				redFuck.alpha = 0;
				add(redFuck);

				whiteFuckDos = new FlxSprite(-800, -200).makeGraphic(FlxG.width * 6, FlxG.height * 6, FlxColor.WHITE);
				whiteFuckDos.alpha = 0;
				add(whiteFuckDos);

				//fucked mode achieved

				fuckedBG = new FlxSprite(-450, -250);
				fuckedBG.loadGraphic(Paths.image('chaotix/fucked/fuckedBg', 'exe'));
				fuckedBG.scrollFactor.set(0.6, 1);
				fuckedBG.scale.set(1.1, 1.1);
				fuckedBG.antialiasing = true;
				add(fuckedBG);

				fuckedFloor = new FlxSprite(-460, -250);
				fuckedFloor.loadGraphic(Paths.image('chaotix/fucked/fuckedFloor', 'exe'));
				fuckedFloor.scrollFactor.set(1, 1);
				fuckedFloor.scale.set(1.2, 1.2);
				fuckedFloor.antialiasing = true;
				add(fuckedFloor);

				fuckedGrass = new FlxSprite(-550, -220);
				fuckedGrass.loadGraphic(Paths.image('chaotix/fucked/fuckedGrass', 'exe'));
				fuckedGrass.scrollFactor.set(1, 1);
				fuckedGrass.scale.set(1.2, 1.2);
				fuckedGrass.antialiasing = true;
				add(fuckedGrass);

				fuckedTree = new FlxSprite(-460, -220);
				fuckedTree.loadGraphic(Paths.image('chaotix/fucked/fuckedTrees', 'exe'));
				fuckedTree.scrollFactor.set(1, 1);
				fuckedTree.scale.set(1.1, 1.1);
				fuckedTree.antialiasing = true;
				add(fuckedTree);

				fuckedBush = new FlxSprite(-460, -220);
				fuckedBush.loadGraphic(Paths.image('chaotix/fucked/fuckedBush', 'exe'));
				fuckedBush.scrollFactor.set(1, 1);
				fuckedBush.scale.set(1.1, 1.1);
				fuckedBush.antialiasing = true;
				add(fuckedBush);

				fuckedFlower = new FlxSprite(-460, -220);
				fuckedFlower.loadGraphic(Paths.image('chaotix/fucked/fuckedFlower', 'exe'));
				fuckedFlower.scrollFactor.set(1, 1);
				fuckedFlower.scale.set(1.1, 1.1);
				fuckedFlower.antialiasing = true;
				add(fuckedFlower);

				fuckedTails = new FlxSprite(-460, -230);
				fuckedTails.loadGraphic(Paths.image('chaotix/fucked/fuckedTails', 'exe'));
				fuckedTails.scrollFactor.set(0.9, 1);
				fuckedTails.scale.set(1.1, 1.1);
				fuckedTails.antialiasing = true;
				add(fuckedTails);

				amyBopFucked = new FlxSprite(-800, 150);
				amyBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/AmyScared', 'exe');
				amyBopFucked.animation.addByPrefix('idle', 'AmyScared instance 1', 24, false);
				amyBopFucked.scrollFactor.set(1, 1);
				amyBopFucked.scale.set(1.0, 1.0);
				amyBopFucked.antialiasing = true;
				add(amyBopFucked);

				charmyBopFucked = new FlxSprite(1800, 0);
				charmyBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/CharmyScared', 'exe');
				charmyBopFucked.animation.addByPrefix('danceLeft', 'CharmyScaredBop instance 1', 24, false);
				charmyBopFucked.scrollFactor.set(1, 1);
				charmyBopFucked.scale.set(1.0, 1.0);
				charmyBopFucked.antialiasing = true;
				add(charmyBopFucked);

				vectorBopFucked = new FlxSprite(1300, 120);
				vectorBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/VectorScared', 'exe');
				vectorBopFucked.animation.addByPrefix('idle', 'VectorScaredBop instance 1', 24, false);
				vectorBopFucked.scrollFactor.set(1, 1);
				vectorBopFucked.scale.set(1.0, 1.0);
				vectorBopFucked.antialiasing = true;
				add(vectorBopFucked);

				espioBopFucked = new FlxSprite(1750, 400);
				espioBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/EspioScared', 'exe');
				espioBopFucked.animation.addByPrefix('idle', 'EspioScaredBop instance 1', 24, false);
				espioBopFucked.scrollFactor.set(0.9, 0.9);
				espioBopFucked.scale.set(1.0, 1.0);
				espioBopFucked.antialiasing = true;
				add(espioBopFucked);

				mightyBopFucked = new FlxSprite(-150, 200);
				mightyBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/MightyScared', 'exe');
				mightyBopFucked.animation.addByPrefix('idle', 'MightyScaredBop instance 1', 24, false);
				mightyBopFucked.scrollFactor.set(1, 1);
				mightyBopFucked.scale.set(0.9, 0.9);
				mightyBopFucked.antialiasing = true;
				add(mightyBopFucked);

				knuxBopFucked = new FlxSprite(-700, 340);
				knuxBopFucked.frames = Paths.getSparrowAtlas('chaotix/bopscared/KnuxScared', 'exe');
				knuxBopFucked.animation.addByPrefix('idle', 'KnuxScaredBop instance 1', 24, false);
				knuxBopFucked.scrollFactor.set(1, 1);
				knuxBopFucked.scale.set(0.9, 0.9);
				knuxBopFucked.antialiasing = true;


				fuckedBG.visible = false;
				fuckedFloor.visible = false;
				fuckedGrass.visible = false;
				fuckedBush.visible = false;
				fuckedTree.visible = false;
				fuckedFlower.visible = false;
				fuckedTails.visible = false;

				amyBopFucked.visible = false;
				charmyBopFucked.visible = false;
				vectorBopFucked.visible = false;
				espioBopFucked.visible = false;
				mightyBopFucked.visible = false;
				knuxBopFucked.visible = false;

			case 'chotix':
				{

					GameOverSubstate.characterName = 'bfii-death';
					defaultCamZoom = 0.6;

					hellBg = new FlxSprite(-400, 0);
					hellBg.loadGraphic(Paths.image('chaotix/hell', 'exe'));
					hellBg.scrollFactor.set(1, 1);
					hellBg.scale.set(1.5, 1.5);
					hellBg.antialiasing = false;
					add(hellBg);
				}

			default: //lol
				GameOverSubstate.characterName = 'bfii-death';

				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}
		}

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}

		dadGhost = new FlxSprite();


		bfGhost = new FlxSprite();


		add(gfGroup); //Needed for blammed lights

		add(bfGhost);
		add(dadGhost);

		add(dadGroup);
		add(boyfriendGroup);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end


		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
			luaArray.push(new FunkinLua(luaFile));
		#end


		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);


		dadGhost.visible = false;
		dadGhost.antialiasing = true;
		dadGhost.alpha = 0.6;
		dadGhost.scale.copyFrom(dad.scale);
		dadGhost.updateHitbox();
		bfGhost.visible = false;
		bfGhost.antialiasing = true;
		bfGhost.alpha = 0.6;
		bfGhost.scale.copyFrom(boyfriend.scale);
		bfGhost.updateHitbox();
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		theStatic = new FlxSprite(0, 0);
		theStatic.frames = Paths.getSparrowAtlas('staticc', 'exe');
		theStatic.animation.addByPrefix('stat', "staticc", 24, true);
		theStatic.animation.play('stat');
		theStatic.cameras = [camOther];
		theStatic.setGraphicSize(FlxG.width, FlxG.height);
		theStatic.screenCenter();

		switch(curStage)
		{
			case 'entrance':
				add(entranceSpookyOver);
				add(entranceOver);

				gfGroup.visible = false;
				dad.y += 200;
				boyfriend.x += 275;
				boyfriend.y += 235;
				theStatic.visible = false;
				add(theStatic);
			
			//fml bruv raz is such a mEANIE
				case 'soulless':
				//add(soulFog);
				gfGroup.visible = false;
				
				dad.x += 100;
				boyfriend.x += 220;
				boyfriend.y += 45;

				dadGroup.visible = true;
				boyfriendGroup.visible = true;
				theStatic.visible = false;
				add(theStatic);

			case 'vista':
				gf.x += 150;
				gf.y += 50;
				boyfriend.y += 80;
				boyfriend.x += 200;
				add(amyBop);
				add(knuxBopFucked);
			case 'chotix':
				gf.y -= 50;
				//dad.setPosition(-500, 350);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("chaotix.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;

		fakeTimeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'fakeSongPercent', 0, 100);
		fakeTimeBar.scrollFactor.set();
		fakeTimeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		fakeTimeBar.numDivisions = 1000;
		fakeTimeBar.visible = showTime;

		/*if (!isPixelHUD)
			{
				add(timeBarBG);
				add(timeBar);
				add(timeTxt);
			}*/
		add(timeBarBG);
		add(timeBar);
		add(timeTxt);

		timeBarBG.sprTracker = timeBar;


		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();


		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);


		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		camGame2.follow(camFollowPos, LOCKON, 1);
		camGame2.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.visible = !ClientPrefs.hideHud;
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'targetHP', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = ClientPrefs.healthBarAlpha;
		add(healthBar);
		healthBarBG.sprTracker = healthBar;

		healthBarOver = new FlxSprite().loadGraphic(Paths.image("healthBarOver"));
		healthBarOver.scrollFactor.set();
		healthBarOver.visible = !ClientPrefs.hideHud;
		healthBarOver.alpha = ClientPrefs.healthBarAlpha;
		add(healthBarOver);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		scoreTxt.setFormat(Paths.font("chaotix.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = false;
		/*if (!isPixelHUD)
		{
		}*/
		add(scoreTxt);

		songNameHUD = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
		songNameHUD.setFormat(Paths.font("chaotix.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songNameHUD.scrollFactor.set();
		songNameHUD.borderSize = 1.25;
		songNameHUD.visible = !ClientPrefs.hideHud;
		add(songNameHUD);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("chaotix.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		// create the custom hud
		trace(curSong.toLowerCase());
		if(hudStyle.exists(curSong.toLowerCase())){
			chaotixHUD = new FlxSpriteGroup(33, 0);
			var labels:Array<String> = [
				"score",
				"time",
				"misses"
			];
			var scale:Float = 3;
			var style:String = hudStyle.get(curSong.toLowerCase());
			switch(style) {
				case 'chotix':
					scale = 0.75;
			}

			for(i in 0...labels.length) {
				var name = labels[i];
				var y = 48 * (i+1);
				var label = new FlxSprite(0, y);
				switch(name){
					case 'rings':
						label.loadGraphic(Paths.image('sonicUI/$style/$name'), true, 83, 12);
						label.animation.add("blink", [0, 1], 2);
						label.animation.add("static", [0], 0);
					case 'fullcombo':
						label.loadGraphic(Paths.image('sonicUI/$style/$name'), true, 83, 12);
						label.animation.add("blink", [0, 1], 2);
					default:
						label.loadGraphic(Paths.image('sonicUI/$style/$name'));
				}

				label.setGraphicSize(Std.int(label.width * scale));
				label.updateHitbox();
				label.antialiasing=false;
				label.scrollFactor.set();
				chaotixHUD.add(label);
				var hasDisplay:Bool = false;
				var displayCount:Int = 0;
				var displayX:Float = 150;
				var dispVar:String = '';
				switch(name) {
					case 'rings':
						hasDisplay = true;
						displayCount = 3;
						displayX = 174;
						label.animation.play("blink", true);
						ringsLabel = label;
					case 'score':
						hasDisplay = true;
						displayCount = 7;
						dispVar = 'songScore';
					case 'fullcombo':
						hasDisplay = false;
						//fcLabel = label;
						label.animation.play("blink", true);
					case 'fc':
						hasDisplay = false;
						fcLabel = label;
						label.animation.play("SFC", true);
					case 'time':
						hasDisplay = false;
						hudMinute = new SonicNumber(150, y + (3 * scale), '0', style);
						hudMinute.setGraphicSize(Std.int(hudMinute.width * scale));
						hudMinute.updateHitbox();

						hudSeconds = new SonicNumberDisplay(198, y + (3 * scale), 2, scale, 0, style);
						hudMS = new SonicNumberDisplay(270, y + (3 * scale), 2, scale, 0, style);
						if(style=='chotix') {
							hudSeconds.x = 270;
							hudMS.x = 198;
							hudSeconds.blankCharacter = 'sex';
							hudMS.blankCharacter = 'sex';
						} else {
							hudSeconds.blankCharacter = '0';
							hudMS.blankCharacter = '0';
						}



						var singleQuote = new FlxSprite(171, y).loadGraphic(Paths.image('sonicUI/$style/colon'));
						singleQuote.setGraphicSize(Std.int(singleQuote.width * scale));
						singleQuote.updateHitbox();
						singleQuote.antialiasing=false;
						var doubleQuote = new FlxSprite(243, y).loadGraphic(Paths.image('sonicUI/$style/quote'));
						doubleQuote.setGraphicSize(Std.int(doubleQuote.width * scale));
						doubleQuote.updateHitbox();
						doubleQuote.antialiasing=false;

						singleQuote.x = 171;
						doubleQuote.x = 243;
						singleQuote.y = y;
						doubleQuote.y = y;

						chaotixHUD.add(singleQuote);
						chaotixHUD.add(doubleQuote);
						chaotixHUD.add(hudMinute);
						chaotixHUD.add(hudSeconds);
						chaotixHUD.add(hudMS);
					case 'misses':
						hasDisplay = true;
						displayCount = 3;
						displayX = 174;
						dispVar = 'songMisses';
						fcLabel = new FlxSprite(174 + ((8 * 3) * (displayCount+1)), y);
						fcLabel.loadGraphic(Paths.image('sonicUI/$style/fc'));
						fcLabel.loadGraphic(Paths.image('sonicUI/$style/fc'), true, Std.int(fcLabel.width/4), Std.int(fcLabel.height/2));
						fcLabel.animation.add("SFC", [0, 4], 0);
						fcLabel.animation.add("GFC", [1, 5], 0);
						fcLabel.animation.add("FC", [2, 6], 0);
						fcLabel.animation.add("SDCB", [3, 7], 0);
						fcLabel.setGraphicSize(Std.int(fcLabel.width * scale));
						fcLabel.updateHitbox();
						fcLabel.antialiasing=false;
						fcLabel.scrollFactor.set();
						fcLabel.animation.play("SFC", true);
						chaotixHUD.add(fcLabel);
				}
				if(hasDisplay) {
					var dis:SonicNumberDisplay = new SonicNumberDisplay(displayX, y + (3 * scale), displayCount, scale, 0, style, this, dispVar);
					hudDisplays.set(name, dis);
					chaotixHUD.add(dis);
				}
			}

			add(chaotixHUD);

			if(!ClientPrefs.downScroll) {
				for(member in chaotixHUD.members)
					member.y = (FlxG.height-member.height-member.y);
			}
			chaotixHUD.cameras = [camHUD];

			if(SONG.song.toLowerCase()=='soulless-endeavors')
				chaotixHUD.visible = false;
			
		}

		if(chaotixHUD!=null && chaotixHUD.visible) {
			healthBar.x += 150;
			iconP1.x = 1000;
			iconP2.x = 400;
			healthBarBG.x += 150;
			remove(scoreTxt);
			remove(songNameHUD);
			remove(fakeTimeBar);
			remove(timeBar);
			remove(timeBarBG);
			remove(timeTxt);
		}
		else {
			iconP1.x = 850;
		iconP2.x = 250;
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarOver.cameras = [camHUD];
		songNameHUD.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		fakeTimeBar.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];

		startCircle.cameras = [camOther];
		startText.cameras = [camOther];
		blackFuck.cameras = [camOther];

		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end


		var daSong:String = Paths.formatToSongPath(curSong);
	
		switch (daSong)
		{
			case  'breakout' | 'soulless-endeavors' | 'long-sky':
				add(blackFuck);
				startCircle.loadGraphic(Paths.image('openings/' + daSong + '_title_card', 'exe'));
				startCircle.frames = Paths.getSparrowAtlas('openings/' + daSong + '_title_card', 'exe');
				startCircle.animation.addByPrefix('idle', daSong + '_title', 24, false);
				if (daSong == 'breakout')
					startCircle.scale.set(2, 1.5);
				//startCircle.setGraphicSize(Std.int(startCircle.width * 0.6));
				startCircle.alpha = 0;
				startCircle.screenCenter();
				add(startCircle);

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					FlxTween.tween(startCircle, {alpha: 1}, 0.5, {ease: FlxEase.cubeInOut});
				});

				new FlxTimer().start(2.2, function(tmr:FlxTimer)
				{
					FlxTween.tween(blackFuck, {alpha: 0}, 2, {
						onComplete: function(twn:FlxTween)
						{
							remove(blackFuck);
							blackFuck.destroy();
							startCircle.animation.play('idle');
						}
					});
					FlxTween.tween(startCircle, {alpha: 1}, 4, {
						onComplete: function(twn:FlxTween)
						{
							remove(startCircle);
							startCircle.destroy();
						}
					});
				});
				new FlxTimer().start(0.3, function(tmr:FlxTimer)
				{
					startCountdown();
				});
				
			default:
				startCountdown();
		}
		
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) CoolUtil.precacheSound('hitsound');
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		if (PauseSubState.songName != null) {
			CoolUtil.precacheMusic(PauseSubState.songName);
		} else if(ClientPrefs.pauseMusic != 'None') {
			CoolUtil.precacheMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		super.create();

		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}


	var newIcon:String;


	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));

		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				startAndEnd();
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countDownSprites:Array<FlxSprite> = [];
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			/*if (isPixelHUD)
				{
					healthBar.x += 150;
					iconP1.x += 150;
					iconP2.x += 150;
					healthBarBG.x += 150;
				}
			else
				{
					//lol
				}*/

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (skipCountdown || startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 500);
				return;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
					bfCamThing = [0, 0];
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
					dadCamThing = [0, 0];
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				switch (swagCounter)
				{
					case 0:
					case 1:
						var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						ready.scrollFactor.set();
						ready.updateHitbox();

						if (PlayState.isPixelStage)
							ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

						ready.screenCenter();
						ready.antialiasing = antialias;
						countDownSprites.push(ready);
						FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(ready);
								remove(ready);
								ready.destroy();
							}
						});
					case 2:
						var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						set.scrollFactor.set();

						if (PlayState.isPixelStage)
							set.setGraphicSize(Std.int(set.width * daPixelZoom));

						set.screenCenter();
						set.antialiasing = antialias;
						countDownSprites.push(set);
						FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(set);
								remove(set);
								set.destroy();
							}
						});
					case 3:
						var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						go.scrollFactor.set();

						if (PlayState.isPixelStage)
							go.setGraphicSize(Std.int(go.width * daPixelZoom));

						go.updateHitbox();

						go.screenCenter();
						go.antialiasing = antialias;
						countDownSprites.push(go);
						FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								countDownSprites.remove(go);
								remove(go);
								go.destroy();
							}
						});
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.5;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.play();
		Conductor.songPosition = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		barSongLength = songLength;
		if(SONG.song.toLowerCase()=='breakout')
		{
			barSongLength = 89000;
		}

		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
			
				var pixelStage = isPixelStage;

				if(daStrumTime >= Conductor.stepToSeconds(640) && daStrumTime <= 123000 && SONG.song.toLowerCase()=='soulless-endeavors')
					isPixelStage = true;
				var gfNote = (section.gfSection && (songNotes[1]<4));
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.row = Conductor.secsToRow(daStrumTime);
				swagNote.gfNote = gfNote;
				swagNote.noteType = songNotes[3];
				
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];

				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts

				var idx = swagNote.gfNote?2:gottaHitNote?0:1;
				if (noteRows[idx][swagNote.row]==null)
					noteRows[idx][swagNote.row]=[];

				noteRows[idx][swagNote.row].push(swagNote);

				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = swagNote.gfNote;
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
				isPixelStage = pixelStage;
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}

			for (tween in piss)
			{
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (tween in piss) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;

			FlxTween.globalManager.forEach(function(tween:FlxTween)
				{
					tween.active = true;
				});
				FlxTimer.globalManager.forEach(function(timer:FlxTimer)
				{
					timer.active = true;
				});

			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var lastSection:Int = 0;
	var forFucksSake:Bool = false;

	override public function update(elapsed:Float)
	{
		if (camGame != null)
		{
			camGame2.zoom = camGame.zoom;
			camGame2.setPosition(camGame.x,camGame.y);
		}

		if (gray != null)
		gray.update(elapsed/4);

		if(staticlol!=null){
			staticlol.iTime.value[0] = Conductor.songPosition / 1000;
			staticlol.alpha.value = [staticAlpha];
		}
		if(staticlmao!=null){
			staticlmao.iTime.value[0] = Conductor.songPosition / 1000;
			staticlmao.alpha.value = [staticAlpha];
		}
		
		if(glitchThingy!=null){
			glitchThingy.iTime.value[0] = Conductor.songPosition / 1000;
		}

		if(camFuckShader!=null)
			camFuckShader.iTime.value[0] = Conductor.songPosition / 1000;
		
		if(camGlitchShader!=null){
			camGlitchShader.iResolution.value = [FlxG.width, FlxG.height];
			camGlitchShader.iTime.value[0] = Conductor.songPosition / 1000;
			if(camGlitchShader.amount>=1)camGlitchShader.amount=1;
		}
		for(shader in glitchShaders){
			shader.iTime.value[0] += elapsed;
		}

		if (glitchinTime) {
			if(dad.curCharacter.startsWith("chaotix-beast-unpixel"))
				camGlitchShader.amount = FlxMath.lerp(0.1, camGlitchShader.amount, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			else
				camGlitchShader.amount = FlxMath.lerp(0, camGlitchShader.amount, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		healthBarOver.x = healthBar.x - 4;
		healthBarOver.y = healthBar.y - 4.9;

		if (fucklesMode)
		{
			fucklesDrain = 0.00035; // copied from exe 2.0 lol sorry
			/*var reduceFactor:Float = combo / 150;
			if(reduceFactor>1)reduceFactor=1;
			reduceFactor = 1 - reduceFactor;
			health -= (fucklesDrain * (elapsed/(1/120))) * reduceFactor * drainMisses;*/
			if(drainMisses > 0)
				health -= (fucklesDrain * (elapsed/(1/120))) * drainMisses;
			else
				drainMisses = 0;
		}
		if(fucklesMode)
		{
			var newTarget:Float = FlxMath.lerp(targetHP, health, 0.1*(elapsed/(1/60)));
			if (Math.abs(newTarget - health)<.002)
				newTarget = health;

			targetHP = newTarget;
			
		} else
			targetHP = health;

		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{

		}

		if(scoreRandom){
			switch(FlxG.random.int(1, 15)) {
				case 1:
					songNameHUD + 'v1sT4';
				case 2:
					songNameHUD + '0vVVOu';
				case 3:
					songNameHUD + 'duKqfdcaXs';
				case 4:
					songNameHUD + 'iPpj5TMNW';
				case 5:
					songNameHUD + '5JH1Bg7gRQ';
				case 6:
					songNameHUD + 'Gkpo5g7vxm';
				case 7:
					songNameHUD + 'NUSmyXyoyH';
				case 8:
					songNameHUD + '1f5VmRWPXE';
				case 9:
					songNameHUD + 'MLioiJtZX4';
				case 10:
					songNameHUD + 'WPvSwx9e5d';
				case 11:
					songNameHUD + 'E0U0xZuJ8p';
				case 12:
					songNameHUD + 'd9f8cj1Rs3';
				case 13:
					songNameHUD + 'Gkpo5g7vxm';
				case 14:
					songNameHUD + 'ZLyE8jMV62';
				case 15:
					songNameHUD + '9j3fOVV9Sw';
				}
		} /*else {
			if(ratingName == '?') {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
			} else {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
			}
		}*/

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			var offX:Float = 0;
			var offY:Float = 0;
			var focus:Character = boyfriend;
			var curSection:Int = Math.floor(curStep / 16);
			if(SONG.notes[curSection]!=null){
				if (gf != null && SONG.notes[curSection].gfSection)
				{
					focus = gf;
				}else if (!SONG.notes[curSection].mustHitSection)
				{
					focus = dad;
				}
			}
			if(focus.animation.curAnim!=null){
				var name = focus.animation.curAnim.name;
				if(name.startsWith("singLEFT"))
					offX = -20;
				else if(name.startsWith("singRIGHT"))
					offX = 20;

				if(name.startsWith("singUP"))
					offY = -20;
				else if(name.startsWith("singDOWN"))
					offY = 20;
			}

			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x + offX, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y + offY, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause)
		{

			FlxTween.globalManager.forEach(function(tween:FlxTween)
			{
				tween.active = false;
			});

			FlxTimer.globalManager.forEach(function(timer:FlxTimer)
			{
				timer.active = false;
			});

			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}

				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene)
		{
			openChartEditor();
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;


		songNameHUD.text = SONG.song;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0)
					{
						switch (curSong)
						{
							case 'my-horizon':
								startSong();
							default:
								startSong();
						}
					}
				}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / barSongLength);

					var songCalc:Float = (barSongLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);

					if(chaotixHUD!=null) {
						var curMS:Float = Math.floor(curTime);
						var curSex:Int = Math.floor(curMS / 1000);
						if (curSex < 0)
							curSex = 0;

						var curMins = Math.floor(curSex / 60);
						curMS%=1000;
						curSex%=60;

						curMS = Math.round(curMS/10);
						var stringMins = Std.string(curMins).split("");
						if(curMins > 9) {
							hudMinute.number = '9';
							hudSeconds.displayed = 59;
							hudMS.displayed = 99;
						} else {
							hudMinute.number = stringMins[0];
							hudSeconds.displayed = curSex;
							hudMS.displayed = Std.int(curMS);
						}
					}



				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}



		if (camZooming)
		{
			var focus:Character = boyfriend;
			var curSection:Int = Math.floor(curStep / 16);
			if(SONG.notes[curSection]!=null) {
				if (gf != null && SONG.notes[curSection].gfSection)
				{
					focus = gf;
				} else if (!SONG.notes[curSection].mustHitSection)
				{
					focus = dad;
				}
			}

			switch (focus.curCharacter)
			{
				case "beast_chaotix":
					FlxG.camera.zoom = FlxMath.lerp(1.2, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				case "dukep3":
					FlxG.camera.zoom = FlxMath.lerp(0.9, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
				default:
					FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			}
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;

				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						}
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}

				var center:Float = strumY + Note.swagWidth / 2;
				if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}


	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (tween in piss) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {

			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}



			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case "Chaotix Health Randomization":

			var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 0;
				switch (value)
				{
					case 1:
						fucklesHealthRandomize();
						camHUD.shake(0.001, 1);
					case 2:
						fucklesFinale();
						camHUD.shake(0.003, 1);
	
				}
			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		var elapsed:Float = FlxG.elapsed;
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();

			switch (dad.curCharacter)
			{
				case "beast_chaotix":
					camFollow.x -= 30;
					camFollow.y -= 50;

				default:

			}
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			switch (boyfriend.curCharacter)
			{
				default:

			}

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		fakeTimeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				note.ratingMod = 0;
				score = 50;
				if(fucklesMode)
					drainMisses++;
				if(!note.ratingDisabled) shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				note.ratingMod = 0.5;
				score = 100;
				if(!note.ratingDisabled) bads++;
			case "good": // good
				totalNotesHit += 0.75;
				note.ratingMod = 0.75;
				score = 200;
				if(fucklesMode)
					drainMisses -= 1/50;
				if(!note.ratingDisabled) goods++;
			case "sick": // sick
				totalNotesHit += 1;
				note.ratingMod = 1;
				if(fucklesMode)
					drainMisses -= 1/25;
				if(!note.ratingDisabled) sicks++;
		}
		note.rating = daRating;

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		rating.visible = (!ClientPrefs.hideHud && showRating);
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});


			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}

						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		if (!fucklesMode)
		{
			health -= daNote.missHealth * healthLoss;
		}
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}
		if(fucklesMode)
			drainMisses++;

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;

		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		switch (daNote.noteType)
		{
			default:
				if (!fucklesMode)
					health -= daNote.missHealth;
				else
					drainMisses++;
		}

		if(char != null && char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong)
			{
				songMisses++;
				if (fucklesMode)
					drainMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}
	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			iconP2.scale.set(1.2, 1.2);

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			if(char != null)
			{
				char.holdTimer = 0;

				// TODO: maybe move this all away into a seperate function
				if (!note.isSustainNote
					&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row] != null
					&& noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row].length > 1)
				{
					// potentially have jump anims?
					var chord = noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row];
					var animNote = chord[0];
					var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + altAnim;
					if (char.mostRecentRow != note.row)
						char.playAnim(realAnim, true);

					if (note != animNote)
						char.playGhostAnim(chord.indexOf(note) - 1, animToPlay, true);

					char.mostRecentRow = note.row;
				}
				else
					char.playAnim(animToPlay, true);
				if (glitchinTime)
					if(!note.isSustainNote){
						if (camGlitchShader != null && char.curCharacter.startsWith('chaotix-beast-unpixel'))
							camGlitchShader.amount += 0.030;
					}
			}


		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;



		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}

				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			if (!fucklesMode)
				{
					health += note.hitHealth * healthGain;
				}

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + daAlt;

				var char:Character = boyfriend;
				if(note.gfNote)
				{
					if(gf != null)
						char = gf;
					
				}

				char.holdTimer = 0;
				
				if (!note.isSustainNote && noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row]!=null && noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row].length > 1)
				{
					// potentially have jump anims?
					var chord = noteRows[note.gfNote ? 2 : note.mustPress ? 0 : 1][note.row];
					var animNote = chord[0];
					var realAnim = singAnimations[Std.int(Math.abs(animNote.noteData))] + daAlt;
					if (char.mostRecentRow != note.row)
						char.playAnim(realAnim, true);
					

					if (note != animNote)
						char.playGhostAnim(chord.indexOf(note) - 1, animToPlay, true);

					char.mostRecentRow = note.row;
				}
				else
					char.playAnim(animToPlay, true);
				

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			iconP1.scale.set(1.2, 1.2);

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	var glitchShaders:Array<GlitchShaderA> = [];

	function glitchKill(spr:FlxSprite,dontKill:Bool=false){
		var shader = new GlitchShaderA();
		shader.iResolution.value = [spr.width, spr.height];
		piss.push(FlxTween.tween(shader, {amount: 1.25}, 2, {
			ease: FlxEase.cubeInOut,
			onComplete: function(tw: FlxTween){
				glitchShaders.remove(shader);
				spr.visible=false;
				if(!dontKill){
					remove(spr);
					spr.destroy();
				}
			}
		}));
		glitchShaders.push(shader);
		spr.shader = shader;
	}
	
	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var gray:GrayscaleShader;
	var distortion:DistortionShader;
	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20 || (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (curStep % 2 == 0 && pleaseStopZoomin)
		{
			FlxG.camera.zoom += 0.04;
			camHUD.zoom += 0.04;
		}

		if (curStep % 1 == 0 && ohGodTheZooms)
		{
			FlxG.camera.zoom += 0.02;
			camHUD.zoom += 0.02;
		}

		switch (SONG.song.toLowerCase())
		{
			case 'breakout':
			{
				switch (curStep)
				{
					case 736:
						FlxTween.tween(camHUD, {alpha: 0}, 3, {ease: FlxEase.cubeInOut});
						camZooming = false;
					case 768:
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.25}, 3, {ease: FlxEase.cubeInOut});
						camGame.setFilters([camGlitchFilter, barrelDistortionFilter]);
						camHUD.setFilters([camGlitchFilter, barrelDistortionFilter]);
					case 784:
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.75, barrelDistortion2: -0.5}, 1.5, {ease: FlxEase.quadInOut});
					case 800:
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0, barrelDistortion2: 0}, 0.35,{
							ease: FlxEase.quadInOut, onComplete: function(tw:FlxTween)
							{
								camGame.setFilters([]);
								camHUD.setFilters([]);
							}});
						iShouldKickUrFuckinAss(1);
						camZooming = true;
						holyFuckStopZoomin = true;
					case 1056:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
						holyFuckStopZoomin = false;
						wowZoomin = false;
					case 1312:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
					case 1568:
						FlxG.camera.flash(FlxColor.WHITE, 2);
						FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.cubeInOut});
						wowZoomin = false;
						camZooming = false;	
					case 1584:
						// :> 4axion was here!!!gdsjsgjsdjsdggs
						dad.cameras = [camGame2];
						boyfriend.animation.pause();
						gray = new GrayscaleShader();
						camGame.setFilters([new ShaderFilter(gray.shader)]);
					case 1736:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
						camGame.setFilters([barrelDistortionFilter]);
						camHUD.setFilters([barrelDistortionFilter]);
						dad.cameras = [camGame];
						gray = null;
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -1.0, barrelDistortion2: -0.5}, 0.75,
							{ease: FlxEase.quadInOut});
					case 1744:
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0.0, barrelDistortion2: 0.0}, 0.35, {
							ease: FlxEase.backOut,
							onComplete: function(tw:FlxTween)
							{
								camGame.setFilters([]);
								camHUD.setFilters([]);
							}
						});
						camZooming = true;
						holyFuckStopZoomin = true;
						camHUD.zoom += 2;
						FlxTween.tween(camHUD, {alpha: 1}, 1, {ease: FlxEase.cubeInOut});
					case 1870:
						camGame.setFilters([camGlitchFilter, barrelDistortionFilter]);
						camHUD.setFilters([camGlitchFilter, barrelDistortionFilter]);
					case 1872:
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.05, barrelDistortion2: -0.05}, 2, {ease: FlxEase.quadInOut});
					case 2000:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
						camGlitchShader.amount = 0.075;
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.1, barrelDistortion2: -0.1}, 2, {ease: FlxEase.quadInOut});
					case 2128:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
						camGlitchShader.amount = 0.1;
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.15, barrelDistortion2: -0.15}, 2, {ease: FlxEase.quadInOut});
					case 2224:
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
						camGlitchShader.amount = 0.15;
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: -0.20, barrelDistortion2: -0.20}, 2, {ease: FlxEase.quadInOut});
					case 2288: 
						FlxG.camera.flash(FlxColor.WHITE, 1.5);
						camGlitchShader.amount = 0;
						FlxTween.tween(barrelDistortionShader, {barrelDistortion1: 0.0, barrelDistortion2: 0.0}, 2.5, {
							ease: FlxEase.backOut,
							onComplete: function(tw:FlxTween)
							{
								camGame.setFilters([]);
								camHUD.setFilters([]);
							}
						});
						holyFuckStopZoomin = false;
						camZooming = false;
						FlxTween.tween(camHUD, {alpha: 0}, 3, {ease: FlxEase.cubeInOut});
				}
			}

			case 'soulless-endeavors':
			{
				switch (curStep)
				{
					case 640:
						theStatic.visible = true;
					case 641:
						health = 1;
						soulSky.visible = false;
						soulBalls.visible = false;
						soulRocks.visible = false;
						soulKai.visible = false;
						soulFrontRocks.visible = false;
						soulPixelBgBg.visible = true;
						soulPixelBg.visible = true;
						theStatic.visible = false;
						isPixelStage = true;
						reloadTheNotesPls();
						healthBar.x += 150;
						iconP1.x += 150;
						iconP2.x += 150;
						healthBarBG.x += 150;
						scoreTxt.visible = false;
						fakeTimeBar.visible = false;
						timeBar.visible = false;
						timeBarBG.visible = false;
						timeTxt.visible = false;
						chaotixHUD.visible = true;
						boyfriend.y -= 60;
					case 1152:
						theStatic.visible = true;
					case 1153:
						healthBar.x -= 150;
						iconP1.x -= 150;
						iconP2.x -= 150;
						healthBarBG.x -= 150;
						scoreTxt.visible = !ClientPrefs.hideHud;
						fakeTimeBar.visible = !ClientPrefs.hideHud;
						timeBar.visible = !ClientPrefs.hideHud;
						timeBarBG.visible = !ClientPrefs.hideHud;
						timeTxt.visible = !ClientPrefs.hideHud;
						chaotixHUD.visible = false;

						health = 1;
						soulSky.visible = true;
						soulBalls.visible = true;
						soulRocks.visible = true;
						soulKai.visible = true;
						soulFrontRocks.visible = true;
						soulPixelBgBg.visible = false;
						soulPixelBg.visible = false;
						boyfriend.x += 150;
						boyfriend.y += 60;
						isPixelStage = false;
						reloadTheNotesPls();
					case 1154:
						theStatic.visible = false;

						//bop shit lolololol
					case 64, 256, 639:
						wowZoomin = true;
						holyFuckStopZoomin = false;
					case 128, 272, 1280:
						wowZoomin = false;
						holyFuckStopZoomin = true;
					case 1281:
						defaultCamZoom = 0.75;
					case 1150:
						wowZoomin = false;
						holyFuckStopZoomin = false;
						defaultCamZoom = 0.9;
					case 1792:
						wowZoomin = false;
						holyFuckStopZoomin = false;
						FlxTween.tween(camHUD, {alpha: 0}, 1.75, {ease: FlxEase.cubeInOut});
				}
			}
				
			case 'vista':
			{
				switch (curStep)
				{
					case 512:
						FlxTween.tween(camHUD, {alpha: 0}, 1.2);
						camZooming = false;
					case 576:
						FlxTween.tween(amyBop, {alpha: 0}, 8);
						FlxTween.tween(boyfriend, {alpha: 0.75}, 11);
						FlxTween.tween(gf, {alpha: 0.75}, 11);
						FlxTween.tween(whiteFuck, {alpha: 1}, 11.5, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{
								iShouldKickUrFuckinAss(2);
							}
						});
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.5}, 11.5, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{
								literallyMyHorizon();
							}
						});
					case 694:
						FlxTween.tween(whiteFuckDos, {alpha: 1}, 0.02, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{	
								new FlxTimer().start(0.03, function(tmr:FlxTimer) 
									{				
										remove(whiteFuckDos);
										whiteFuckDos.destroy();
									});
								boyfriend.visible = false;
								gf.visible = false;
							}
						});

						FlxTween.tween(redFuck, {alpha: 1}, 0.02, {ease: FlxEase.cubeInOut, onComplete: function(twn:FlxTween)
							{	
								new FlxTimer().start(0.08, function(tmr:FlxTimer) 
									{				
										remove(redFuck);
										redFuck.destroy();
									});
							}
						});
					case 702:
						dadGroup.visible = false;
					case 2240:
						camZooming = false;
						FlxTween.tween(fuckedBG, {alpha: 0.2}, 3);
						FlxTween.tween(camHUD, {alpha: 0}, 0.5);
						FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.3}, 4, {ease: FlxEase.cubeInOut});
					case 2300:
						animController = false;
					case 2301:
						glitchKill(amyBopFucked);
						glitchKill(mightyBopFucked);
						glitchKill(knuxBopFucked);
					case 2288:
						glitchKill(espioBopFucked);
						glitchKill(vectorBopFucked);
						glitchKill(charmyBopFucked);
						// imma need someone else to fix this lol
					case 2336:
						defaultCamZoom = 0.70;
						glitchinTime = true;
						scoreRandom = true;	
						camHUD.zoom += 2;
						FlxG.camera.flash(FlxColor.BLACK, 1);
						if(ClientPrefs.flashing){
							camGame.setFilters([camGlitchFilter, camFuckFilter]);
							camHUD.setFilters([camGlitchFilter, camFuckFilter]);
						}
						camFuckShader.amount = 0.01;
						FlxTween.tween(camHUD, {alpha: 1}, 0.5);
						FlxTween.tween(this, {health: 1}, 2);
						FlxTween.tween(fuckedBG, {alpha: 1}, 2);
					case 2592:
						defaultCamZoom = 0.60;
						wowZoomin = true;	
						FlxG.camera.flash(FlxColor.WHITE, 1);
						camFuckShader.amount = 0.02;
						finalStretchTrail = new FlxTrail(dad, null, 2, 12, 0.20, 0.05);
						add(finalStretchTrail);
					case 2848:
						defaultCamZoom = 0.65;
						wowZoomin = false;
						holyFuckStopZoomin = true;
						FlxG.camera.flash(FlxColor.WHITE, 1);
						camFuckShader.amount = 0.035;
					case 3104:
						defaultCamZoom = 0.6;
						camFuckShader.amount = 0.045;
					case 3264, 3328, 3520, 3584:
						FlxG.camera.flash(FlxColor.WHITE, 1);
						defaultCamZoom = 0.70;
					case 3269, 3333, 3525, 3589: 
						FlxG.camera.flash(FlxColor.WHITE, 1);
						defaultCamZoom = 0.80;
					case 3280, 3344, 3536, 3600:
						FlxG.camera.flash(FlxColor.BLACK, 1);
						defaultCamZoom = 0.6;
					case 3360:
						camFuckShader.amount = 0.055;
					case 3488:
						camFuckShader.amount = 0.060;
					case 3552:
						camFuckShader.amount = 0.075;
					case 3668:
						FlxG.camera.flash(FlxColor.WHITE, 1);
						FlxTween.tween(camGame, {alpha: 0}, 1);
						FlxTween.tween(camHUD, {alpha: 0}, 1);
				}			
			}
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	var charmyDanced:Bool = false;

	override function beatHit()
	{
		super.beatHit();

		if(fcLabel!=null){
			if(fcLabel.animation.curAnim !=null) {
				var frame = fcLabel.animation.curAnim.curFrame;
				frame += 1;
				frame %= 2;
				fcLabel.animation.curAnim.curFrame = frame;
			}
		}

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (curBeat % 2 == 0 && curStage == 'vista')
		{
			amyBop.animation.play('idle');
			espioBop.animation.play('idle');
			knuxBop.animation.play('idle');
			mightyBop.animation.play('idle');
			vectorBop.animation.play('idle');
			charmyBop.animation.play('danceLeft');
		}

		if (curBeat % 1 == 0 && curStage == 'vista')
			{
				if (animController)
				{	
					amyBopFucked.animation.play('idle');
					espioBopFucked.animation.play('idle');
					knuxBopFucked.animation.play('idle');
					mightyBopFucked.animation.play('idle');
					vectorBopFucked.animation.play('idle');
					charmyBopFucked.animation.play('danceLeft');
				}

			}

		if (curBeat % 4 == 0 && curStage == 'vista')
		{
			charmyBop.animation.play('danceRight');
		}
/* 		if (curBeat % 2 == 0 && curStage == 'vista' && fucklesMode)
		{
			gf.animation.play('scared');
		} */

		if (curBeat % 2 == 0 && wowZoomin)
		{
			FlxG.camera.zoom += 0.04;
			camHUD.zoom += 0.06;

			if (camGlitchShader != null && glitchinTime)
				camGlitchShader.amount += 0.030;
		}

		if (curBeat % 1 == 0 && holyFuckStopZoomin)
		{
			FlxG.camera.zoom += 0.04;
			camHUD.zoom += 0.06;
			if (camGlitchShader != null && glitchinTime)
				camGlitchShader.amount += 0.015;
		}

		if (curBeat % 8 == 0 && fuckedBar)
		{
			var fakeSongPercentTweener:Float = FlxG.random.int(0, 100);

			FlxTween.tween(this, {fakeSongPercent: fakeSongPercentTweener}, 1.5, {ease: FlxEase.cubeOut});
			trace(fakeTimeBar.visible);
			//this shit is supposed to tween randomly everywhere to look like its glitching but it won't fucking work :sob:
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && gray == null && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			bfCamThing = [0, 0];
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dadCamThing = [0, 0];
			dad.dance();
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	function literallyMyHorizon()
		{
			boyfriend.visible = true;
			gf.visible = true;
			dadGroup.visible = true;
			fuckedBar = true;
			FlxG.camera.flash(FlxColor.BLACK, 1);
			camZooming = true;
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 1.5, {ease: FlxEase.cubeInOut});
			FlxTween.tween(camHUD, {alpha: 1}, 1.0);
			amyBop.visible = false;
			fucklesDeluxe();
			FlxTween.tween(whiteFuck, {alpha: 0}, 2, {ease: FlxEase.cubeInOut});

			camHUD.zoom += 2;

			//ee oo ee oo ay oo ay oo ee au ee ah
		}


	function iShouldKickUrFuckinAss(die:Int)
		{
			switch (die)
			{
				case 1:
					FlxG.camera.flash(FlxColor.WHITE, 1.5);
					FlxTween.tween(this, {barSongLength: songLength, health: 1}, 5);

					entranceSpookyBG.visible = true;
					entranceSpookyClock.visible = true;
					entranceSpookyIdk.visible = true;
					entranceSpookyFloor.visible = true;
					entranceSpookyOver.visible = true;

					FlxTween.tween(camHUD, {alpha: 1}, 0.5, {ease: FlxEase.cubeInOut});
						camHUD.zoom += 2;

					remove(entranceBG);
					entranceBG.destroy();
					remove(entranceClock);
					entranceClock.destroy();
					remove(entranceIdk);
					entranceIdk.destroy();
					remove(entranceFloor);
					entranceFloor.destroy();
					remove(entranceOver);
					entranceOver.destroy();
					//the game is racist its over
					//this is a joke coming from a mixed dude shut the fuck up twitter.
				case 2:
					FlxTween.tween(this, {health: 1}, 5);
					FlxTween.tween(boyfriend, {alpha: 1}, 0.01);
					FlxTween.tween(gf, {alpha: 1}, 0.01);

					remove(vistaFlower);
					vistaFlower.destroy();
					remove(vistaTree);
					vistaTree.destroy();
					remove(vistaBush);
					vistaBush.destroy();
					remove(vistaGrass);
					vistaGrass.destroy();
					remove(vistaFloor);
					vistaFloor.destroy();
					remove(vistaBG);
					vistaBG.destroy();

					amyBop.visible = false;
					vectorBop.visible = false;
					charmyBop.visible = false;
					espioBop.visible = false;
					mightyBop.visible = false;
					knuxBop.visible = false;

					amyBopFucked.visible = true;
					charmyBopFucked.visible = true;
					vectorBopFucked.visible = true;
					espioBopFucked.visible = true;
					mightyBopFucked.visible = true;
					knuxBopFucked.visible = true;

					fuckedBG.visible = true;
					fuckedFloor.visible = true;
					fuckedGrass.visible = true;
					fuckedBush.visible = true;
					fuckedTree.visible = true;
					fuckedFlower.visible = true;
					fuckedTails.visible = true;
			}
		}


	function staticEvent()
	{
		FlxTween.tween(theStatic, {alpha: 0.9}, 1.5, {ease: FlxEase.quadInOut});

		new FlxTimer().start(0.9, function(tmr:FlxTimer) 
		{				
			FlxFlicker.flicker(theStatic, 0.5, 0.02, false, false);
		});
		new FlxTimer().start(1.5, function(tmr:FlxTimer) 
		{				
			FlxG.camera.flash(0xFF0edc7c, 1);
			theStatic.visible = false;
			theStatic.alpha = 0;
		});
	}


	function reloadTheNotesPls()
	{
		playerStrums.forEach(function(spr:StrumNote)
		{
			spr.reloadNote();
		});
		opponentStrums.forEach(function(spr:StrumNote)
		{
			spr.reloadNote();
		});
		notes.forEach(function(spr:Note)
		{
			spr.reloadNote();
		});
	}

	function fucklesDeluxe()
	{
		health = 2;
		//songMisses = 0;
		fucklesMode = true;

		timeBar.visible = false;
		timeTxt.visible = false;

		scoreTxt.visible = false;

		opponentStrums.forEach(function(spr:FlxSprite)
		{
			spr.x += 10000;
		});
	}

			// ok might not do this lmao

	var fuckedMode:Bool = false;

	function fucklesFinale()
	{
		if (fucklesMode)
			fuckedMode = true;
		if (fuckedMode)
		{
			health -= 0.1;
			if (health <= 0.01)
			{
				health = 0.01;
				fuckedMode = false;
			}
		}
	}

	function fucklesHealthRandomize()
	{
		if (fucklesMode)
			health = FlxG.random.float(0.5, 2);
		// randomly sets health between max and 0.5,
		// this im gonna use for stephits and basically
		// have it go fucking insane in some parts and disable the drain and reenable when needed
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";

			if(fcLabel!=null){
				if(fcLabel.animation.curAnim!=null){
					if(fcLabel.animation.getByName(ratingFC)!=null && fcLabel.animation.curAnim.name!=ratingFC){
						var frame = fcLabel.animation.curAnim.curFrame;
						fcLabel.animation.play(ratingFC,true);
						fcLabel.animation.curAnim.curFrame = frame;
					}
				}else if(fcLabel.animation.getByName(ratingFC)!=null){
					fcLabel.animation.play(ratingFC,true);
				}
				fcLabel.visible=songMisses<10;
			}
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end


	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}