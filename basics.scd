//generic synth template
//(C)2016 K Ring Technologies Ltd, Simon Jackson

//Notes for the brave.
//--------------------
//I have not created any classes, as this requires Quarks and installing into the compiled class base.
//I have used functions as classes, and provided some common control constructors.
//Happy coding!

~outBusBase = 0;
~path = PathName(thisProcess.nowExecutingPath).parentPath;//for +/+

//=============
// READ CONFIG
//=============
~configAll = nil;

~load = { arg name = "startup.sesh";
	var what = ~path +/+ name;
	var ev = {
		File.use(what, "a+", { |f|
			//Append, so ...
			f.seek;
			~configAll = f.readAllString;
			//parse?
		});
	};
	if(~running, { if(name == nil, { Dialog.openPanel({ |f| what = f; ev.value; } , { }); }, ev) });
};

~save = { arg name = "startup.sesh";
	var what = ~path +/+ name;
	var ev = {
		File.use(what, "w", { |f|
			//write
			f.write(~configAll);//Write out a premade string
		});
	};
	if(~running, { if(name == nil, { Dialog.savePanel({ |f| what = f; ev.value; } , { }); }, ev) });
};

//=========================
// START AND TEMPLATE CTRL
//=========================
s = Server.default;
s.boot;

//=======================
// MAIN MIDI CONTROL BUS
//=======================
//All buses are spec range buses based on spec mappings belew.
//
~midiCC = Array.fill(16, {
	Bus.control(s, 32);
});//32 controllers and 16 channels

//=========
// CC SPEC
//=========
~midiCCSpec = Array.fill(16, { Array.fill(32, { ControlSpec() }) });//32 controllers and 16 channels

//=========
// PRESETS
//=========
~presets = Array.fill(129, { Array.fill(16, { Array.fill(32, 0) }) });//128 presets each plus default

//=============================
//MASTER CLOCK AND WIN COUNTER
//=============================
~sync = TempoClock(1);
~win = nil;
~winCnt = 0;
~ctlCnt = 0;
~rowCnt = 0;

~noteIdx = 0;
~stepIdx = 0;
// BEWARE STATIC ITERATORS!! THEY BE CLONES ===
~fonty = Array.fill(16, { Array.fill(8, { nil }) });//Allows for upto 16 rows of note buttons, avaraging 1 row per instrument

~envArr = [
	'hi.null',
	'hi.note',
	'hi.accent',
	'hi.long',
	'hi.blip'
];

~fillArr = [
	[ 0, 1, 2, 3, 4, 5, 6, 7 ],//0
	[ 0, 3, 2, 1, 4, 7, 6, 5 ],//1
	[ 4, 5, 2, 7, 1, 2, 6, 4 ],//2
	[ 0, 5, 2, 7, 4, 1, 6, 3 ],//3
	[ 0, 1, 4, 5, 2, 3, 6, 7 ]//4
];

~fontOn = Font(Font.default.name, 30);//note on!!
~fontOff = Font(Font.default.name, 15);//regular size

//====================
// A WINDOW CONTAINER
//====================
~winSpace = 25;
~xmulSpace = 2.5;

~cont = { arg label = "is?", close = nil;
	var x, y, w;
	x = (Window.screenBounds.width / 2) + (~winSpace * (~winCnt - 8) * ~xmulSpace) - 220;
	y = (Window.screenBounds.height / 2) - (~winSpace * (~winCnt - 8)) - 170;
	~win = Window(label, Rect(x, y, 440, 380), false);
	~winCnt = ~winCnt + 1;
	~win.front;
	if(close == nil, { ~win.userCanClose = false; }, {
		~win.onClose = close;
		~win.alwaysOnTop = true;
	});//Always on top first window (asCloseMaster)
	~win.view.decorator = FlowLayout(~win.view.bounds, 6@4);
	~win;//out
};

~contHolder = { arg label;
	~winCnt = ~winCnt + 1;
	~ctlCnt = ~winCnt * 32;//To ease development
};

~knob = { arg label = "is?", color, spec;
	var ref = EZKnob(~win, label: label, controlSpec: spec);
	var chan = ~ctlCnt.div(32);
	var ctl = ~ctlCnt % 32;
	~midiCCSpec[chan][ctl] = spec;//Set control spec of bus
	ref.action = {
		~midiCC[chan].subBus(ctl).set(ref.value);//Set bus
	};
	ref.setColors(knobColors: [ color, Color.black, Color.white, Color.black ]);
	ref.doAction;//eval once
	~ctlCnt = ~ctlCnt + 1;
	ref;
};

