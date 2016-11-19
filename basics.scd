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
		~outFB = Bus.control(s);//the output (pre volume)
		//Always pass only necessary busses into Synth, as the SynthDef CAN'T Out index a subBus!!!
		~outLFO = Bus.audio(s);

		// Make default window
		~cont.value("General Hi (MIDI ch 1)",  {
			~save.value;
			~running = false;
			~midiMon = nil;//close monitor connection
			~sync.clear;
			s.quit;
			Window.closeAll;
			MIDIClient.disposeClient;
			MIDIIn.disconnectAll;
			~midiCC.do { |i|
				i.free;//free bus allocation IDs
			};
			~outFB.free;
			~outLFO.free;
		});

		~resid = 0.0;

		~tick = { arg beats, time, clock;
			~midiCC[0].get({ arg iBus;
				~midiCC[1].get({ arg jBus;
					~sync.tempo = iBus[2] / 60 * jBus[1];//master tempo
					//~sync.tempo.postln;
					//N.B. ==========================================
					// WARNING: There is a one beat scheduling delay
					//===============================================
					Synth(\lfo);
					Synth(~envArr[iBus[~noteIdx + 24].floor], [ key: iBus[~noteIdx + 16] + jBus[~stepIdx + 16] ]);
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

		//N.B.==================================
		// WARNING: Any parameter to a SynthDef
		//======================================
		// They will become (UGens via?) an OutputProxy controls. This will prevent array indexing, BAD?!!
		// and other things depending on the scalar nature of integers.
		// Kind of obvious when you think deeper about how the server runs.

		SynthDef(\hi, { arg key = 0, r = 1, l = 1;//last for variants
			var iBus = ~midiCC[0];//Get the instrument bus
			var mBus = ~midiCC[1];//The modulation bus

			var note = iBus.kr(1, 6) + 69 + key + (mBus.kr(1, 5) / 100 * 3 * ~outLFO.ar);//Base midi note
			var hz = note.midicps;//Base with note multiplier

			var out = ~outFB.kr;//Get feedback bus

			var rl = 1 / iBus.kr(1, 2) * 400;
			var stip = out * (iBus.kr(1, 5) / 200).lag * (1 - (mBus.kr(1, 4).lag / 100 * ~outLFO.ar).squared) +
			PinkNoise.ar * mBus.kr(1, 9) / 100;// <5
			var pm = iBus.kr(1, 7) / 100 * out * (1 - (mBus.kr(1, 6).lag / 100 * ~outLFO.ar).squared);

			var env = EnvGen.kr(Env.perc(0.01, r * rl, l), doneAction: 2);
			var polEnv = (env * mBus.kr(1, 8) / 100 * 12).midiratio.lag;
			var filt = ((hz * (iBus.kr(1, 8).midiratio)).lag * (1 + stip)) * polEnv;//Pop elimination
			var plEnv = (env * mBus.kr(1, 10) / 100) + 1;

			var sh2 = (env * mBus.kr(1, 12) / 100) + 1;
			var sh9 = (env * mBus.kr(1, 13) / 100) + 1;
			var sh5 = (env * mBus.kr(1, 14) / 100) + 1;
			var sh17 = (env * mBus.kr(1, 15) / 100) + 1;

			var subz = SinOsc.ar( hz / 2, stip, iBus.kr(1, 12) * sh2 / 50) +
			SinOsc.ar( hz / 9, stip, iBus.kr(1, 13) * sh9 / 50) + //The nine fix. Both pseudo and real Fermat in one.
			SinOsc.ar( hz / 5, stip, iBus.kr(1, 14) * sh5 / 50) +
			SinOsc.ar( hz / 17, stip, iBus.kr(1, 15) * sh17 / 50);

			var osc = SinOsc.ar(hz, pm + subz, env);
			var lpf = LPF.ar(osc, filt);

			var q = (((osc - lpf) * lpf * osc * iBus.kr(1, 10) / 10 * plEnv) + lpf).clip(-1.0, 1.0);//hard
			//A nicked cubic clip with end differential matching.
			var plate = q * (3 - q.squared) / 3;//softer
			var link = LPF.ar(plate, filt);

			var ac = (link * iBus.kr(1, 9) / 100) + (plate * (1 - (iBus.kr(1, 9) / 100)));
			var thEnv = (env * mBus.kr(1, 11) / 100 * 12).midiratio;
			var order = HPF.ar(ac, (iBus.kr(1, 11).lag * 0.0095 + 0.05) * filt * thEnv);//DC removal and low cut
			var postLFO = order * (1 - (mBus.kr(1, 3).lag / 100 * ~outLFO.ar).squared);

			Out.kr(~outFB, postLFO);//Synthesis complete

			//Render out
			OffsetOut.ar(~outBusBase, (postLFO * (iBus.kr(1, 4).dbamp))!2);//output audio
		},
		variants: (
			null: [r: 0.01, l: 0],
			note: [r: 1],
			accent: [r: 1, l: 2],
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

		~ratioSpec = ControlSpec(1, 8, \lin, 1, 1);
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
		~knob.value("Pink", Color.green, ~modSpec);
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
			var oneTick = 1 / (cBus.kr(1, 2) / 60 * lBus.kr(1, 1));
			var hz = oneTick * lBus.kr(1, 2);//Rate adjusted LFO
			OffsetOut.ar(~outLFO, SinOsc.ar(hz, EnvGen.kr(Env.linen(0.01, oneTick * lBus.kr(1, 7) / 20, 0.5), doneAction: 2)));
		}).add;//DON'T FORGET TO ADD!!!!!!

		//==================
		// EFFECTS GUI Sift
		//==================

		//row 1 - Basic Controls
		~cont.value("Sargent Sift (MIDI ch 3)");

		~knob.value("Left", Color.yellow, ~modSpec);
		~knob.value("LTone", Color.green, ~modSpec);
		~knob.value("LRoute", Color.yellow, ~modSpec);

		~knob.value("Right", Color.yellow, ~modSpec);
		~knob.value("RTone", Color.green, ~modSpec);
		~knob.value("RRoute", Color.yellow, ~modSpec);

		~knob.value("SRoute", Color.yellow, ~modSpec);
		~knob.value("Paths", Color.red, ~modSpec);

		//row 2 - Effects 1 and 2
		~knob.value("A", Color.cyan, ~polSpec);
		~knob.value("B", Color.cyan, ~modSpec);
		~knob.value("C", Color.cyan, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		~knob.value("A", Color.magenta, ~polSpec);
		~knob.value("B", Color.magenta, ~polSpec);
		~knob.value("C", Color.magenta, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		//row 3 - Effects 3 and 4
		~knob.value("A", Color.white, ~polSpec);
		~knob.value("B", Color.white, ~modSpec);
		~knob.value("C", Color.white, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		~knob.value("A", Color.grey, ~polSpec);
		~knob.value("B", Color.grey, ~polSpec);
		~knob.value("C", Color.grey, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		//row 4 - Effects 5 and Stereo Controls
		~knob.value("A", Color.blue, ~polSpec);
		~knob.value("B", Color.blue, ~modSpec);
		~knob.value("C", Color.blue, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		~knob.value("A", Color.red, ~polSpec);
		~knob.value("B", Color.yellow, ~polSpec);
		~knob.value("C", Color.green, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);



		//================
		// DRUMS GUI Beat
		//================

		//row 1 - Basic Controls
		~cont.value("Corporal Beat (MIDI ch 4)");

		~knob.value("Left", Color.yellow, ~modSpec);
		~knob.value("LTone", Color.green, ~modSpec);
		~knob.value("LRoute", Color.yellow, ~modSpec);

		~knob.value("Right", Color.yellow, ~modSpec);
		~knob.value("RTone", Color.green, ~modSpec);
		~knob.value("RRoute", Color.yellow, ~modSpec);

		~knob.value("SRoute", Color.yellow, ~modSpec);
		~knob.value("Paths", Color.red, ~modSpec);

		//row 2 - Effects 1 and 2
		~knob.value("A", Color.cyan, ~polSpec);
		~knob.value("B", Color.cyan, ~modSpec);
		~knob.value("C", Color.cyan, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		~knob.value("A", Color.magenta, ~polSpec);
		~knob.value("B", Color.magenta, ~polSpec);
		~knob.value("C", Color.magenta, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		//row 3 - Effects 3 and 4
		~knob.value("A", Color.white, ~polSpec);
		~knob.value("B", Color.white, ~modSpec);
		~knob.value("C", Color.white, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		~knob.value("A", Color.grey, ~polSpec);
		~knob.value("B", Color.grey, ~polSpec);
		~knob.value("C", Color.grey, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		//row 4 - Effects 5 and Stereo Controls
		~knob.value("A", Color.blue, ~polSpec);
		~knob.value("B", Color.blue, ~modSpec);
		~knob.value("C", Color.blue, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);

		~knob.value("A", Color.red, ~polSpec);
		~knob.value("B", Color.yellow, ~polSpec);
		~knob.value("C", Color.green, ~polSpec);
		~knob.value("Mix", Color.green, ~polSpec);



		//=====================================
		// MIDI 5 - 12
		//=====================================

		~contHolder.value("");//5
		~contHolder.value("");//6
		~contHolder.value("");//7
		~contHolder.value("");//8

		~contHolder.value("");//9 - Emergency ...
		~contHolder.value("");//10 - Drums 2 ...
		~contHolder.value("");//11 - The imagination machine ...
		~contHolder.value("");//12 - Loose ends

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

		//The following machine does tempo synced control remapping. There is 8 four controls parts.
		//In, out, ctl, gain ... So chan (note vs bend polar), one of 16, one of 32, gain (polar).
		//If you have more than 8 keyboards ... :(
		//=============================
		// PITCH MOD AND NOTE REMAPPER
		//=============================

		~contHolder.value("Sparkie (MIDI ch 14)");//14

		//=====================================
		// MIDI 15
		//=====================================

		~contHolder.value("");//15


		//============
		// Notary Nob
		//============
		~cont.value("Notary Nob (MIDI ch 16)");//16
		~hello = StaticText(~win, 434@374);
		~hello.font = ~fontOff;
		~hello.align = \center;
		~hello.string = "<h1>Hello, and welcome to the basics synthesizers.</h1><br><br>Channel 16 helps use notes as controllers. To close use the <b>General Hi</b> close button, as the other close buttons do not work. General Hi controls the main tempo.<br><br>This software is by <a href=\"http:/kring.co.uk\">K Ring Technologies Ltd.</a> and the hope is you enjoy.<br><br>The coding was done by Simon Jackson over a few months. There are no classes defined in the code so as to make it a simple single portable file.<br><br>There is no particular versioning system apart from an up to date master branch.";


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

		//============================================================================
		// REDIRECTS CH16 (NOTE CONTROLLER) AND CH15 (BEND AND AFTERTOUCH CONTROLLER)
		//============================================================================
		//Synthetic controllers, on channel 16, lower 16 as note ratio, and higher (+16) as last velocity
		//Bend and aftertouch (mono) on channel 15 synthetics. Tone lower 16, touch (+16)

		~midiCCBend = ControlSpec(1 / 64, 64, \exp);

		~tuneReq = { 32.do { arg i;
			~midiCCSpec[15][i] = ~midiCCBend;
			~midiCC[15].subBus(i).set(1.0);
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
				/* spec = ~midiCCSpec[15][chan + 15];
				bus = ~midiCC[15].subBus(chan + 16);
				bus.set(spec.map(vel / 127)); */
			});
		});

		/* //Like above.
		MIDIFunc.noteOff({
		//NEVER NEEDED IN THIS SYNTH MODEL
		}); */

		//Feed into tune control.
		//Center 2000 hex
		MIDIFunc.bend({
			arg bend, chan, uid;
			if(uid == ~midiSrc, {//expression is not function (as while and case would be).
				var spec = ~midiCCSpec[15][chan + 16];//synthetic
				var bus = ~midiCC[15].subBus(chan + 16);
				bus.set(spec.map((bend - 8192) / 8192 / 2 + 0.5));
			});
		});

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