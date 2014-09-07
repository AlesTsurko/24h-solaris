Server.default = Server.local;
s = Server.default;
s.options.blockSize = 512;
s.options.memSize = 2 ** 20;
s.waitForBoot({
	Routine.run({
		~speed = 0.12; // скорость воспроизведения видео

		~redPixelsList = List.newClear;
		~redPixelsListPerc = List.newClear;
		~greenPixelsList = List.newClear;
		~greenPixelsListPerc = List.newClear;
		~bluePixelsList = List.newClear;
		~bluePixelsListPerc = List.newClear;

		~maxSynthNum = 50;
		~maxCPU = 87;

		~pitches = List.newClear;
		~bluePercPitches = List.newClear;

		[36, 40, 41, 43, 45, 47].do({arg item;
			3.do({arg a;
				~pitches.add(item + (12 * a))
			});
			7.do({arg a;
				~bluePercPitches.add(item + (12 * a))
			});
		});

		~pitches.sort;
		~bluePercPitches.sort;

		s.volume = -1;
		// s.volume.gui;

		~solSound = Buffer.cueSoundFile(s, "solaris_sound_mono.wav".resolveRelative, 0, 1, 2 ** 16);

		s.sync;

		SynthDef("red", {arg note, attrel, mul, mul2, mfreq, oct;
			var env, trig, osc, osc2, out;
			env = EnvGen.kr(Env.perc(attrel, attrel), doneAction: 2);
			trig = Dust.kr((mfreq + 2).log.squared);
			osc = GrainSin.ar(2, trig, (mfreq + 2).log * 0.25, note.midicps * ((2 ** oct) / 2) * 2, mul: 0.9).tan.log * env;
			osc2 = SinOscFB.ar(note.midicps, mfreq, (1 / (mfreq + 1)) * 0.07, 0.08) * env;
			out = osc.thresh(osc2) + osc.thresh(osc.ceil * mul * osc2).acos + osc.scaleneg(osc2);
			out = BMoog.ar(out, 10000 * (1 / (mfreq + 2).log.squared), 0.98, 0.7, 0.95, 0.1);
			out = out + (PitchShift.ar(out, (mfreq + 2).log * 0.4, note.midiratio * 2, 0.1, 0.5, (mfreq + 2).log * 0.05).floor.cubed * 0.15) * env;
			out = BLowPass4.ar(out, 10000 * (1 / (mfreq + 2).log.squared), (mfreq + 2).log10 * 0.9) + BHiPass4.ar(out, 800, 0.5, mul2 * mul2);
			out = Pan2.ar(Limiter.ar(out, 0.9), TRand.kr(-0.85, 0.85, trig));
			out = Normalizer.ar(out, 0.1);
			out = BPeakEQ.ar(out, 116, 1, 2);
			out = BPeakEQ.ar(out, 205, 1.67, -4.5);
			out = BPeakEQ.ar(out, 15400, 4.35, 4.5);

			Out.ar(0, LeakDC.ar(out, mul: mul * mul2))
		}).add;

		SynthDef("green", {arg note, att, rel, mul, oct, mfreq;
			var env, pitch, gen, out;
			env = EnvGen.kr(Env.perc(att, rel), doneAction: 2);
			pitch = Vibrato.kr(note.midicps * ((2 ** oct) / 2), 2, 0.007, 0, 0, 0.1, 0.2);
			gen = LFTri.ar(pitch, 0, mul * 0.7).cos.log * env;
			out = gen * 20;
			out = out + PitchShift.ar(out, (mfreq + 2).log * 0.4, (2 ** oct) * 0.25, 0, 0.1, mul * mul * 0.7 * env).tan;
			out = Limiter.ar(LeakDC.ar(out), 0.9);
			out = Pan2.ar(out, LFNoise1.ar(7));
			out = Normalizer.ar(out) * env;
			out = BLowShelf.ar(out, 106, 0.625, -21.5);
			out = BPeakEQ.ar(out, 130, 3.23, -13.5);
			out = BPeakEQ.ar(out, 250, 3.23, -12);
			out = BPeakEQ.ar(out, 335, 2.7, 7.5);
			out = BPeakEQ.ar(out, 415, 5, -18.5);
			out = BPeakEQ.ar(out, 11600, 1.33, 3);
			out = BHiShelf.ar(out, 2600, 2.38, 12.5);
			out = BHiShelf.ar(out, 9400, 2.13, 15);

			Out.ar(0, out * mul * 0.142)
		}).add;

		SynthDef("blue", {arg note, att, rel, mul, oct, mfreq;
			var env, mod, gen, out;
			env = EnvGen.kr(Env.perc(att, rel), doneAction: 2);
			mod = SinOsc.ar(note.midicps * ((2 ** oct) / 2) * (4 + ((mfreq + 2).log * 0.1)), 0, mul.pow(2) * 400);
			mod = mod + SinOsc.ar(note.midicps * ((2 ** oct) / 2) * ((mfreq + 2).log * 0.1), 0, mul.pow(2) * 50);
			gen = SinOsc.ar(note.midicps + mod, 0, mul * 0.5) * env;
			out = (gen.cos * 10) + (gen * mul);
			out = Pan2.ar(Limiter.ar(LeakDC.ar(out), 0.9), LFNoise1.kr(10));
			out = BLowShelf.ar(out, 136, 1, 10.5);
			out = BPeakEQ.ar(out, 94, 0.83, 6.5);
			out = BPeakEQ.ar(out, 140, 4.17, -12.5);
			out = BPeakEQ.ar(out, 1300, 3.7, 5);
			out = BPeakEQ.ar(out, 2150, 2.17, 8);

			Out.ar(0, out * mul * 0.5)
		}).add;

		SynthDef("redPerc", {arg note, mul, muleach, dtime, mfreq;
			var env, trig, gen, out;
			env = EnvGen.kr(Env.perc(0.005, 0.5), doneAction: 2);
			trig = Impulse.kr(1);
			gen = GrainFM.ar(2, trig, (mfreq + 2).log * 0.001, note.midicps, (mfreq + 1).squared,
			mfreq.log.squared, 0, mul: mul.pow(3) * 2 * muleach).atan;
			out = gen + AllpassN.ar(gen, 0.1, dtime, 0.5, mul * (mfreq * 0.08)).acos;
			out = out.cosh + out.ceil;
			out = Pan2.ar(Limiter.ar(LeakDC.ar(out), 0.9), LFNoise1.kr(20));
			out = out + (out.floor * mul.pow(4) * 0.1).softclip;
			out = out + (((out.sqrt.asin * mul.pow(4)).floor * mul.pow(4)).acos * 0.3);
			out = Pan2.ar(Limiter.ar(LeakDC.ar(out), 0.1 * mul.pow(3)), TRand.kr(-0.9, 0.9, trig)).tanh.sinh;
			out = BHiPass4.ar(out, 150, 1.41);
			out = BPeakEQ.ar(out, 148, 3.33, -17.5);
			out = BPeakEQ.ar(out, 325, 3.33, -10);
			out = BPeakEQ.ar(out, 500, 3.03, 4.5);
			out = BPeakEQ.ar(out, 2750, 4.17, 7);
			out = BHiShelf.ar(out, 7800, 2, 9);

			Out.ar(0, LeakDC.ar(out));
		}).add;

		SynthDef("greenPerc", {arg note, mul, muleach, dtime, mfreq;
			var env, env2, mod, gen, out;
			env = EnvGen.kr(Env.perc(0.015, 0.025));
			env2 = EnvGen.kr(Env.perc(0.1, 2), doneAction: 2);
			mod = SinOsc.ar(note.midicps * 16.1, mul.pow(3) * 1.5, 1.2).tanh;
			gen = LFPar.ar(note.midicps, 0, mul.pow(3) * muleach).acos.clip * env;
			out = gen.sqrt.tanh + (gen * mod * muleach.pow(3)).softclip;
			out = Limiter.ar(LeakDC.ar(out * 4 * mul.pow(3)), 0.3);
			out = BHiPass4.ar(out, 90, 1.41);
			out = BPeakEQ.ar(out, 108, 0.77, 11.5);
			out = BPeakEQ.ar(out, 186, 3.33, -10);
			out = BPeakEQ.ar(out, 310, 3.33, -7);
			out = BPeakEQ.ar(out, 3700, 5, 8);
			out = BHiShelf.ar(out, 15400, 2.78, 15);

			Out.ar(0, out!2 * 4.dbamp);
		}).add;

		SynthDef("bluePerc", {arg note, mul, muleach, dtime, mfreq;
			var trig, env, env2, gen, out;
			trig = Impulse.kr(1);
			env = EnvGen.kr(Env.perc(0.005, 0.1));
			env2 = EnvGen.kr(Env.perc(0.005, 4), doneAction: 2);
			gen = DPW4Saw.ar(note.midicps, muleach).ceil * env;
			gen = PMOsc.ar(note.midicps, note.midicps * 0.25, mfreq, 0, 1) * env + gen;
			out = Pluck.ar(gen, trig, 1 / note.midicps, 1 / note.midicps, muleach.neg.reciprocal - 0.001, 0.7 + TRand.kr(0, 0.25, trig));
			out = out + AllpassN.ar(out, 0.1, dtime, muleach.reciprocal + 0.001, muleach);
			out = Decay.ar(Resonz.ar(out, note.midicps, 0.01, 7), muleach * 10, 0.7) * env2 + out;
			out = Pan2.ar(out, TRand.kr(-0.5, 0.5, trig), mul.pow(3) * 3.1);
			out = LeakDC.ar(out);
			out = Limiter.ar(out, 0.8 * mul);
			out = BHiPass4.ar(out, 40, 1.41);
			out = BLowShelf.ar(out, 91, 1, -10.5);
			out = BPeakEQ.ar(out, 102, 3.7, -3.5);
			out = BPeakEQ.ar(out, 215, 3.3, -8);
			out = BPeakEQ.ar(out, 335, 5, -5.5);
			out = BPeakEQ.ar(out, 390, 3.3, -7);
			out = BHiShelf.ar(out, 2850, 2.94, 14, 2);

			Out.ar(0, out);
		}).add;

		SynthDef("solaris", {arg note = 60, mul = 0, dur = 1;
			var trig, val, pos, play, grain, out;
			trig = Saw.kr((24 / 4) * dur); // (~pixelsNum / ~frameDelay) * dur
			val = LFNoise1.kr(1);
			pos = TRand.kr(trig: trig);
			play = VDiskIn.ar(1, ~solSound.bufnum, ~speed, 1);
			grain = GrainBuf.ar(2, trig, 0.01, ~solSound.bufnum, 1, pos);
			out = Pluck.ar(grain, trig, 1 / note.midicps * 0.25, 1 / note.midicps * 0.25, TRand.kr(0.1, 4, trig), 0.45);
			out = XFade2.ar(out, grain, -0.1, val.abs.neg.clip(-1, -0.8));
			out = BHiPass4.ar(out, 290, 1.41);
			out = BPeakEQ.ar(out, 510, 7.69, -10, 12 * mul);
			out = Limiter.ar(LeakDC.ar(out, mul: -3.dbamp));

			Out.ar(0, out)
		}).add;

		s.wait;
		"OSC.scd".loadRelative;
	});
});
