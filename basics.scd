//generic synth template
//(C)2016 K Ring Technologies Ltd, Simon Jackson

//Notes for the brave.
//--------------------
//I have not created any classes, as this requires Quarks and installing into the compiled class base.
//I have used functions as classes, and provided some common control constructors. Some are NOT reentrant.
//Happy coding!

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

//" ", "-", "=", "#", "~"
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
	~patch.put(label, ref);
	ref;
};

~butt = { arg states = [ "is?" ], colors = [ Color.white ], actions = [{ }];
	var ref = Button(~win, 50@90);
	ref.action = {
		actions.at(ref.value % actions.size).value(ref.value);
	};
	ref.font = ~fontTmp;
	ref.states = states.collect({ arg it, i;
		[ it, Color.black, colors.at(i % colors.size) ];
	});
	ref.doAction;//eval once
	~patch.put(states.at(0), ref);
	ref;
};

//Below are not reentrant

~noteButt = { arg num = 0;
	var butt = ~butt.value([
		num.asDigit, "-", "=", "#", "~"
	], [
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
	(
		// Make default window
		~cont.value("Global Hi",  {
			~sync.clear;
			s.quit;
			Window.closeAll;
		});
		~win.alwaysOnTop = true;
		~jig = 0.0;
		~resid = 0.0;
		~tick = {arg beats, time, clock;
			AppClock.play({
				~fonty.at(~noteIdx).font = ~fontDef;// big
			});
			//~envSel.at(~noteIdx).postln;//debug -- notes on parameters becoming control UGens
			Synth(~envArr.at(~envSel.at(~noteIdx)), [ \mul, ~noteMul.at(~noteIdx), \env, ~envSel.at(~noteIdx) ]);
			AppClock.play({
				~fonty.at((~noteIdx + 7) % 8).font = ~fontTmp;
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

		~butt.value(["RUN", "RUN"], [ Color.red, Color.green ], [
			{ ~sync.clear; },
			{ ~fonty.at(~noteIdx).font = ~fontTmp; ~noteIdx = 7; ~sync.play(~tick, 0); }
		]);
		~butt.value(["MUTE", "MUTE"], [ Color.green, Color.red ], [
			{ s.unmute; },
			{ s.mute; }
		]);

		~bpmSpec = ControlSpec(60, 340, \lin, 1, 200);
		~modSpec = ControlSpec(0, 100, \lin, 0, 0);

		~volSpec = ControlSpec(-inf, 0, \db, 0, -12);
		~freqSpec = ControlSpec(110, 1760, \exp, 0, 440);

		~knob.value("Tempo", Color.red, { |val| ~sync.tempo = val; }, ~bpmSpec, 1/30);
		~knob.value("Jiggle", Color.yellow, { |val| ~jig = val; }, ~modSpec, 1/5000);

		~knob.value("Volume", Color.yellow, { |val| val = 10.0 ** (val / 20.0);
			~vol.set(val); }, ~volSpec);
		~knob.value("Ring", Color.green, { |val| ~ring.set(val); }, ~modSpec, 1/10);

		~knob.value("Tune", Color.red, { |val| ~hz.set(val); }, ~freqSpec);
		~knob.value("Buzz", Color.green, { |val| ~buzz.set(val); }, ~modSpec, 1/3);

		//Row 2
		~lpf = Bus.control(s);
		~sub = Bus.control(s, 7);
		~ratioSpec = ControlSpec(-24, 24, \lin, 0, 0);

		~knob.value("Filter", Color.yellow, { |val| ~lpf.set(2 ** (val / 12)); }, ~ratioSpec);

		~knob.value("SH2", Color.green, { |val| ~sub.setAt(0, val); }, ~modSpec, 1/50);
		~knob.value("SH3", Color.green, { |val| ~sub.setAt(1, val); }, ~modSpec, 1/50);
		~knob.value("SH5", Color.green, { |val| ~sub.setAt(2, val); }, ~modSpec, 1/100);
		~knob.value("SH7", Color.green, { |val| ~sub.setAt(3, val); }, ~modSpec, 1/100);
		~knob.value("SH11", Color.green, { |val| ~sub.setAt(4, val); }, ~modSpec, 1/150);
		~knob.value("SH13", Color.green, { |val| ~sub.setAt(5, val); }, ~modSpec, 1/150);
		~knob.value("SH17", Color.green, { |val| ~sub.setAt(6, val); }, ~modSpec, 1/150);

		//row 3 and 4
		~noteKnobs.value;

		~noteArr.value;

		//N.B.==================================
		// WARNING: Any parameter to a SynthDef
		//======================================
		// They will become UGen controls. This will prevent array indexing,
		// and other things depending on the scalar nature of integers.
		// Kind of obvious when you think deeper about how the server runs.

		SynthDef(\hi, {|mul = 1.0, r = 1, l = 1|
			var out = Bus.audio(s);//the output (pre volume)
			var hz = ~hz.kr * mul;
			var filt = hz * ~lpf.kr;
			var pm = ~buzz.kr * out.ar;
			var am = 1 + (~ring.kr * out.ar);

			var env = EnvGen.kr(Env.perc(0.01, r, l), doneAction: 2);

			var subz = SinOsc.ar( hz / 2, 0, ~sub.kr(1, 0)) +
			SinOsc.ar( hz / 3, 0, ~sub.kr(1, 1)) +
			SinOsc.ar( hz / 5, 0, ~sub.kr(1, 2)) +
			SinOsc.ar( hz / 7, 0, ~sub.kr(1, 3)) +
			SinOsc.ar( hz / 11, 0, ~sub.kr(1, 4)) +
			SinOsc.ar( hz / 13, 0, ~sub.kr(1, 5)) +
			SinOsc.ar( hz / 17, 0, ~sub.kr(1, 6));

			var osc = SinOsc.ar(hz, pm + subz, am * env);
			var lpf = LPF.ar(osc, filt);

			Out.ar(out, lpf);
			Out.ar(0, lpf * ~vol.kr);//output audio
		},
		variants: (
			null: [r: 0.01, l: 0],
			note: [r: 1],
			accent: [r: 1, l: 1.5],
			long: [r: 2],
			blip: [r: 0.1])
		).add;
	);

	//================
	// SYNTH GUI HiHo
	//================
	(

		~cont.value("HiHo");

		~butt.value(["ON\nJZ", "OFF"], [ Color.green, Color.red ]);

	);

	//======
	// EXIT
	//======
});
);