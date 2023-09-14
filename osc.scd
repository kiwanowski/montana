var synth1;
var synth2;
var synth3;
var synth4;
var synth5;
var synth6;
var synth7;
var synth8;
var reverb;

s.waitForBoot{
	SynthDef(\braids, { arg pitch = 60, gate = 0, timbre = 0, color = 0, model = 0, freq = 2000, res = 0, low = 1, band = 0, high = 0, rev = 0, attack = 1, release = 1, level = 1, att_pitch = 1, rel_pitch = 1, pitch_level = 0, att_flt = 1, rel_flt = 1, flt_level = 0, pitch_lfo_freq = 1, pitch_lfo_level = 0, flt_lfo_freq = 1, flt_lfo_level = 0, timbre_lfo_freq = 1, timbre_lfo_level = 0, color_lfo_freq = 1, color_lfo_level = 0, tempo = 60;
		var braids;
		var env;
		var filter;
		var pan;
		var env_pitch;
		var env_flt;
		var lfo_pitch;
		var lfo_flt;
		var lfo_timbre;
		var lfo_color;
		lfo_pitch = SinOsc.kr(pitch_lfo_freq * tempo / 240, 0, pitch_lfo_level);
		lfo_flt = SinOsc.kr(flt_lfo_freq * tempo / 240, 0, flt_lfo_level);
		lfo_timbre = SinOsc.kr(timbre_lfo_freq * tempo / 240, 0, timbre_lfo_level);
		lfo_color = SinOsc.kr(color_lfo_freq * tempo / 240, 0, color_lfo_level);
		env = EnvGen.kr(Env.perc(attack, release, level), gate);
		env_pitch = EnvGen.kr(Env.perc(att_pitch, rel_pitch, pitch_level), gate);
		env_flt = EnvGen.kr(Env.perc(att_flt, rel_flt, flt_level), gate);
		braids = MiBraids.ar(pitch + env_pitch + lfo_pitch, timbre + lfo_timbre, color + lfo_color, model, gate);
		filter = SVF.ar(braids, freq + env_flt + lfo_flt, res, low, band, high);
		pan = filter * env;
		Out.ar(0, Pan2.ar(pan, 0));
		Out.ar(4, pan * rev);
	}).add;
	SynthDef(\reverb, { arg time = 0.5, damp = 0.5, hp = 0, freeze = 0, diff = 0.5;
		var reverb;
		reverb = MiVerb.ar(In.ar(4), time, 1, damp, hp, freeze, diff);
		Out.ar(0, reverb);
	}).add;

	s.sync;

	reverb = Synth(\reverb);
	synth1 = Synth(\braids);
	synth2 = Synth(\braids);
	synth3 = Synth(\braids);
	synth4 = Synth(\braids);
	synth5 = Synth(\braids);
	synth6 = Synth(\braids);
	synth7 = Synth(\braids);
	synth8 = Synth(\braids);

    OSCFunc({ arg msg;
        synth1.set(\tempo, msg[1]);
	    synth2.set(\tempo, msg[1]);
	    synth3.set(\tempo, msg[1]);
	    synth4.set(\tempo, msg[1]);
        synth5.set(\tempo, msg[1]);
	    synth6.set(\tempo, msg[1]);
	    synth7.set(\tempo, msg[1]);
	    synth8.set(\tempo, msg[1]);
    }, "/t/temp");

    OSCFunc({ arg msg;
        reverb.set(\time, msg[1].linlin(0, 255, 0, 1.25));
    }, "/r/time");

    OSCFunc({ arg msg;
        reverb.set(\damp, msg[1].linlin(0, 255, 0, 1));
    }, "/r/damp");

    OSCFunc({ arg msg;
        reverb.set(\hp, msg[1].linlin(0, 255, 0, 1));
    }, "/r/hpfl");

    OSCFunc({ arg msg;
        reverb.set(\freeze, msg[1]);
    }, "/r/frez");

    OSCFunc({ arg msg;
        reverb.set(\diff, msg[1].linlin(0, 255, 0, 1));
    }, "/r/diff");

    [synth1, synth2, synth3, synth4, synth5, synth6, synth7, synth8].do { arg synth, synthidx;
        synthidx = synthidx + 1;

        OSCFunc({ arg msg;
            synth.set(\pitch, msg[1]);
            synth.set(\gate, 1);
        }, "/%/nton".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\gate, 0);
        }, "/%/ntof".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
        }, "/%/attk".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\release, msg[1].linexp(0, 255, 0.001, 20));
        }, "/%/rele".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\level, msg[1].linlin(0, 255, 0, 1));
        }, "/%/levl".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\timbre, msg[1].linlin(0, 255, 0, 1));
        }, "/%/tmbr".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\color, msg[1].linlin(0, 255, 0, 1));
        }, "/%/colr".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\model, msg[1]);
        }, "/%/modl".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\freq, msg[1].linexp(0, 255, 20, 20000));
        }, "/%/freq".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\res, msg[1].linlin(0, 255, 0, 1));
        }, "/%/reso".format(synthidx));

        OSCFunc({ arg msg;
            switch(msg[1],
		        0, {
		            synth.set(\low, 1);
			        synth.set(\band, 0);
			        synth.set(\high, 0);
		        },
		        1, {
			        synth.set(\low, 0);
			        synth.set(\band, 1);
			        synth.set(\high, 0);
		        },
		        2, {
			        synth.set(\low, 0);
			        synth.set(\band, 0);
			        synth.set(\high, 1);
		        }
	        );
        }, "/%/ftyp".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\rev, msg[1].linlin(0, 255, 0, 1));
        }, "/%/revb".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
        }, "/%/peat".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
        }, "/%/pede".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
        }, "/%/peam".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
        }, "/%/feat".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
        }, "/%/fede".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
        }, "/%/feam".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\pitch_lfo_freq, pow(2, msg[1]));
        }, "/%/plrt".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
        }, "/%/plam".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\flt_lfo_freq, pow(2, msg[1]));
        }, "/%/flrt".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
        }, "/%/flam".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\color_lfo_freq, pow(2, msg[1]));
        }, "/%/clrt".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
        }, "/%/clam".format(synthidx));

        OSCFunc({ arg msg;
	        synth.set(\timbre_lfo_freq, pow(2, msg[1]));
        }, "/%/tlrt".format(synthidx));

        OSCFunc({ arg msg;
            synth.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
        }, "/%/tlam".format(synthidx));
    };
};