~butt = { arg state = "is?", colors = [ Color.white ], actions = [{ }];
	var ref = Button(~win, 50@90);
	var spec = ControlSpec(0, actions.size - 1, \lin, 1, 0);
	var chan = ~ctlCnt.div(32);
	var ctl = ~ctlCnt % 32;
	~midiCCSpec[chan][ctl] = spec;//Set control spec of bus
	ref.action = {
		~midiCC[chan].subBus(ctl).set(ref.value);//Set bus
		//~midiCC[chan].get.postln;
		actions.at(ref.value % actions.size).value(ref.value);
	};
	ref.font = ~fontOff;
	ref.states = colors.collect({ arg it, i;
		[ state, Color.black, colors.at(i) ];
	});
	ref.doAction;//eval once
	~ctlCnt = ~ctlCnt + 1;
	ref;
};

~midiMon = Array.fill(32, { nil; });

~ctlShow = {
	var ref = LevelIndicator(~win, 50@90);
	var spec = ControlSpec(0, 127, \lin);
	var chan = ~ctlCnt.div(32);
	var ctl = ~ctlCnt % 32;
	ref.warning = 1.0;
	ref.critical = 1.0;
	~midiCCSpec[chan][ctl] = spec;//Set control spec of bus
	~ctlCnt = ~ctlCnt + 1;
	ref;
};

//Private utility used below
~noteButt = { arg i;
	var butt = ~butt.value(
		i.asDigit,
		[ Color.grey, Color.red, Color.yellow, Color.green, Color.blue ]);
	butt;
};

~noteButts = {
	8.do { arg i;
		~fonty[~rowCnt][i] = ~noteButt.value(i);//make 8 note keys
	};
	~rowCnt = ~rowCnt + 1;
};

~noteSpec = ControlSpec(-24, 24, \lin, 1, 0);

~noteKnobs = {
	8.do { arg i;
		~knob.value("@" ++ i.asDigit, Color.blue, ~noteSpec);
	};
};



