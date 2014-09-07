Routine.run({

	if(thisProcess.openUDPPort(5001), {
		~processing = NetAddr("127.0.0.1", 5001);
		"OSC port is open".postln;
	}, {
		"OSC port does NOT open. Run SuperCollider code first then Processing.".postln;
		CmdPeriod.run;
		s.freeAll;
		OSCdef.freeAll;
		currentEnvironment.clear;
		s.quit;
	});

	s.wait;

	OSCdef("pixelsNum", {arg msg, time, addr, recvPort;
		~pixelsNum = msg[1];

		~redPixelsList = List.newClear;
		~redPixelsListPerc = List.newClear;
		~greenPixelsList = List.newClear;
		~greenPixelsListPerc = List.newClear;
		~bluePixelsList = List.newClear;
		~bluePixelsListPerc = List.newClear;

		~noteA = Synth("solaris");
		~noteB = Synth("solaris");
		~noteC = Synth("solaris");

	}, '/pixelsnum');

	OSCdef("frameDelay", {arg msg, time, addr, recvPort;
		~frameDelay = msg[1];
	}, '/framedelay');

	OSCdef("redAverage", { arg msg, time, addr, recvPort;
		~redAverage = msg[1];
		~redOffset = ((5 / 255) * msg[1]).round;
	}, '/redaverage');

	OSCdef("greenAverage", { arg msg, time, addr, recvPort;
		~greenAverage = msg[1];
		~greenOffset = ((5 / 255) * msg[1]).round;
	}, '/greenaverage');

	OSCdef("blueAverage", { arg msg, time, addr, recvPort;
		~blueAverage = msg[1];
		~blueOffset = ((5 / 255) * msg[1]).round;
	}, '/blueaverage');

	OSCdef("redPixelsHarm", { arg msg, time, addr, recvPort;
		// harm
		if(~redOffset.notNil, {~redPixelsList.add(msg[1])});

		if(~redPixelsList.size == ~pixelsNum, {
			Routine.run({

				((~redOffset * 0.4).round(0.05)).wait;

				~redPixelsList.do({arg item, n;
					var note, dur;
					note = ((17 / 255) * item).round;
					dur = (item + 1) * 0.01;

					if((s.numSynths < ~maxSynthNum).and(s.peakCPU < ~maxCPU), {
						Synth("red", [
							\note, ~pitches.wrapAt(note + ~redOffset),
							\attrel, (256 / (item + 1)).log + 0.005,
							\mul, 1 / (item + 2).log,
							\mfreq, item,
							\oct, (~redAverage * (4 / 255)).round,
							\mul2, ~redAverage / 255
						]);
					});

					dur.wait;
				});
				~redPixelsList = List.newClear;
			});
		});

	}, '/redpixels');

	OSCdef("redPixelsPerc", { arg msg, time, addr, recvPort;
		// perc
		if(~redAverage.notNil, {~redPixelsListPerc.add(msg[1])});

		if(~redPixelsListPerc.size == ~pixelsNum, {
			Routine.run({

				~redPixelsListPerc.do({arg item, n;
					var dur;
					dur = 1 / 2.pow(item%2);

					Synth("redPerc", [
						\note, ((79 / 255) * item + 36).round,
						\mul, ~redAverage / 255,
						\muleach, item / 255,
						\mfreq, item,
						\dtime, (~frameDelay / ~pixelsNum) * dur
					]);

					(~frameDelay / ~pixelsNum).wait;
				});
				~redPixelsListPerc = List.newClear;
			});
		});

	}, '/redpixels');

	OSCdef("greenPixels", { arg msg, time, addr, recvPort;
		if(~greenOffset.notNil, {~greenPixelsList.add(msg[1])});

		if(~greenPixelsList.size == ~pixelsNum, {
			Routine.run({

				((~greenOffset * 0.4).round(0.05)).wait;

				~greenPixelsList.do({arg item, n;
					var note, dur;
					note = ((11 / 255) * item).round;
					dur = (item + 1) * 0.01;

					if((s.numSynths < ~maxSynthNum).and(s.peakCPU < ~maxCPU), {
						Synth("green", [
							\note, ~pitches.wrapAt(note + ~greenOffset),
							\att, (item + 2).log10.squared,
							\rel, (256 / (item + 1)).log + 0.005,
							\mul, ~greenAverage / 255,
							\mfreq, item,
							\oct, (~greenAverage * (4 / 255)).round
						]);
					});

					dur.wait;
				});
				~greenPixelsList = List.newClear;
			});
		});
	}, '/greenpixels');

	OSCdef("greenPixelsPerc", { arg msg, time, addr, recvPort;
		// perc
		if(~greenAverage.notNil, {~greenPixelsListPerc.add(msg[1])});

		if(~greenPixelsListPerc.size == ~pixelsNum, {
			Routine.run({

				~greenPixelsListPerc.do({arg item, n;
					var dur;
					dur = 2 / 2.pow(item%3);

					Synth("greenPerc", [
						\note, ((79 / 255) * item + 36).round,
						\mul, ~greenAverage / 255,
						\muleach, item / 255,
						\mfreq, item,
						\dtime, (~frameDelay / ~pixelsNum) * (1 / 2.pow(item%3));
					]);

					((~frameDelay / ~pixelsNum) * dur).wait;
				});
				~greenPixelsListPerc = List.newClear;
			});
		});

	}, '/greenpixels');

	OSCdef("bluePixels", { arg msg, time, addr, recvPort;
		if(~blueOffset.notNil, {~bluePixelsList.add(msg[1])});

		if(~bluePixelsList.size == ~pixelsNum, {
			Routine.run({

				((~blueOffset * 0.4).round(0.05)).wait;

				~bluePixelsList.do({arg item, n;
					var note, dur;
					note = ((11 / 255) * item).round;
					dur = (item + 1) * 0.01;

					if((s.numSynths < ~maxSynthNum).and(s.peakCPU < ~maxCPU), {
						Synth("blue", [
							\note, ~pitches.wrapAt(note + ~blueOffset),
							\att, (item + 2).log10.pow(3),
							\rel, ((256 / (item + 1)).log + 0.005) * 3,
							\mul, ~blueAverage / 255,
							\mfreq, item,
							\oct, (~blueAverage * (4 / 255)).round
						]);
					});

					dur.wait;
				});
				~bluePixelsList = List.newClear;
			});
		});

	}, '/bluepixels');

	OSCdef("bluePixelsPerc", { arg msg, time, addr, recvPort;
		// perc
		if(~blueAverage.notNil, {~bluePixelsListPerc.add(msg[1])});

		if(~bluePixelsListPerc.size == ~pixelsNum, {
			Routine.run({

				~bluePixelsListPerc.do({arg item, n;
					var dur;
					dur = (item + 2).log10.reciprocal.squared.round(0.0625) * 8;

					if((1 / 255 * item).coin.and(s.peakCPU < ~maxCPU),  {
						Synth("bluePerc", [
							\note, ~bluePercPitches.wrapAt(((83 / 255) * item).round),
							\mul, ~blueAverage / 255,
							\muleach, item / 255,
							\mfreq, item,
							\dtime, (~frameDelay / ~pixelsNum) * (1 / 2.pow(item%3));
						]);
					});

					((~frameDelay / ~pixelsNum) * dur).wait;
				});
				~bluePixelsListPerc = List.newClear;
			});
		});

	}, '/bluepixels');

	OSCdef("newFrame", { arg msg, time, addr, recvPort;
		~bluePixelsListPerc = List.newClear;

		if((~redOffset.notNil).and(~greenOffset.notNil).and(~blueOffset.notNil), {

			~noteA.set(
				\note, ~pitches.wrapAt(~redOffset),
				\mul, (~redOffset + 1) / 6
			);

			~noteB.set(
				\note, ~pitches.wrapAt(~greenOffset + 2),
				\mul, (~greenOffset + 1) / 6
			);

			~noteC.set(
				\note, ~pitches.wrapAt(~blueOffset + 4 + [-1, 0, 1].choose),
				\mul, (~blueOffset + 1) / 6,
				\dur, [0.5, 1].wchoose([1, 20].normalizeSum)
			);

		});

	}, '/newframe');

	s.wait;

	"24hSolaris.app".resolveRelative.openOS;

	s.wait;

	{var script = "osascript -e 'on is_running(appName)\n"
		"tell application \"System Events\" to (name of processes) does not contain appName\n"
		"end is_running\n"
		"set solRunning to is_running(\"sketch_24h_Solaris_Desktop\")\n"
		"if solRunning then\n"
		"tell application \"24h Solaris D\" to quit\n"
		"end if'";
		loop{
			if((~redOffset.notNil).or(~greenOffset.notNil).or(~blueOffset.notNil), {
				script.unixCmd;
				}); 4.wait};
	}.fork;
});
