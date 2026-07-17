package mobile.options;

import flixel.input.keyboard.FlxKey;
import options.BaseOptionsMenu;
import options.Option;
#if sys
import funk.PsychFile as File;
#end

class MobileOptionsSubState extends BaseOptionsMenu
{
    final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
    final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
    var option:Option;

    public function new()
    {

        title = 'Mobile Options';
        rpcTitle = 'Mobile Options Menu'; // for Discord Rich Presence

        option = new Option('Extra Controls', 'Select how many extra buttons you prefer to have?\nThey can be used for mechanics with LUA or HScript.',
            'extraButtons', 'string', 'NONE', exControlTypes);
        addOption(option);

        option = new Option('Mobile Controls Opacity',
            'Selects the opacity for the mobile buttons (careful not to put it at 0 and lose track of your buttons).', 'controlsAlpha', 'percent', 60);
        option.scrollSpeed = 1;
        option.minValue = 0.001;
        option.maxValue = 1;
        option.changeValue = 0.1;
        option.decimals = 1;
        option.onChange = () ->
        {
            touchPad.alpha = curOption.getValue();
        };
        addOption(option);

        #if mobile
        option = new Option('Allow Phone Screensaver',
            'If checked, the phone will sleep after going inactive for few seconds.\n(The time depends on your phone\'s options)', 'screensaver', 'bool', false);
        option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
        addOption(option);
        #end

        if (MobileData.mode == 3)
        {
            option = new Option('Hitbox Design', 'Choose how your hitbox should look like.', 'hitboxType', 'string', 'Gradient', hintOptions);
            addOption(option);

            option = new Option('Hitbox Position', 'If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.',
                'hitboxPos', 'bool', true);
            addOption(option);

            super();
        }
    }
}
