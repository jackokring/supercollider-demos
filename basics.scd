//generic synth template
//(C)2016 K Ring Technologies Ltd, Simon Jackson

//Notes for the brave.
//--------------------
//I have not created any classes, as this requires Quarks and installing into the compiled class base.
//I have used functions as classes, and provided some common control constructors. Some are NOT reentrant.
//Happy coding!

~outBusBase = 0;
~path = PathName(thisProcess.nowExecutingPath).parentPath;//for +/+

//=========================
// START AND TEMPLATE CTRL
//=========================
(
s.boot;
~sync = TempoClock(1);
~patch = Dictionary.new(1024);
~win = nil;
~winCnt = 0;
~noteIdx = 0;
~fonty = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];

~noteMul = [ 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 ];
~envSel = [ 0, 0, 0, 0, 0, 0, 0, 0 ];

~envArr = [
	'hi.null',
	'hi.note',
	'hi.accent',
	'hi.long',
	'hi.blip'
];

~notes = (([ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 ] + 69).midicps) / 440;//an octave
~notes = (~notes / 4) ++ (~notes / 2) ++ (~notes) ++ (~notes * 2) ++ [ 4 ];//full dial range

~fontDef = Font(Font.default.name, 30);//note on!!
~fontTmp = Font(Font.default.name, 15);//regular size

~cont = { arg label = "is?", close = { };
	var x, y;
	x = (Window.screenBounds.width / 2) + (40 * ~winCnt) - 220;
	y = (Window.screenBounds.height / 2) - (40 * ~winCnt) - 170;
	~win = Window(label, Rect(x, y, 440, 380), false);
	~winCnt = ~winCnt + 1;
	~win.front;
	~win.onClose = close;
	~win.view.decorator = FlowLayout(~win.view.bounds, 6@4);
	~win;//out
};

~knob = { arg label = "is?", color = Color.grey, post = { }, spec = ControlSpec(-1, 1, \lin), scale = 1.0;
	var flow;
	var ref = EZKnob(~win, label: label, controlSpec: spec);
	ref.action = {
		flow = scale * ref.value;
		post.value(flow);
	};
	ref.setColors(knobColors: [ color, Color.black, Color.white, Color.black ]);
	ref.doAction;//eval once
	~patch.put(label ++ "-" ++ ~winCnt, ref);
	ref;
};

~butt = { arg state = "is?", colors = [ Color.white ], actions = [{ }];
	var ref = Button(~win, 50@90);
	ref.action = {
		actions.at(ref.value % actions.size).value(ref.value);
	};
	ref.font = ~fontTmp;
	ref.states = colors.collect({ arg it, i;
		[ state, Color.black, colors.at(i) ];
	});
	ref.doAction;//eval once
	~patch.put(state ++ "-" ++ ~winCnt, ref);
	ref;
};

//Below are not reentrant

~noteButt = { arg num = 0;
	var butt = ~butt.value(
		num.asDigit,
		[
			Color.grey, Color.red, Color.yellow, Color.green, Color.blue
		], [{ arg butt;
			~envSel.put(num, butt.value);
			//butt.value.postln; //debug -- language does not support variable references to future closures
			//~noteMul.postln; //ok!
	}]);
	~fonty.put(num, butt);
};

~noteArr = {
	8.do { arg i;
		~noteButt.value(i);//make 8 note keys
	};
};

~noteSpec = ControlSpec(-24, 24, \lin, 1, 0);

~noteKnobs = {
	8.do { arg i;
		~knob.value("@" ++ i.asDigit, Color.blue, { |note| ~noteMul.put(i, ~notes.at(note + 24)); }, ~noteSpec);
	};
};
);

