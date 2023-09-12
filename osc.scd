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

	a = Synth(\reverb);
	b = Synth(\braids);
	c = Synth(\braids);
	d = Synth(\braids);
	e = Synth(\braids);
	f = Synth(\braids);
	g = Synth(\braids);
	h = Synth(\braids);
	i = Synth(\braids);

};

OSCFunc({ arg msg;
    b.set(\tempo, msg[1]);
	c.set(\tempo, msg[1]);
	d.set(\tempo, msg[1]);
	e.set(\tempo, msg[1]);
    f.set(\tempo, msg[1]);
	g.set(\tempo, msg[1]);
	h.set(\tempo, msg[1]);
	i.set(\tempo, msg[1]);
}, '/t/temp');

OSCFunc({ arg msg;
    a.set(\time, msg[1].linlin(0, 255, 0, 1.25));
}, '/r/time');

OSCFunc({ arg msg;
    a.set(\damp, msg[1].linlin(0, 255, 0, 1));
}, '/r/damp');

OSCFunc({ arg msg;
    a.set(\hp, msg[1].linlin(0, 255, 0, 1));
}, '/r/hpfl');

OSCFunc({ arg msg;
    a.set(\freeze, msg[1]);
}, '/r/frez');

OSCFunc({ arg msg;
    a.set(\diff, msg[1].linlin(0, 255, 0, 1));
}, '/r/diff');

OSCFunc({ arg msg;
    b.set(\pitch, msg[1]);
    b.set(\gate, 1);
}, '/1/nton');

OSCFunc({ arg msg;
    b.set(\gate, 0);
}, '/1/ntof');

