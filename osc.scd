// Bus assignments
var reverbBus = 4;
var synths;
var reverb1;

s.waitForBoot {
	SynthDef(\braids, { |pitch = 60, gate = 0, timbre = 0, color = 0, model = 0,
		freq = 2000, res = 0, low = 1, band = 0, high = 0, rev = 0,
		attack = 1, release = 1, level = 1,
		att_pitch = 1, rel_pitch = 1, pitch_level = 0,
		att_flt = 1, rel_flt = 1, flt_level = 0,
		pitch_lfo_freq = 1, pitch_lfo_level = 0,
		flt_lfo_freq = 1, flt_lfo_level = 0,
		timbre_lfo_freq = 1, timbre_lfo_level = 0,
		color_lfo_freq = 1, color_lfo_level = 0,
		tempo = 60|

		var lfo_pitch   = SinOsc.kr(pitch_lfo_freq   * tempo / 240, 0, pitch_lfo_level);
		var lfo_flt     = SinOsc.kr(flt_lfo_freq     * tempo / 240, 0, flt_lfo_level);
		var lfo_timbre  = SinOsc.kr(timbre_lfo_freq  * tempo / 240, 0, timbre_lfo_level);
		var lfo_color   = SinOsc.kr(color_lfo_freq   * tempo / 240, 0, color_lfo_level);
		var env         = EnvGen.kr(Env.perc(attack,    release,   level),       gate);
		var env_pitch   = EnvGen.kr(Env.perc(att_pitch, rel_pitch, pitch_level), gate);
		var env_flt     = EnvGen.kr(Env.perc(att_flt,   rel_flt,   flt_level),   gate);
		var braids      = MiBraids.ar(pitch + env_pitch + lfo_pitch, timbre + lfo_timbre, color + lfo_color, model, gate);
		var filter      = SVF.ar(braids, freq + env_flt + lfo_flt, res, low, band, high);
		var sig         = filter * env;

		Out.ar(0, Pan2.ar(sig, 0));
		Out.ar(reverbBus, sig * rev);
	}).add;

	SynthDef(\reverb, { |time = 0.5, damp = 0.5, hp = 0, freeze = 0, diff = 0.5|
		Out.ar(0, MiVerb.ar(In.ar(reverbBus), time, 1, damp, hp, freeze, diff));
	}).add;

	s.sync;

	reverb1 = Synth(\reverb);

	// Reverb OSC handlers
	OSCFunc({ |msg| reverb1.set(\time,   msg[1].linlin(0, 255, 0, 1.25)) }, "/r/time");
	OSCFunc({ |msg| reverb1.set(\damp,   msg[1].linlin(0, 255, 0, 1))    }, "/r/damp");
	OSCFunc({ |msg| reverb1.set(\hp,     msg[1].linlin(0, 255, 0, 1))    }, "/r/hpfl");
	OSCFunc({ |msg| reverb1.set(\freeze, msg[1])                         }, "/r/frez");
	OSCFunc({ |msg| reverb1.set(\diff,   msg[1].linlin(0, 255, 0, 1))    }, "/r/diff");

	// Create all 8 braids synths
	synths = Array.fill(8, { Synth(\braids) });

	// Tempo handler: registered once, applies to all synths
	OSCFunc({ |msg|
		synths.do { |s| s.set(\tempo, msg[1]) };
	}, "/t/temp");

	// Per-synth OSC handlers
	synths.doWithIndex { |synth, i|
		var idx = i + 1;

		OSCFunc({ |msg|
			synth.set(\pitch, msg[1]);
			synth.set(\gate, 1);
		}, "/%/nton".format(idx));

		OSCFunc({ |msg| synth.set(\gate,        0)                               }, "/%/ntof".format(idx));
		OSCFunc({ |msg| synth.set(\attack,       msg[1].linexp(0, 255, 0.001, 20)) }, "/%/attk".format(idx));
		OSCFunc({ |msg| synth.set(\release,      msg[1].linexp(0, 255, 0.001, 20)) }, "/%/rele".format(idx));
		OSCFunc({ |msg| synth.set(\level,        msg[1].linlin(0, 255, 0, 1))      }, "/%/levl".format(idx));
		OSCFunc({ |msg| synth.set(\timbre,       msg[1].linlin(0, 255, 0, 1))      }, "/%/tmbr".format(idx));
		OSCFunc({ |msg| synth.set(\color,        msg[1].linlin(0, 255, 0, 1))      }, "/%/colr".format(idx));
		OSCFunc({ |msg| synth.set(\model,        msg[1])                           }, "/%/modl".format(idx));
		OSCFunc({ |msg| synth.set(\freq,         msg[1].linexp(0, 255, 20, 20000)) }, "/%/freq".format(idx));
		OSCFunc({ |msg| synth.set(\res,          msg[1].linlin(0, 255, 0, 1))      }, "/%/reso".format(idx));
		OSCFunc({ |msg| synth.set(\rev,          msg[1].linlin(0, 255, 0, 1))      }, "/%/revb".format(idx));
		OSCFunc({ |msg| synth.set(\att_pitch,    msg[1].linexp(0, 255, 0.001, 20)) }, "/%/peat".format(idx));
		OSCFunc({ |msg| synth.set(\rel_pitch,    msg[1].linexp(0, 255, 0.001, 20)) }, "/%/pede".format(idx));
		OSCFunc({ |msg| synth.set(\pitch_level,  msg[1].linlin(0, 255, 0, 60))     }, "/%/peam".format(idx));
		OSCFunc({ |msg| synth.set(\att_flt,      msg[1].linexp(0, 255, 0.001, 20)) }, "/%/feat".format(idx));
		OSCFunc({ |msg| synth.set(\rel_flt,      msg[1].linexp(0, 255, 0.001, 20)) }, "/%/fede".format(idx));
		OSCFunc({ |msg| synth.set(\flt_level,    msg[1].linlin(0, 255, 0, 10000))  }, "/%/feam".format(idx));
		OSCFunc({ |msg| synth.set(\pitch_lfo_freq,  2 ** msg[1])                   }, "/%/plrt".format(idx));
		OSCFunc({ |msg| synth.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12))  }, "/%/plam".format(idx));
		OSCFunc({ |msg| synth.set(\flt_lfo_freq,    2 ** msg[1])                   }, "/%/flrt".format(idx));
		OSCFunc({ |msg| synth.set(\flt_lfo_level,   msg[1].linlin(0, 255, 0, 10000)) }, "/%/flam".format(idx));
		OSCFunc({ |msg| synth.set(\color_lfo_freq,  2 ** msg[1])                   }, "/%/clrt".format(idx));
		OSCFunc({ |msg| synth.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1))   }, "/%/clam".format(idx));
		OSCFunc({ |msg| synth.set(\timbre_lfo_freq,  2 ** msg[1])                  }, "/%/tlrt".format(idx));
		OSCFunc({ |msg| synth.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1))  }, "/%/tlam".format(idx));

		// Filter type: set all three filter mode flags atomically
		OSCFunc({ |msg|
			var low  = (msg[1] == 0).asInteger;
			var band = (msg[1] == 1).asInteger;
			var high = (msg[1] == 2).asInteger;
			synth.set(\low, low, \band, band, \high, high);
		}, "/%/ftyp".format(idx));
	};
};

