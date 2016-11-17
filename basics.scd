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
s = Server.default;
s.boot;

//=======================
// MAIN MIDI CONTROL BUS
//=======================
~midiCC = [
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32),
	Bus.control(s, 32)
];//32 controllers and 16 channels

//=========
// CC SPEC
//=========
~midiCCSpec = [
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ],
	[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ]
];//32 controllers and 16 channels

//=============================
//MASTER CLOCK AND WIN COUNTER
//=============================
~sync = TempoClock(1);
~win = nil;
~winCnt = 0;
~ctlCnt = 0;

~noteIdx = 0;
~fonty = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];
~envSel = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
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

~knob = { arg label = "is?", color, spec;
	var ref = EZKnob(~win, label: label, controlSpec: spec);
	var chan = ~ctlCnt.div(16);
	var ctl = ~ctlCnt % 16;
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
	var chan = ~ctlCnt.div(16);
	var ctl = ~ctlCnt % 16;
	~midiCCSpec[chan][ctl] = spec;//Set control spec of bus
	ref.action = {
		var val = ~midiCCSpec[chan][ctl].unmap(ref.value) * 16383;//Calculate ranged full
		~midiCC[chan].subBus(ctl).set(val);//Set bus
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

//Not reentrant
~noteButt = { arg num = 0;
	var butt = ~butt.value(
		num.asDigit,
		[
			Color.grey, Color.red, Color.yellow, Color.green, Color.blue
		], [{ }]);
	~fonty.put(num, butt);
};

//Not reentrant
~noteArr = {
	8.do { arg i;
		~noteButt.value(i);//make 8 note keys
	};
};

~noteSpec = ControlSpec(-24, 24, \lin, 1, 0);

//Not reentrant
~noteKnobs = {
	8.do { arg i;
		~knob.value("@" ++ i.asDigit, Color.blue, ~noteSpec);
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
			MIDIClient.disposeClient;
		});
		~win.alwaysOnTop = true;
		~resid = 0.0;

		//FB VIA A CONTROL BUS
		//Surprising use of control buss gets sampling FB at audio rate (with 1 sample delay?)
		~outFB = Bus.control(s, 8);//the output (pre volume)
		//Always pass only necessary busses into Synth, as the SynthDef CAN'T east Out index a subBus!!!

		~tick = { arg beats, time, clock;
			~midiCC[0].get({ |iBus|
				clock.tempo = iBus[2] / 60;//master tempo
				//N.B. ==========================================
				// WARNING: There is a one beat scheduling delay
				//===============================================
				var env = ~midiCCSpec[0][~noteIdx + 24].map(iBus[~noteIdx + 24]);//Map to envelope
				Synth(~envArr.at(env), [ \key, iBus[~noteIdx + 16], \n, ~outFB.subBus(~noteIdx) ]);
				//Seems to be a sync scheduling bug, making Synth play on the tick after it get scheduled.
				//I think this is to do with the tick already having passed at the schedule, and jitter effect
				//cancellation.
				AppClock.play({
					~fonty.at((~noteIdx + 6) % 8).font = ~fontOff;//Hence previous but one "offed"
				});
				AppClock.play({
					~fonty.at((~noteIdx + 7) % 8).font = ~fontOn;//Hence previous note "displayed"
				});
				~noteIdx = (~noteIdx + 1) % 8;
				~resid = ((iBus[3] / 500).bilinrand - ~resid) * 0.95;
				1 + ~resid;//with retrig
			});
		};

		//row 1
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

		~noteArr.value;

		//N.B.==================================
		// WARNING: Any parameter to a SynthDef
		//======================================
		// They will become (UGens via?) an OutputProxy controls. This will prevent array indexing, BAD?!!
		// and other things depending on the scalar nature of integers.
		// Kind of obvious when you think deeper about how the server runs.

		SynthDef(\hi, {|key = 0, r = 1, l = 1, fb = 0| //last for variants and FB busID
			var iBus = ~midiCC[0];//Get the instrument bus
			var note = iBus.kr(1, 6) + 69 + key;//Base midi note
			var hz = note.midicps;//Base with note multiplier

			var out = fb.kr;

			var rl = iBus.kr(1, 2) / 20;
			var stip = out * (iBus.kr(1, 5) / 100).lag;// <5
			var filt = ((hz * (iBus.kr(1, 8).midiratio)).lag * (1 + stip));//Pop elimination
			var pm = iBus.kr(1, 7) * out;

			var env = EnvGen.kr(Env.perc(0.01, r * rl, l), doneAction: 2);

			var subz = SinOsc.ar( hz / 2, stip, iBus.kr(1, 12) / 50) +
			SinOsc.ar( hz / 9, stip, iBus.kr(1, 13) / 50) + //The nine fix. Both pseudo and real Fermat in one.
			SinOsc.ar( hz / 5, stip, iBus.kr(1, 14) / 50) +
			SinOsc.ar( hz / 17, stip, iBus.kr(1, 15) / 50);

			var osc = SinOsc.ar(hz, pm + subz, env);
			var lpf = LPF.ar(osc, filt);

			var q = (((osc - lpf) * lpf * osc * iBus.kr(1, 10) / 5) + lpf).clip(-1.0, 1.0);//hard
			//A nicked cubic clip with end differential matching.
			var plate = q * (3 - q.squared) / 3;//softer
			var link = LPF.ar(plate, filt);

			var ac = (link * iBus.kr(1, 9)) + (plate * (1 - iBus.kr(1, 9)));
			var order = HPF.ar(ac, (iBus.kr(1, 11).lag * 0.0095 + 0.05) * filt);//DC removal and low cut

			Out.kr(fb, order);//Synthesis complete

			//Render out
			OffsetOut.ar(~outBusBase, (order * (iBus.kr(1, 4).dbamp))!2);//output audio
		},
		variants: (
			null: [r: 0.01, l: 0],
			note: [r: 10],
			accent: [r: 10, l: 2],
			long: [r: 20],
			blip: [r: 3])
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
		~knob.value("StipMod", Color.green, { }, ~polSpec, 1/100);
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
			if(uid == ~midiSrc, {//expression is not function (as while and case would be).
				//BUS IS ASYNC SO CALLBACK SET
				var bus = ~midiCC[chan].subBus(ctl % 32);
				var spec = ~midiCCSpec[chan][ctl % 32];
				case
				{ ctl < 32 } {//MSB
					bus.get( { |val|
						val = spec.unmap(val) * 16383;//14 bit from 0 to 1
						val = (val % 128) + (128 * val);
						val = spec.map(val) / 16383;//back to 0 to 1
						bus.set(val);
					});
				}
				{ ctl < 64 } {//LSB
					bus.get( { |val|
						val = spec.unmap(val) * 16383;//14 bit from 0 to 1
						val = val.div(128) * 128 + val;
						val = spec.map(val) / 16383;//back to 0 to 1
						bus.set(val);
					});
				}
				{ true } { ("CC:" ++ ctl ++ " ON: " ++ (chan + 1)).postln; };//Debug
			});
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