OSCFunc({ arg msg;
    b.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/1/attk');

OSCFunc({ arg msg;
    b.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/1/rele');

OSCFunc({ arg msg;
    b.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/1/levl');

OSCFunc({ arg msg;
    b.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/1/tmbr');

OSCFunc({ arg msg;
    b.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/1/colr');

OSCFunc({ arg msg;
    b.set(\model, msg[1]);
}, '/1/modl');

OSCFunc({ arg msg;
    b.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/1/freq');

OSCFunc({ arg msg;
    b.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/1/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    b.set(\low, 1);
			b.set(\band, 0);
			b.set(\high, 0);
		},
		1, {
			b.set(\low, 0);
			b.set(\band, 1);
			b.set(\high, 0);
		},
		2, {
			b.set(\low, 0);
			b.set(\band, 0);
			b.set(\high, 1);
		}
	);
}, '/1/ftyp');

OSCFunc({ arg msg;
    b.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/1/revb');

OSCFunc({ arg msg;
    b.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/1/peat');

OSCFunc({ arg msg;
    b.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/1/pede');

OSCFunc({ arg msg;
    b.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/1/peam');

OSCFunc({ arg msg;
    b.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/1/feat');

OSCFunc({ arg msg;
    b.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/1/fede');

OSCFunc({ arg msg;
    b.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/1/feam');

OSCFunc({ arg msg;
    b.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/1/plrt');

OSCFunc({ arg msg;
    b.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/1/plam');

OSCFunc({ arg msg;
    b.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/1/flrt');

OSCFunc({ arg msg;
    b.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/1/flam');

OSCFunc({ arg msg;
    b.set(\color_lfo_freq, pow(2, msg[1]));
}, '/1/clrt');

OSCFunc({ arg msg;
    b.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/1/clam');

OSCFunc({ arg msg;
	b.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/1/tlrt');

OSCFunc({ arg msg;
    b.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/1/tlam');

OSCFunc({ arg msg;
    c.set(\pitch, msg[1]);
    c.set(\gate, 1);
}, '/2/nton');

OSCFunc({ arg msg;
    c.set(\gate, 0);
}, '/2/ntof');

OSCFunc({ arg msg;
    c.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/2/attk');

OSCFunc({ arg msg;
    c.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/2/rele');

OSCFunc({ arg msg;
    c.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/2/levl');

OSCFunc({ arg msg;
    c.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/2/tmbr');

OSCFunc({ arg msg;
    c.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/2/colr');

OSCFunc({ arg msg;
    c.set(\model, msg[1]);
}, '/2/modl');

OSCFunc({ arg msg;
    c.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/2/freq');

OSCFunc({ arg msg;
    c.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/2/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    c.set(\low, 1);
			c.set(\band, 0);
			c.set(\high, 0);
		},
		1, {
			c.set(\low, 0);
			c.set(\band, 1);
			c.set(\high, 0);
		},
		2, {
			c.set(\low, 0);
			c.set(\band, 0);
			c.set(\high, 1);
		}
	);
}, '/2/ftyp');

OSCFunc({ arg msg;
    c.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/2/revb');

OSCFunc({ arg msg;
    c.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/2/peat');

OSCFunc({ arg msg;
    c.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/2/pede');

OSCFunc({ arg msg;
    c.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/2/peam');

OSCFunc({ arg msg;
    c.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/2/feat');

OSCFunc({ arg msg;
    c.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/2/fede');

OSCFunc({ arg msg;
    c.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/2/feam');

OSCFunc({ arg msg;
    c.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/2/plrt');

OSCFunc({ arg msg;
    c.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/2/plam');

OSCFunc({ arg msg;
    c.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/2/flrt');

OSCFunc({ arg msg;
    c.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/2/flam');

OSCFunc({ arg msg;
    c.set(\color_lfo_freq, pow(2, msg[1]));
}, '/2/clrt');

OSCFunc({ arg msg;
    c.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/2/clam');

OSCFunc({ arg msg;
    c.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/2/tlrt');

OSCFunc({ arg msg;
    c.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/2/tlam');

OSCFunc({ arg msg;
    d.set(\pitch, msg[1]);
    d.set(\gate, 1);
}, '/3/nton');

OSCFunc({ arg msg;
    d.set(\gate, 0);
}, '/3/ntof');

OSCFunc({ arg msg;
    d.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/3/attk');

OSCFunc({ arg msg;
    d.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/3/rele');

OSCFunc({ arg msg;
    d.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/3/levl');

OSCFunc({ arg msg;
    d.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/3/tmbr');

OSCFunc({ arg msg;
    d.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/3/colr');

OSCFunc({ arg msg;
    d.set(\model, msg[1]);
}, '/3/modl');

OSCFunc({ arg msg;
    d.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/3/freq');

OSCFunc({ arg msg;
    d.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/3/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    d.set(\low, 1);
			d.set(\band, 0);
			d.set(\high, 0);
		},
		1, {
			d.set(\low, 0);
			d.set(\band, 1);
			d.set(\high, 0);
		},
		2, {
			d.set(\low, 0);
			d.set(\band, 0);
			d.set(\high, 1);
		}
	);
}, '/3/ftyp');

OSCFunc({ arg msg;
    d.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/3/revb');

OSCFunc({ arg msg;
    d.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/3/peat');

OSCFunc({ arg msg;
    d.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/3/pede');

OSCFunc({ arg msg;
    d.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/3/peam');

OSCFunc({ arg msg;
    d.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/3/feat');

OSCFunc({ arg msg;
    d.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/3/fede');

OSCFunc({ arg msg;
    d.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/3/feam');

OSCFunc({ arg msg;
    d.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/3/plrt');

OSCFunc({ arg msg;
    d.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/3/plam');

OSCFunc({ arg msg;
    d.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/3/flrt');

OSCFunc({ arg msg;
    d.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/3/flam');

OSCFunc({ arg msg;
    d.set(\color_lfo_freq, pow(2, msg[1]));
}, '/3/clrt');

OSCFunc({ arg msg;
    d.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/3/clam');

OSCFunc({ arg msg;
    d.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/3/tlrt');

OSCFunc({ arg msg;
    d.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/3/tlam');

OSCFunc({ arg msg;
    e.set(\pitch, msg[1]);
    e.set(\gate, 1);
}, '/4/nton');

OSCFunc({ arg msg;
    e.set(\gate, 0);
}, '/4/ntof');

OSCFunc({ arg msg;
    e.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/4/attk');

OSCFunc({ arg msg;
    e.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/4/rele');

OSCFunc({ arg msg;
    e.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/4/levl');

OSCFunc({ arg msg;
    e.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/4/tmbr');

OSCFunc({ arg msg;
    e.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/4/colr');

OSCFunc({ arg msg;
    e.set(\model, msg[1]);
}, '/4/modl');

OSCFunc({ arg msg;
    e.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/4/freq');

OSCFunc({ arg msg;
    e.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/4/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    e.set(\low, 1);
			e.set(\band, 0);
			e.set(\high, 0);
		},
		1, {
			e.set(\low, 0);
			e.set(\band, 1);
			e.set(\high, 0);
		},
		2, {
			e.set(\low, 0);
			e.set(\band, 0);
			e.set(\high, 1);
		}
	);
}, '/4/ftyp');

OSCFunc({ arg msg;
    e.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/4/revb');

OSCFunc({ arg msg;
    e.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/4/peat');

OSCFunc({ arg msg;
    e.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/4/pede');

OSCFunc({ arg msg;
    e.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/4/peam');

OSCFunc({ arg msg;
    e.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/4/feat');

OSCFunc({ arg msg;
    e.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/4/fede');

OSCFunc({ arg msg;
    e.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/4/feam');

OSCFunc({ arg msg;
    e.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/4/plrt');

OSCFunc({ arg msg;
    e.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/4/plam');

OSCFunc({ arg msg;
    e.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/4/flrt');

OSCFunc({ arg msg;
    e.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/4/flam');

OSCFunc({ arg msg;
    e.set(\color_lfo_freq, pow(2, msg[1]));
}, '/4/clrt');

OSCFunc({ arg msg;
    e.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/4/clam');

OSCFunc({ arg msg;
    e.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/4/tlrt');

OSCFunc({ arg msg;
    e.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/4/tlam');

OSCFunc({ arg msg;
    f.set(\pitch, msg[1]);
    f.set(\gate, 1);
}, '/5/nton');

OSCFunc({ arg msg;
    f.set(\gate, 0);
}, '/5/ntof');

OSCFunc({ arg msg;
    f.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/5/attk');

OSCFunc({ arg msg;
    f.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/5/rele');

OSCFunc({ arg msg;
    f.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/5/levl');

OSCFunc({ arg msg;
    f.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/5/tmbr');

OSCFunc({ arg msg;
    f.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/5/colr');

OSCFunc({ arg msg;
    f.set(\model, msg[1]);
}, '/5/modl');

OSCFunc({ arg msg;
    f.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/5/freq');

OSCFunc({ arg msg;
    f.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/5/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    f.set(\low, 1);
			f.set(\band, 0);
			f.set(\high, 0);
		},
		1, {
			f.set(\low, 0);
			f.set(\band, 1);
			f.set(\high, 0);
		},
		2, {
			f.set(\low, 0);
			f.set(\band, 0);
			f.set(\high, 1);
		}
	);
}, '/5/ftyp');

OSCFunc({ arg msg;
    f.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/5/revb');

OSCFunc({ arg msg;
    f.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/5/peat');

OSCFunc({ arg msg;
    f.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/5/pede');

OSCFunc({ arg msg;
    f.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/5/peam');

OSCFunc({ arg msg;
    f.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/5/feat');

OSCFunc({ arg msg;
    f.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/5/fede');

OSCFunc({ arg msg;
    f.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/5/feam');

OSCFunc({ arg msg;
    f.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/5/plrt');

OSCFunc({ arg msg;
    f.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/5/plam');

OSCFunc({ arg msg;
    f.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/5/flrt');

OSCFunc({ arg msg;
    f.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/5/flam');

OSCFunc({ arg msg;
    f.set(\color_lfo_freq, pow(2, msg[1]));
}, '/5/clrt');

OSCFunc({ arg msg;
    f.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/5/clam');

OSCFunc({ arg msg;
    f.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/5/tlrt');

OSCFunc({ arg msg;
    f.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/5/tlam');

OSCFunc({ arg msg;
    g.set(\pitch, msg[1]);
    g.set(\gate, 1);
}, '/6/nton');

OSCFunc({ arg msg;
    g.set(\gate, 0);
}, '/6/ntof');

OSCFunc({ arg msg;
    g.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/6/attk');

OSCFunc({ arg msg;
    g.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/6/rele');

OSCFunc({ arg msg;
    g.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/6/levl');

OSCFunc({ arg msg;
    g.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/6/tmbr');

OSCFunc({ arg msg;
    g.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/6/colr');

OSCFunc({ arg msg;
    g.set(\model, msg[1]);
}, '/6/modl');

OSCFunc({ arg msg;
    g.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/6/freq');

OSCFunc({ arg msg;
    g.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/6/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    g.set(\low, 1);
			g.set(\band, 0);
			g.set(\high, 0);
		},
		1, {
			g.set(\low, 0);
			g.set(\band, 1);
			g.set(\high, 0);
		},
		2, {
			g.set(\low, 0);
			g.set(\band, 0);
			g.set(\high, 1);
		}
	);
}, '/6/ftyp');

OSCFunc({ arg msg;
    g.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/6/revb');

OSCFunc({ arg msg;
    g.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/6/peat');

OSCFunc({ arg msg;
    g.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/6/pede');

OSCFunc({ arg msg;
    g.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/6/peam');

OSCFunc({ arg msg;
    g.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/6/feat');

OSCFunc({ arg msg;
    g.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/6/fede');

OSCFunc({ arg msg;
    g.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/6/feam');

OSCFunc({ arg msg;
    g.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/6/plrt');

OSCFunc({ arg msg;
    g.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/6/plam');

OSCFunc({ arg msg;
    g.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/6/flrt');

OSCFunc({ arg msg;
    g.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/6/flam');

OSCFunc({ arg msg;
    g.set(\color_lfo_freq, pow(2, msg[1]));
}, '/6/clrt');

OSCFunc({ arg msg;
    g.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/6/clam');

OSCFunc({ arg msg;
    g.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/6/tlrt');

OSCFunc({ arg msg;
    g.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/6/tlam');

OSCFunc({ arg msg;
    h.set(\pitch, msg[1]);
    h.set(\gate, 1);
}, '/7/nton');

OSCFunc({ arg msg;
    h.set(\gate, 0);
}, '/7/ntof');

OSCFunc({ arg msg;
    h.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/7/attk');

OSCFunc({ arg msg;
    h.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/7/rele');

OSCFunc({ arg msg;
    h.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/7/levl');

OSCFunc({ arg msg;
    h.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/7/tmbr');

OSCFunc({ arg msg;
    h.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/7/colr');

OSCFunc({ arg msg;
    h.set(\model, msg[1]);
}, '/7/modl');

OSCFunc({ arg msg;
    h.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/7/freq');

OSCFunc({ arg msg;
    h.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/7/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    h.set(\low, 1);
			h.set(\band, 0);
			h.set(\high, 0);
		},
		1, {
			h.set(\low, 0);
			h.set(\band, 1);
			h.set(\high, 0);
		},
		2, {
			h.set(\low, 0);
			h.set(\band, 0);
			h.set(\high, 1);
		}
	);
}, '/7/ftyp');

OSCFunc({ arg msg;
    h.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/7/revb');

OSCFunc({ arg msg;
    h.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/7/peat');

OSCFunc({ arg msg;
    h.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/7/pede');

OSCFunc({ arg msg;
    h.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/7/peam');

OSCFunc({ arg msg;
    h.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/7/feat');

OSCFunc({ arg msg;
    h.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/7/fede');

OSCFunc({ arg msg;
    h.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/7/feam');

OSCFunc({ arg msg;
    h.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/7/plrt');

OSCFunc({ arg msg;
    h.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/7/plam');

OSCFunc({ arg msg;
    h.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/7/flrt');

OSCFunc({ arg msg;
    h.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/7/flam');

OSCFunc({ arg msg;
    h.set(\color_lfo_freq, pow(2, msg[1]));
}, '/7/clrt');

OSCFunc({ arg msg;
    h.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/7/clam');

OSCFunc({ arg msg;
    h.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/7/tlrt');

OSCFunc({ arg msg;
    h.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/7/tlam');


OSCFunc({ arg msg;
    i.set(\pitch, msg[1]);
    i.set(\gate, 1);
}, '/8/nton');

OSCFunc({ arg msg;
    i.set(\gate, 0);
}, '/8/ntof');

OSCFunc({ arg msg;
    i.set(\attack, msg[1].linexp(0, 255, 0.001, 20));
}, '/8/attk');

OSCFunc({ arg msg;
    i.set(\release, msg[1].linexp(0, 255, 0.001, 20));
}, '/8/rele');

OSCFunc({ arg msg;
    i.set(\level, msg[1].linlin(0, 255, 0, 1));
}, '/8/levl');

OSCFunc({ arg msg;
    i.set(\timbre, msg[1].linlin(0, 255, 0, 1));
}, '/8/tmbr');

OSCFunc({ arg msg;
    i.set(\color, msg[1].linlin(0, 255, 0, 1));
}, '/8/colr');

OSCFunc({ arg msg;
    i.set(\model, msg[1]);
}, '/8/modl');

OSCFunc({ arg msg;
    i.set(\freq, msg[1].linexp(0, 255, 20, 20000));
}, '/8/freq');

OSCFunc({ arg msg;
    i.set(\res, msg[1].linlin(0, 255, 0, 1));
}, '/8/reso');

OSCFunc({ arg msg;
    switch(msg[1],
		0, {
		    i.set(\low, 1);
			i.set(\band, 0);
			i.set(\high, 0);
		},
		1, {
			i.set(\low, 0);
			i.set(\band, 1);
			i.set(\high, 0);
		},
		2, {
			i.set(\low, 0);
			i.set(\band, 0);
			i.set(\high, 1);
		}
	);
}, '/8/ftyp');

OSCFunc({ arg msg;
    i.set(\rev, msg[1].linlin(0, 255, 0, 1));
}, '/8/revb');

OSCFunc({ arg msg;
    i.set(\att_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/8/peat');

OSCFunc({ arg msg;
    i.set(\rel_pitch, msg[1].linexp(0, 255, 0.001, 20));
}, '/8/pede');

OSCFunc({ arg msg;
    i.set(\pitch_level, msg[1].linlin(0, 255, 0, 60));
}, '/8/peam');

OSCFunc({ arg msg;
    i.set(\att_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/8/feat');

OSCFunc({ arg msg;
    i.set(\rel_flt, msg[1].linexp(0, 255, 0.001, 20));
}, '/8/fede');

OSCFunc({ arg msg;
    i.set(\flt_level, msg[1].linlin(0, 255, 0, 10000));
}, '/8/feam');

OSCFunc({ arg msg;
    i.set(\pitch_lfo_freq, pow(2, msg[1]));
}, '/8/plrt');

OSCFunc({ arg msg;
    i.set(\pitch_lfo_level, msg[1].linlin(0, 255, 0, 12));
}, '/8/plam');

OSCFunc({ arg msg;
    i.set(\flt_lfo_freq, pow(2, msg[1]));
}, '/8/flrt');

OSCFunc({ arg msg;
    i.set(\flt_lfo_level, msg[1].linlin(0, 255, 0, 10000));
}, '/8/flam');

OSCFunc({ arg msg;
    i.set(\color_lfo_freq, pow(2, msg[1]));
}, '/8/clrt');

OSCFunc({ arg msg;
    i.set(\color_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/8/clam');

OSCFunc({ arg msg;
    i.set(\timbre_lfo_freq, pow(2, msg[1]));
}, '/8/tlrt');

OSCFunc({ arg msg;
    i.set(\timbre_lfo_level, msg[1].linlin(0, 255, 0, 1));
}, '/8/tlam');