//======================
// CONSTRUCT GLOBAL GUI
//======================
(
s.doWhenBooted({
	~running = false;
	"BOOT COMPLETE!".postln;

	//==============
	// SYNTH GUI Hi
	//==============
	(
		//FB VIA A BUS
		//Surprising use of control buss gets sampling FB at audio rate (with 1 sample delay?)
		//~outFB = Bus.control(s, 8);//the output (pre volume)
		//Always pass only necessary busses into Synth, as the SynthDef CAN'T Out index a subBus!!!
		~outLFO = Bus.audio(s);

		// Make default window
		~cont.value("General Hi (MIDI ch 1)",  {
			~lChan.free;
			~rChan.free;
			~mixChan.free;
			~save.value;
			~sync.clear;
			~running = false;
			~midiMon = nil;//close monitor connection
			s.quit;
			Window.closeAll;
			MIDIClient.disposeClient;
			MIDIIn.disconnectAll;
		});

		~resid = 0.0;

		~tick = { arg beats, time, clock;
			if(~running, {//prevent race on initialization
				~midiCC[3].get({ arg dBus;
					~midiCC[4].get({ arg pBus;
						~midiCC[5].get({ arg gBus;
							8.do { arg num;
								var v = dBus[num] / 100;
								var l = dBus[num + 8] / 100;// /0?
								var r = dBus[num + 16] / 100;
								var p = dBus[num + 24].floor;
								var pat = (p * 8) - 8 + ~stepIdx;//got pattern control index
								var id = (((~stepIdx * 8 + ~noteIdx) * gBus[pat]) % 8).floor;
								//got major drum detail
								p = (p * 8) - 8 + id;//got amplitude index
								if(p >= 0, { p = pBus[p] / 100; }, { p = 0; });//got amplitude
								Synth(\drum, [ v: v, l: l, r: r,  p: p ]);
							};
						});
					});
				});
			});
			if(~running, {//prevent race on initialization
				~midiCC[0].get({ arg iBus;
					~midiCC[1].get({ arg jBus;
						var fill = ~fillArr[jBus[~stepIdx + 24].floor];//The fill
						var note = fill[~noteIdx];//The note of the fill
						~sync.tempo = iBus[2] / 60 * jBus[1];//master tempo
						//~sync.tempo.postln;
						//N.B. ==========================================
						// WARNING: There is a one beat scheduling delay
						//===============================================
						Synth(\lfo);
						Synth(~envArr[iBus[note + 24].floor],
							[ key: iBus[note + 16] + jBus[~stepIdx + 16] ]);
						//Seems to be a sync scheduling bug, making Synth play on the tick after it get scheduled.
						//I think this is to do with the tick already having passed at the schedule, and jitter effect
						//cancellation.
						AppClock.play({
							~fonty[0][(~noteIdx + 6) % 8].font = ~fontOff;//Hence previous but one "offed"
						});
						AppClock.play({
							~fonty[0][(~noteIdx + 7) % 8].font = ~fontOn;//Hence previous note "displayed"
							if(~noteIdx == 0) {
								~fonty[1][~stepIdx].font = ~fontOn;
								~fonty[1][(~stepIdx + 7) % 8].font = ~fontOff;
							};
						});
						~noteIdx = (~noteIdx + 1) % 8;
						if(~noteIdx == 0) { ~stepIdx = (~stepIdx + 1) % 8; };
						~resid = ((iBus[3] / 5000).bilinrand - ~resid) * 0.95;
						//~resid.postln;
					});
				});
			});
			1 + ~resid;//with retrig -- here!!
		};

		//row 1
		~butt.value("RUN", [ Color.red, Color.green ], [
			{ ~sync.clear; },
			{
				~fonty[0][(~noteIdx + 7) % 8].font = ~fontOff;
				~fonty[1][~stepIdx].font = ~fontOff;
				~noteIdx = 0;
				~stepIdx = 0;
				~fonty[1][0].font = ~fontOn;
				~sync.play(~tick); }
		]);
		~butt.value("MUTE", [ Color.green, Color.red ], [
			{ s.unmute; },
			{ s.mute; }
		]);

		~bpmSpec = ControlSpec(30, 300, \lin, 1, 240);
		~modSpec = ControlSpec(0, 100, \lin, 0, 0);
		~volSpec = ControlSpec(-inf, 0, \db, 0, -12);

		~knob.value("Tempo", Color.red, ~bpmSpec);
		~knob.value("Jiggle", Color.yellow, ~modSpec);

		~knob.value("Volume", Color.yellow, ~volSpec);
		~knob.value("Stiple", Color.green, ~modSpec);

		~knob.value("Tune", Color.red, ~noteSpec);
		~knob.value("Buzz", Color.green, ~modSpec);

		//Row 2

		//one octave up filter
		~filterSpec = ControlSpec(-12, 36, \lin, 0, 12);
		~knob.value("Filter", Color.yellow, ~filterSpec);
		~knob.value("Order", Color.yellow, ~modSpec);
		~knob.value("Plate", Color.yellow, ~modSpec);
		~knob.value("Thin", Color.yellow, ~modSpec);

		~knob.value("SB2", Color.green, ~modSpec);
		~knob.value("SB9", Color.green, ~modSpec);
		~knob.value("SB5", Color.green, ~modSpec);
		~knob.value("SB17", Color.green, ~modSpec);

		//row 3 and 4
		~noteKnobs.value;

		~noteButts.value;

		~synth = Bus.audio(s);//Summation bus.

		~phi5 = (5.sqrt + 1) / 2;

		//N.B.==================================
		// WARNING: Any parameter to a SynthDef
		//======================================
		// They will become (UGens via?) an OutputProxy controls. This will prevent array indexing, BAD?!!
		// and other things depending on the scalar nature of integers.
		// Kind of obvious when you think deeper about how the server runs.

		SynthDef(\hi, { arg key = 0, r = 1, l = 1;//last for variants
			var iBus = ~midiCC[0];//Get the instrument bus
			var mBus = ~midiCC[1];//The modulation bus

			var note = iBus.kr(1, 6) + 69 + key + (mBus.kr(1, 5) / 100 * ~outLFO.ar);//Base midi note
			var hz = note.midicps;//Base with note multiplier

			//var out = ~outFB.kr(1, fbidx);//Get feedback bus

			var rl = 1 / iBus.kr(1, 2) * 400;
			var stip = ((iBus.kr(1, 5) / 100) * (1 - (mBus.kr(1, 4) / 100 * ~outLFO.ar))); //+
//				//(PinkNoise.ar * mBus.kr(1, 9) / 100));// <5
			var pm = iBus.kr(1, 7) / 100 * (1 - (mBus.kr(1, 6).lag / 100 * ~outLFO.ar));

			var env = EnvGen.kr(Env.perc(0.1, r * rl, l), doneAction: 2);
			var polEnv = (env * mBus.kr(1, 8) / 100 * 12).midiratio.lag;

			var plEnv = (env * mBus.kr(1, 10) / 100) + 1;
			var ordenv = (1 - (env * mBus.kr(1, 9) / 100)) * (iBus.kr(1, 9) / 100);

			var sh2 = (env * mBus.kr(1, 12) / 100) + 1;
			var sh9 = (env * mBus.kr(1, 13) / 100) + 1;
			var sh5 = (env * mBus.kr(1, 14) / 100) + 1;
			var sh17 = (env * mBus.kr(1, 15) / 100) + 1;

			var subz = SinOscFB.ar(hz / 2, stip, iBus.kr(1, 12) * sh2 / 25) +
			SinOscFB.ar(hz / 9, stip, iBus.kr(1, 13) * sh9 / 100) + //The nine fix. Both pseudo and real Fermat in one.
			SinOscFB.ar(hz / 5, stip, iBus.kr(1, 14) * sh5 / 25) +
			SinOscFB.ar(hz / 17, stip, iBus.kr(1, 15) * sh17 / 100);
			var mix = SinOscFB.ar(hz * ~phi5, subz, pm);//interesting

			var osc = SinOsc.ar(hz, mix + subz, env);
			var filt = ((hz * (iBus.kr(1, 8).midiratio)).lag * (1 + (stip / 2 * osc))) * polEnv;//Pop elimination
			var lpf = LPF.ar(osc, filt);

			var q = (((osc - lpf) * lpf * osc * iBus.kr(1, 10) / 10 * plEnv) + lpf).clip(-1.0, 1.0);//hard
			//A nicked cubic clip with end differential matching.
			var plate = q * (3 - q.squared) / 2;//softer
			var link = LPF.ar(plate, filt);

			var ac = (link * ordenv) + (plate * (1 - ordenv));
			var thEnv = (env * mBus.kr(1, 11) / 100 * 12).midiratio.lag;
			var order = HPF.ar(ac, (1 + (iBus.kr(1, 11).lag / 100 * 32)) * filt / 33 * thEnv);//DC removal and low cut
			var postLFO = order * (1 - (mBus.kr(1, 3).lag / 100 * ~outLFO.ar));

//			Out.kr(fbbus, postLFO);//Synthesis complete

			//Render out
			Out.ar(~synth, postLFO * (iBus.kr(1, 4).dbamp) / 3);//Output audio, of 8 chan estimate of Gauss
		},
		variants: (
			null: [r: 0.01, l: 0],
			note: [r: 1],
			accent: [r: 1, l: 1.6],
			long: [r: 3],
			blip: [r: 0.3])
		).add;

		//================
		// SYNTH GUI HiHo
		//================

		//row 1 - Basic LFO application
		~cont.value("Captain HiHo (MIDI ch 2)");
		MIDIClient.init;
		~midiSrc = 0;

		~midiFix = {
			~midiCC[1].subBus(0).get({ |v|
				~midiSrc = MIDIClient.sources[v.floor].asMIDIInPortUID;
		});
		};

		~midiSpec = ControlSpec(0, max(MIDIClient.sources.size - 1, 0), \lin, 1, 0);
		~knob.value("MIDI Src", Color.red, ~midiSpec);

		~ratioSpec = ControlSpec(1, 4, \lin, 1, 1);
		~lfoSpec = ControlSpec(0, 8, \lin, 1/4, 1);
		~knob.value("Speed", Color.red, ~ratioSpec);
		~knob.value("LFO", Color.yellow, ~lfoSpec);

		~polSpec = ControlSpec(-100, 100, \lin, 0, 0);//polar modulation spec
		~knob.value("VolMod", Color.yellow, ~modSpec);//Keeping bounds
		~knob.value("StipMod", Color.green, ~modSpec);
		~knob.value("TuneMod", Color.red, ~polSpec);
		~knob.value("BuzzMod", Color.green, ~modSpec);

		~knob.value("Length", Color.red, ~modSpec);

		//row 2 - Program (control timbrals of Hi)
		~knob.value("FiltEnv", Color.yellow, ~polSpec);
		~knob.value("OrdEnv", Color.green, ~modSpec);
		~knob.value("PlatEnv", Color.yellow, ~polSpec);
		~knob.value("ThinEnv", Color.yellow, ~polSpec);
		~knob.value("Mod2", Color.green, ~polSpec);
		~knob.value("Mod9", Color.green, ~polSpec);
		~knob.value("Mod5", Color.green, ~polSpec);
		~knob.value("Mod17", Color.green, ~polSpec);

		//row 3 - Song (control tonals of Hi)
		~noteKnobs.value;

		//row 4 - Sequence (control temporals of Hi)
		~noteButts.value;

		SynthDef(\lfo, {
			var cBus = ~midiCC[0];
			var lBus = ~midiCC[1];
			var oneTick = (cBus.kr(1, 2) / 60 * lBus.kr(1, 1)) / 8;
			var hz = oneTick * lBus.kr(1, 2);//Rate adjusted LFO
			Out.ar(~outLFO, SinOsc.ar(hz, EnvGen.kr(Env.linen(0, 8 / oneTick * lBus.kr(1, 7) / 100, 0), doneAction: 2)));
		}).add;//DON'T FORGET TO ADD!!!!!!

		//==================
		// EFFECTS GUI Sift
		//==================

		//row 1 - Basic Controls
		~cont.value("Sargent Sift (MIDI ch 3)");

		~boostSpec = ControlSpec(-inf, 24, \db, 0, 12);
		//Left In Preamp
		~knob.value("SPan", Color.yellow, ~polSpec);
		~knob.value("Left", Color.yellow, ~volSpec);
		~knob.value("LFuzz", Color.green, ~boostSpec);
		~knob.value("LPan", Color.yellow, ~polSpec);

		//Right In Preamp
		~knob.value("Right", Color.yellow, ~volSpec);
		~knob.value("RFuzz", Color.green, ~boostSpec);
		~knob.value("RPan", Color.yellow, ~polSpec);
		~knob.value("DPan", Color.yellow, ~polSpec);

		~left = Bus.audio(s);
		~right = Bus.audio(s);
		~drums = Bus.audio(s);

		SynthDef(\preamp, { arg input, output, base;
			var in = SoundIn.ar(input);
			var cBus = ~midiCC[2];//the controls
			var gain = cBus.kr(1, 0 + base).dbamp;
			var fuzz = cBus.kr(1, 1 + base).dbamp;
			var sig = (in * fuzz).clip(-1.0, 1.0);
			var soft = sig * (3 - sig.squared) / 2;//soft
			var post = soft * gain;
			Out.ar(output, post);
		}).add;

		//Need to put all other things here

		SynthDef(\mixer, {
			var in1 = ~synth.ar;
			var cBus = ~midiCC[2];//the controls
			var gain = cBus.kr(1, 8).dbamp;
			var fuzz = cBus.kr(1, 9).dbamp;
			var sig = (in1 * fuzz).clip(-1.0, 1.0);
			var soft = sig * (3 - sig.squared) / 2;//soft
			var in2 = ~drums.ar;
			var gain2 = cBus.kr(1, 14).dbamp;
			var fuzz2 = cBus.kr(1, 15).dbamp;
			var sig2 = (in2 * fuzz2).clip(-1.0, 1.0);
			var soft2 = sig2 * (3 - sig2.squared) / 2;//soft
			var post = ((soft * gain) + (soft2 * gain2) + ~left.ar + ~right.ar) / 4;//da mix within unit range
			Out.ar(~outBusBase, post ! 2);
		}).add;

		AppClock.play({
			~lChan = Synth(\preamp, [ input: 0, output: ~left, base: 1 ]);
			~rChan = Synth(\preamp, [ input: 1, output: ~right, base: 4 ]);
			~mixChan = Synth(\mixer);
		});

		//Synth Routing
		~knob.value("Synths", Color.yellow, ~volSpec);
		~knob.value("SFuzz", Color.green, ~boostSpec);

		//row 2 - Effect Shaper
		//https://en.wikipedia.org/wiki/Chebyshev_equation (Evens mul?)
		//https://en.wikipedia.org/wiki/Legendre_polynomials
		//https://en.wikipedia.org/wiki/Bernoulli_polynomials (Offset + Normalize)
		~knob.value("Basis", Color.cyan, ~modSpec);
		~knob.value("Order", Color.cyan, ~modSpec);//Curve set blender
		~knob.value("Odds", Color.cyan, ~modSpec);//Cross mul level
		~knob.value("Pan", Color.yellow, ~polSpec);

		//Drums Routing
		~knob.value("Drums", Color.yellow, ~volSpec);
		~knob.value("DFuzz", Color.green, ~boostSpec);

		//row 3 - Effect Compressor
		~knob.value("Attack", Color.magenta, ~modSpec);
		~knob.value("Decay", Color.magenta, ~modSpec);
		~knob.value("Gain", Color.magenta, ~modSpec);
		~knob.value("Pan", Color.yellow, ~polSpec);

		//row 3 - Effect Flange
		~knob.value("DRatio", Color.white, ~modSpec);
		~knob.value("MRatio", Color.white, ~modSpec);
		~knob.value("Depth", Color.white, ~modSpec);
		~knob.value("Pan", Color.yellow, ~polSpec);

		//row 4 - Effect Delay
		~knob.value("Ratio", Color.blue, ~modSpec);//Tempo locked
		~knob.value("Feedfor", Color.blue, ~polSpec);//All-pass
		~knob.value("Feedback", Color.blue, ~polSpec);//Feedback output vs input (also phase feedback polarity)
		~knob.value("Pan", Color.yellow, ~polSpec);

		//row 4 - Effect Subshift
		~knob.value("Ratio", Color.grey, ~modSpec);//Delay timing
		~knob.value("Down", Color.grey, ~modSpec);//Tuning
		~knob.value("Sectors", Color.grey, ~modSpec);//Amount of overlay sectors (>1)
		~knob.value("Pan", Color.yellow, ~polSpec);



		//================
		// DRUMS GUI Beat
		//================

		~drumKnobs = { arg pre, col, spec;
			8.do { arg i;
				~knob.value(pre ++ (i.asDigit), col, spec);
		}};

		//row 1 - Basic Controls
		~cont.value("Corporal Beat (MIDI ch 4)");

		//Percussive modelling - tension based frequency control
		//Using Leff = sqrt(L^2 + Amp^2)
		//And f = V / Leff
		//And a soft clip compressor
		//By altering the 2 constants L^2 and V ...
		//Then there is the release envekope time R ...
		//And a pattern selector
		~drumKnobs.value("V", Color.yellow, ~modSpec);

		//row 2
		~drumKnobs.value("L", Color.yellow, ~modSpec);

		//row 3
		~drumKnobs.value("R", Color.green, ~modSpec);

		//row 4
		//Selects pattern row in MIDI 5 Stick
		~noteButts.value;

		SynthDef(\drum, { arg v, l, r, p;
			var env = Env.perc(0.05, r * 0.45 + 0.1, p * 1.5);
			var gen = EnvGen.kr(env, doneAction: 2);
			var osc = WhiteNoise.ar(gen);
			var a = BPF.ar(osc, v * 1000 + 50);
			var sig = a.clip(-1.0, 1.0);
			var soft = (1 + (l * 5)) * sig * (3 - sig.squared) / 2;//soft
			var b = BPF.ar(soft, v * 1000 + 50);
			var sig2 = b.clip(-1.0, 1.0);
			var soft2 = sig2 * (3 - sig2.squared) / 2;//soft
			Out.ar(~drums, soft2 / 3);
		}).add;


		//=================
		// DRUMS GUI Stick
		//=================

		//Basically note pattern step volumes
		~cont.value("Private Stick (MIDI ch 5)");

		//Pattern 1
		~drumKnobs.value("@", Color.red, ~modSpec);

		//Pattern 2
		~drumKnobs.value("@", Color.yellow, ~modSpec);

		//Pattern 3
		~drumKnobs.value("@", Color.green, ~modSpec);

		//Pattern 4
		~drumKnobs.value("@", Color.blue, ~modSpec);

		//==================
		// DRUMS GUI Groove
		//==================

		//Basically 8 step pattern control
		~cont.value("Private Groove (MIDI ch 6)");
		~drumSpec = ControlSpec(1, 8, \lin, 0.25, 1);

		//Pattern 1
		~drumKnobs.value("@", Color.red, ~drumSpec);

		//Pattern 2
		~drumKnobs.value("@", Color.yellow, ~drumSpec);

		//Pattern 3
		~drumKnobs.value("@", Color.green, ~drumSpec);

		//Pattern 4
		~drumKnobs.value("@", Color.blue, ~drumSpec);

		//=====================================
		// MIDI 7 - 11
		//=====================================

		~contHolder.value("");//7
		~contHolder.value("");//8

		~contHolder.value("");//9 - Emergency ...
		~contHolder.value("");//10 - Drums 2 ...
		~contHolder.value("");//11 - The imagination machine ...

		//=================
		// PATTERN GUI Pat
		//=================

		~cont.value("Postman Pat (MIDI ch 12)");//12 - Loose ends
		12.do {
			~knob.value("@", Color.red, ~modSpec);
			~butt.value("=", [ Color.gray, Color.red, Color.green ]);
		};
		~noteButts.value;

		//The following machine just IDs your controllers and is a good channel for sending MIDI to null.
		//You could perhaps use 14, 15 and 16, but that could interfere with controllers.
		//==========================
		// THE UNLUCKY MIDI MONITOR
		//==========================

		~cont.value("Unlucky Jack (MIDI ch 13)");//13
		32.do { arg i;
			~midiMon[i] = ~ctlShow.value;
		};

		AppClock.play({
			32.do { arg i;
				if(~midiMon != nil, { ~midiCC[12].subBus(i).get({ arg v;
					AppClock.play({//assume app clock not preemptive of itself
						if(~midiMon != nil, { ~midiMon[i].value = ~midiCCSpec[12][i].unmap(v); } );
						nil;//as integer does looping
					});
				}); });
			};
			if(~midiMon != nil, {
				~midiFix.value;//Update valid midi source
				0.1;
			}, nil);
		});

		//The following machine does tempo synced control remapping
		//So the control is updated on the note play
		//Likely best done by a tempo played synthdef
		//There is 16 controls parts. (one per channel)
		//ctl, gain ... one of 32, and 1/8 to 8 times
		//If you have more than 16 keyboards ... :(
		//===============
		// NOTE REMAPPER
		//===============

		~contHolder.value("Sparkie (MIDI ch 14)");//14

		//ctl, gain
		//===================
		// VELOCITY REMAPPER
		//===================

		~contHolder.value("Fluff (MIDI ch 15)");//15


		//============
		// Notary Nob
		//============
		~cont.value("Notary Nob (MIDI ch 16)");//16
		~hello = StaticText(~win, 434@374);
		~hello.font = ~fontOff;
		~hello.align = \center;
		~hello.string = "<h1>Hello, and welcome to the basics synthesizers.</h1><br><br>Channel 16 helps use notes as controllers. To close use the <b>General Hi</b> close button, as the other close buttons do not work. General Hi controls the main tempo.<br><br>This software is by <a href=\"http:/kring.co.uk\">K Ring Technologies Ltd.</a> and the hope is you enjoy.<br><br>The coding was done by Simon Jackson over a few months. There are no classes defined in the code so as to make it a simple single portable file.";


		//==============
		// MACHINES END
		//==============
		//The notes are remapped onto CC along with velocities. Same goes for bend and mono aftertouch.
		//These are on channels 15 and 16
		~running = true;//All OK to load and save
		~load.value;

	);

	//==============
	// MIDI Handler
	//==============

	// THERE WILL BE NO MIDI OUT
	//---------------------------

	//drums on 10?
	(
		//In pairs for 14 bit resolution?
		//So with 32 controls per machine @ 14 bit, that's 64 controllers per machine.
		//The upper 64-ish are for some unsupported channel mode bull. (I suggest an all notes off in such case.
		//And perhaps a 13 bit blip code. :D ) Just ignore them, or do a remap
		//LSB @ (controller + 32)
		MIDIFunc.cc({
			arg val, ctl, chan, uid;
			if(uid == ~midiSrc, {//expression is not function (as while and case would be).
				//BUS IS ASYNC SO CALLBACK SET
				var bus = ~midiCC[chan].subBus((ctl - 1) % 32);
				var spec = ~midiCCSpec[chan][(ctl - 1) % 32];
				case
				{ ctl < 32 } {//MSB
					bus.get( { arg v;
						//v.postln;
						v = spec.unmap(v) * 16383;//14 bit from 0 to 1
						v = (v % 128) + (128 * val);
						v = spec.map(v / 16383);//back to 0 to 1
						bus.set(v);
					});
				}
				{ ctl < 64 } {//LSB
					bus.get( { arg v;
						v = spec.unmap(v) * 16383;//14 bit from 0 to 1
						v = v.div(128) * 128 + val;
						v = spec.map(v / 16383);//back to 0 to 1
						bus.set(v);
					});
				}
				{ true } { ("CC:" ++ ctl ++ " ON: " ++ (chan + 1)).postln; };//Debug
			});
		});

		//==================================
		// REDIRECTS CH16 (NOTE CONTROLLER)
		//==================================
		//Synthetic controllers, on channel 16, lower 16 as note ratio, and higher (+16) as last velocity
		//After reading through some MIDI keyboard manuals

		~midiCCBend = ControlSpec(1 / 64, 64, \exp, 0, 1);
		~midiVelSpec = ControlSpec(0, 127, \lin, 1, 0);

		~tuneReq = { 16.do { arg i;
			~midiCCSpec[15][i] = ~midiCCBend;
			~midiCC[15].subBus(i).set(1.0);
			~midiCCSpec[15][i + 15] = ~midiVelSpec;
			~midiCC[15].subBus(i + 15).set(0);
		} };

		~tuneReq.value;

		//Must be free, so on system clock?
		//Can immediate cotrol buses, but for synth triggers, que on a TempoClock at midiClock rate.
		//Calc rate Based on tempo PLL.
		MIDIFunc.noteOn({
			arg vel, note, chan, uid;
			if(uid == ~midiSrc, {//expression is not function (as while and case would be).
				var spec = ~midiCCSpec[15][chan];//synthetic
				var bus = ~midiCC[15].subBus(chan);
				//63 is 1.0 -> +6
				bus.set(spec.map((note / 127)) * (-6.midiratio));//D#5
				spec = ~midiCCSpec[15][chan + 15];
				bus = ~midiCC[15].subBus(chan + 16);
				bus.set(spec.map(vel));
			});
		});

		/* //Like above.
		MIDIFunc.noteOff({
		//NEVER NEEDED IN THIS SYNTH MODEL
		}); */

		//Feed into tune control.
		//Center 2000 hex
		//N.B. Usually this can be reassigned
		/* MIDIFunc.bend({
			arg bend, chan, uid;
			if(uid == ~midiSrc, {//expression is not function (as while and case would be).
				var spec = ~midiCCSpec[15][chan + 16];//synthetic
				var bus = ~midiCC[15].subBus(chan + 16);
				bus.set(spec.map((bend - 8192) / 8192 / 2 + 0.5));
			});
		}); */

		/* /A monphonic max pressure event.
		MIDIFunc.touch({
			arg touch, chan, uid;
			if(uid == ~midiSrc.value, {//expression is not function (as while and case would be).
				var spec = ~midiCCSpec[14][chan + 16];//synthetic
				var bus = ~midiCC[14].subBus(chan + 16);
				bus.set(spec.map(touch / 127));
			});
		}); */

		/* //A note aftertouch event.
		MIDIFunc.polytouch({
		//NEVER NEEDED IN THIS SYNTH MODEL
		}); */

		//Patch change timbral
		MIDIFunc.program({

		});

		//+1 @ 6 midi clocks (14 bit) => 4 per Quarter beat => 16 per beat => 1024 beats per song
		// => 128 loops of General Hi ...
		//Use a modulo and subtract one TempoClock!
		//If less than zero, then initial, add one beat and drop 1st!! (while stopped?)
		MIDIFunc.songPosition({

		});

		//Notes change tonal.
		MIDIFunc.songSelect({

		});

		//24 per quater note ... where as "ticks" can get as high as silly, for sync, and can vary.
		MIDIFunc.midiClock({

		});

		//Create midi TempoClock (and drop initial beat)
		MIDIFunc.start({

		});

		//Stop midi TempoClock.
		MIDIFunc.stop({

		});

		//Run midi TempoClock.
		MIDIFunc.continue({

		});

		//Full instrument reset.
		MIDIFunc.reset({

		});

		//Play A 440 tuning tone.
		MIDIFunc.tuneRequest({
			~tuneReq.value;
		});

		//Launch a half second callback, to terminate sound, after killing any existing callback.
		MIDIFunc.activeSense({

		});

		//F0 7E = EOF, ACK, NAK, Wait, Cancel, File Dump Data Packet, File Dump Request
		MIDIFunc.sysex({

		});
	);

	//======
	// EXIT
	//======
	MIDIIn.connectAll;
});
);