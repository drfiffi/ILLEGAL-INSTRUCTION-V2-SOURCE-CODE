package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxInput.FlxInputState;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.effects.FlxFlicker;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxDirectionFlags;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
#if MODS_ALLOWED
import sys.FileSystem;
#end
using StringTools;

class BallsFreeplay extends MusicBeatState
{  
    var songs:Array<String> = [
        'breakout',
        'soulless-endeavors',
        'vista',
        'meltdown',
        'color-crash'
    ];

    var characters:Array<String> = [
        'duke',
        'P2duke',
        'chaotix',
        'chotix',
        'wechnia'
    ];

    var backgroundShits:FlxTypedGroup<FlxSprite>;

    var screenInfo:FlxTypedGroup<FlxSprite>;
    var screenCharacters:FlxTypedGroup<FlxSprite>;

    var player:FlxSprite;

    public static var numSelect:Int = 0;

    override function create()
    {
        Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

        if (ClientPrefs.ducclyMix)
        {
            FlxG.sound.playMusic(Paths.music('freeplayThemeDuccly'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.7);
        }
        else
        {
            FlxG.sound.playMusic(Paths.music('freeplayTheme'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.7);
        }
        transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

        FlxG.mouse.visible = true;

        #if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Selecting The New World.", null);
		#end

        var blackFuck:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
        blackFuck.screenCenter();
        add(blackFuck);

        backgroundShits = new FlxTypedGroup<FlxSprite>();
		add(backgroundShits);

        screenInfo = new FlxTypedGroup<FlxSprite>();
		add(screenInfo);

        screenCharacters = new FlxTypedGroup<FlxSprite>();
		add(screenCharacters);

        var characterText:FlxText;
        var scoreText:FlxText;
        var proceedText:FlxText;
        var yn:FlxText;

        for(i in 0...songs.length)
        {
            var songPortrait:FlxSprite = new FlxSprite();

            songPortrait.loadGraphic(Paths.image('freeplay/screen/${songs[i]}'));

            songPortrait.screenCenter();
            songPortrait.antialiasing = false;
            songPortrait.scale.set(4.5, 4.5);
            songPortrait.y -= 60;
            songPortrait.alpha = 0;
            screenInfo.add(songPortrait);

            var songCharacter:FlxSprite = new FlxSprite();
            songCharacter.frames = Paths.getSparrowAtlas('freeplay/screen/${characters[i]}');
            songCharacter.animation.addByPrefix('idle', '${characters[i]}_idle', 24, true);
            songCharacter.animation.play('idle');
            songCharacter.screenCenter();
            songCharacter.scale.set(3, 3);
            songCharacter.x -= 360;
            songCharacter.y -= 70;
            songCharacter.alpha = 0;
            if(i == 0)
                songCharacter.flipX = true;

            screenCharacters.add(songCharacter);


            songPortrait.ID = i;
            songCharacter.ID = i;

            if(songPortrait.ID == numSelect)
                songPortrait.alpha = 1;

            if(songCharacter.ID == numSelect)
                songCharacter.alpha = 1;

            /* 
            After those make a screen shit for each pixel background all in 1 location and then add
            them to pixelShits
            */

            //Each song has a background
        }



        var screen:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/Frame'));
        screen.setGraphicSize(FlxG.width, FlxG.height);
        screen.updateHitbox();
        add(screen);

        super.create();
    }

    var infoScreen:Bool = false;
    var curSelected:Int = 0;

    override function update(elapsed:Float)
    {

        super.update(elapsed);
    }

    override function switchTo(state:FlxState) {
		FlxG.mouse.visible = false;

        FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

		return super.switchTo(state);
	}

    function doTheLoad()
    {
       /*  var songLowercase:String = Paths.formatToSongPath(songs[curSelected]);
        PlayState.SONG = Song.loadFromJson(songLowercase + '-hard', songLowercase);
        PlayState.isStoryMode = false;
        PlayState.storyDifficulty = 2;
        LoadingState.loadAndSwitchState(new PlayState()); */
    }
}