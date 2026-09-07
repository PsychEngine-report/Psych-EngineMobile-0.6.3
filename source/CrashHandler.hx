package;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
#if sys
import funk.PsychFileSystem as FileSystem;
import funk.PsychFile as File;
import sys.io.File;
#end

using StringTools;
using flixel.util.FlxArrayUtil;

/**
 * Crash Handler & Custom Trace Logger.
 * @author YoshiCrafter29, Ne_Eo, MAJigsaw77 and Lily Ross (mcagabe19)
 */
class CrashHandler
{
	#if sys
	private static var traceFilePath:String = null;
	#end

	public static function init():Void
	{
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end

		#if sys
		initCustomTrace();
		#end
	}

	#if sys
	private static function initCustomTrace():Void
	{
		var oldTrace = haxe.Log.trace;

		var storagePath = #if mobile StorageUtil.getStorageDirectory() + #end 'traces/';

		if (!FileSystem.exists(storagePath))
			FileSystem.createDirectory(storagePath);

		traceFilePath = storagePath + Date.now().toString().replace(' ', '-').replace(':', "'") + '_session.txt';

		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos)
		{
			oldTrace(v, infos);

			var methodInfo = "Unknown position";
			if (infos != null)
			{
				methodInfo = '${infos.className}.${infos.methodName} (line ${infos.lineNumber})';
			}
			var traceContent = '[$methodInfo] $v\n';

			appendTraceMessage(traceContent);
		};
	}

	private static function appendTraceMessage(message:String):Void
	{
		try
		{
			if (traceFilePath != null)
			{
				var fout = sys.io.File.append(traceFilePath, false);
				fout.writeString(message);
				fout.close();
			}
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save trace message. (${e.message})');
	}
	#end

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = e.error;
		if (Std.isOfType(e.error, Error))
		{
			var err = cast(e.error, Error);
			m = '${err.message}';
		}
		else if (Std.isOfType(e.error, ErrorEvent))
		{
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		var stack = haxe.CallStack.exceptionStack();
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		for (e in stack)
		{
			switch (e)
			{
				case CFunction:
					stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c):
					stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');

		#if sys
		saveErrorMessage('$m\n$stackLabel');
		#end

		CoolUtil.showPopUp('$m\n$stackLabel', "Error!");
		lime.system.System.exit(1);
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		final log:Array<String> = [];

		if (message != null && message.length > 0)
			log.push(message);

		log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));

		#if sys
		saveErrorMessage(log.join('\n'));
		#end

		CoolUtil.showPopUp(log.join('\n'), "Critical Error!");
		lime.system.System.exit(1);
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		try
		{
			var storagePath = #if mobile StorageUtil.getStorageDirectory() + #end 'logs/';

			if (!FileSystem.exists(storagePath))
				FileSystem.createDirectory(storagePath);

			sys.io.File.saveContent(storagePath
				+ Date.now().toString().replace(' ', '-').replace(':', "'")
				+ '.txt',
				message);
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
	}
	#end
}