//======================
// CONSTRUCT GLOBAL GUI
//======================
(
s.doWhenBooted({
	"BOOT COMPLETE!".postln;

	//==============
	// SYNTH GUI Hi
	//==============
	(
		// Make default window
		~cont.value("Global Hi (MIDI ch 1)",  {
			~sync.clear;
			s.quit;
			Window.closeAll;
		});
		~win.alwaysOnTop = true;
		~jig = 0.0;
		~resid = 0.0;
		~tick = {arg beats, time, clock;
			//N.B. ==========================================
			// WARNING: There is a one beat scheduling delay
			//===============================================
			//~envSel.at(~noteIdx).postln;//debug -- notes on parameters becoming control UGens
			Synth(~envArr.at(~envSel.at(~noteIdx)), [ \mul, ~noteMul.at(~noteIdx) ]);
			//Seems to be a sync scheduling bug, making Synth play on the tick after it get scheduled.
			//I think this is to do with the tick already having passed at the schedule, and jitter effect
			//cancellation.
			AppClock.play({
				~fonty.at((~noteIdx + 6) % 8).font = ~fontTmp;//Hence previous but one "offed"
			});
			AppClock.play({
				~fonty.at((~noteIdx + 7) % 8).font = ~fontDef;//Hence previous note "displayed"
			});
			~noteIdx = (~noteIdx + 1) % 8;
			~resid = ((~jig).bilinrand - ~resid) * 0.95;
			1 + ~resid;//with retrig
		};

		//row 1
		~vol = Bus.control(s);
		~ring = Bus.control(s);

		~hz = Bus.control(s);
		~buzz = Bus.control(s);
		~tmpo = Bus.control(s);

		~butt.value("RUN", [ Color.red, Color.green ], [
			{ ~sync.clear; },
			{ ~fonty.at((~noteIdx + 7) % 8).font = ~fontTmp; ~noteIdx = 0; ~sync.play(~tick); }
		]);
		~butt.value("MUTE", [ Color.green, Color.red ], [
			{ s.unmute; },
			{ s.mute; }
		]);

		~bpmSpec = ControlSpec(120, 360, \lin, 1, 240);
		~modSpec = ControlSpec(0, 100, \lin, 0, 0);

		~volSpec = ControlSpec(-inf, 0, \db, 0, -12);

		~knob.value("Tempo", Color.red, { |val| ~sync.tempo = val; ~tmpo.set(val) }, ~bpmSpec, 1/60);
		~knob.value("Jiggle", Color.yellow, { |val| ~jig = val; }, ~modSpec, 1/5000);

		~knob.value("Volume", Color.yellow, { |val| val = 10.0 ** (val / 20.0);	~vol.set(val); }, ~volSpec);
		~knob.value("Ring", Color.green, { |val| ~ring.set(val); }, ~modSpec, 1/10);

		~knob.value("Tune", Color.red, { |val| ~hz.set(440 * (2 ** (val / 12))); }, ~noteSpec);
		~knob.value("Buzz", Color.green, { |val| ~buzz.set(val); }, ~modSpec, 1/10);

		//Row 2
		~lpf = Bus.control(s);
		~sub = Bus.control(s, 7);

		//one octave up filter
		~filterSpec = ControlSpec(-12, 36, \lin, 0, 12);
		~knob.value("Filter", Color.yellow, { |val| ~lpf.set(2 ** (val / 12)); }, ~filterSpec);

		~knob.value("Order", Color.yellow, { |val| ~sub.setAt(5, val); }, ~modSpec, 1/100);
		~knob.value("Plate", Color.yellow, { |val| ~sub.setAt(6, val); }, ~modSpec, 1/30);

		~knob.value("SB2", Color.green, { |val| ~sub.setAt(0, val); }, ~modSpec, 1/20);
		~knob.value("SB9", Color.green, { |val| ~sub.setAt(1, val); }, ~modSpec, 1/20);
		~knob.value("SB5", Color.green, { |val| ~sub.setAt(2, val); }, ~modSpec, 1/20);
		~knob.value("SB17", Color.green, { |val| ~sub.setAt(3, val); }, ~modSpec, 1/20);

		~knob.value("Stiple", Color.yellow, { |val| ~sub.setAt(4, val); }, ~modSpec, 1/20);

		//row 3 and 4
		~noteKnobs.value;

		~noteArr.value;

		//N.B.==================================
		// WARNING: Any parameter to a SynthDef
		//======================================
		// They will become UGen controls. This will prevent array indexing,
		// and other things depending on the scalar nature of integers.
		// Kind of obvious when you think deeper about how the server runs.

		//Surprising use of control buss gets sampling FB at audio rate (with 1 sample delay?)
		~outFB = Bus.control(s);//the output (pre volume)

		SynthDef(\hi, {|mul = 1.0, r = 1, l = 1| //last for variants
			var out = ~outFB.kr;
			var hz = ~hz.kr * mul;
			var rl = ~tmpo.kr / 20;
			var stip = out * ~sub.kr(1, 4);// <5
			var filt = (hz * ~lpf.kr) * (1 + (stip / 5));
			var pm = ~buzz.kr * out;
			var am = 1 + (~ring.kr * out);

			var env = EnvGen.kr(Env.perc(0.01, r * rl, l * rl), doneAction: 2);

			var subz = SinOsc.ar( hz / 2, stip, ~sub.kr(1, 0)) +
			SinOsc.ar( hz / 9, stip, ~sub.kr(1, 1)) + //The nine fix. Both pseudo and real Fermat in one.
			SinOsc.ar( hz / 5, stip, ~sub.kr(1, 2)) +
			SinOsc.ar( hz / 17, stip, ~sub.kr(1, 3));

			var osc = SinOsc.ar(hz, pm + subz, (am * env) / 2);
			var lpf = LPF.ar(osc, filt);

			var q = (((osc - lpf) * lpf * ~sub.kr(1, 6)) + lpf).clip2(1.0);//hard
			//A nicked cubic clip with end differential matching.
			var plate = q * (3 - q.squared) / 3;//softer
			var link = LPF.ar(plate, filt);

			var order = (link * ~sub.kr(1, 5)) + (plate * (1 - ~sub.kr(1, 5)));

			Out.kr(~outFB, order);//Synthesis complete

			//Render out
			Out.ar(~outBusBase, (order * ~vol.kr)!2);//output audio
		},
		variants: (
			null: [r: 0.01, l: 0],
			note: [r: 10],
			accent: [r: 10, l: 2],
			long: [r: 20],
			blip: [r: 1])
		).add;
	);

	//================
	// SYNTH GUI HiHo
	//================
	(

		//row 1 - Basic LFO application
		~cont.value("Captain HiHo (MIDI ch 2)");
		MIDIClient.init;
		MIDIIn.connectAll;
		~midiSrc = nil;

		~midiSpec = ControlSpec(0, max(MIDIClient.sources.size - 1, 0), \lin, 1, 0);
		~knob.value("MIDI In", Color.red, { |val| ~midiSrc = MIDIClient.sources[val].asMIDIInPortUID; }, ~midiSpec);

		~ratioSpec = ControlSpec(1, 8, \lin, 1 / 8, 1);
		~knob.value("Quick", Color.yellow, { }, ~ratioSpec);
		~knob.value("Slow", Color.yellow, { }, ~ratioSpec);

		~polSpec = ControlSpec(-100, 100, \lin, 0, 0);//polar modulation spec
		~knob.value("VolMod", Color.green, { }, ~polSpec, 1/100);
		~knob.value("RingMod", Color.green, { }, ~polSpec, 1/100);
		~knob.value("TuneMod", Color.red, { }, ~polSpec, 1/100);
		~knob.value("BuzzMod", Color.green, { }, ~polSpec, 1/100);

		~a128Spec = ControlSpec(1, 128, \lin, 1, 1);
		~knob.value("Sync", Color.red, { }, ~a128Spec);

		//row 2 - Program (control timbrals of Hi)


		//row 3 - Song (control tonals of Hi)


		//row 4 - Sequence (control temporals of Hi)


	);

	//==============
	// MIDI Handler
	//==============

	//drums on 10?
	(
		//In pairs for 14 bit resolution?
		//So with 32 controls per machine @ 14 bit, that's 64 controllers per machine.
		//The upper 64-ish are for some unsupported channel mode bull. (I suggest an all notes off in such case.
		//And perhaps a 13 bit blip code. :D ) Just ignore them, or do a remap
		//LSB @ (controller + 32)
		MIDIFunc.cc({
			arg val, ctl, chan, uid;

		});

		//Must be free, so on system clock?
		//Can immediate cotrol buses, but for synth triggers, que on a TempoClock at midiClock rate.
		//Calc rate Based on tempo PLL.
		MIDIFunc.noteOn({

		});

		//Like above.
		MIDIFunc.noteOff({

		});

		//Feed into tune control.
		//Center 2000 hex
		MIDIFunc.bend({

		});

		//A monphonic max pressure event.
		MIDIFunc.touch({

		});

		//A note aftertouch event.
		MIDIFunc.polytouch({

		});

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
});
);


