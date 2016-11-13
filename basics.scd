//generic synth template
//(C)2016 K Ring Technologies Ltd, Simon Jackson

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
~noteMul = [ 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 ];
~notes = [ 0.0 ] ++ (([ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 ] + 69).midicps) / 440;

~fontDef = Font(Font.default.name, 30);
~fontTmp = Font(Font.default.name, 15);

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

~noteButt = { arg num = 0, muller = ~noteMul;
	var butt = ~butt.value([
		"#" ++ num.asDigit, "A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"
	], [
		Color.red, Color.white, Color.grey, Color.white, Color.white, Color.grey, Color.white, Color.grey, Color.white,
		Color.white, Color.grey, Color.white, Color.grey
	], [{ arg butt;
		muller.put(num, ~notes.at(butt.value));
		//butt.value.postln; //debug -- language does not support variable references to future closures
		//~noteMul.postln; //ok!
	}]);
	~fonty.put(num, butt);
};

~noteArr = { arg muller = ~noteMul;
	8.do { arg i;
		~noteButt.value(i, muller);//make 8 note keys
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
		~out = Bus.audio(s);//the output (pre volume)
		~resid = 0.0;
		~tick = {arg beats, time, clock;
			AppClock.play({
				~fonty.at(~noteIdx).font = ~fontDef;// big
			});
			Synth(\hi, [ \mul, ~noteMul.at(~noteIdx) ]);
			AppClock.play({
				~fonty.at((~noteIdx + 7) % 8).font = ~fontTmp;
			});
			~noteIdx = (~noteIdx + 1) % 8;
			~resid = ((~jig).bilinrand - ~resid) * 0.95;
			1 + ~resid;//with retrig
		};

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

		~knob.value("Tempo", Color.red, { |val| ~sync.tempo = val; }, ~bpmSpec, 1/15);
		~knob.value("Jiggle", Color.yellow, { |val| ~jig = val; }, ~modSpec, 1/5000);

		~knob.value("Volume", Color.yellow, { |val| val = 10.0 ** (val / 20.0);
			~vol.set(val); }, ~volSpec);
		~knob.value("Ring", Color.green, { |val| ~ring.set(val); }, ~modSpec, 1/5);

		~knob.value("Tune", Color.red, { |val| ~hz.set(val); }, ~freqSpec);
		~knob.value("Buzz", Color.green, { |val| ~buzz.set(val); }, ~modSpec, 1/5);

		~knob.value("Filter", Color.yellow, {}, ~freqSpec);

		~knob.value("SH2", Color.green, {}, ~modSpec);
		~knob.value("SH3", Color.green, {}, ~modSpec);
		~knob.value("SH5", Color.green, {}, ~modSpec);
		~knob.value("SH7", Color.green, {}, ~modSpec);
		~knob.value("SH11", Color.green, {}, ~modSpec);
		~knob.value("SH13", Color.green, {}, ~modSpec);
		~knob.value("SH17", Color.green, {}, ~modSpec);

		~noteSpec = ControlSpec(-24, 24, \lin, 1, 0);

		~knob.value("@0", Color.blue, {}, ~noteSpec);
		~knob.value("@1", Color.blue, {}, ~noteSpec);
		~knob.value("@2", Color.blue, {}, ~noteSpec);
		~knob.value("@3", Color.blue, {}, ~noteSpec);
		~knob.value("@4", Color.blue, {}, ~noteSpec);
		~knob.value("@5", Color.blue, {}, ~noteSpec);
		~knob.value("@6", Color.blue, {}, ~noteSpec);
		~knob.value("@7", Color.blue, {}, ~noteSpec);

		~noteArr.value;

		SynthDef(\hi, {|mul = 1.0, a = 0.01, r = 1|
			var temp = SinOsc.ar(~hz.kr * mul, ~buzz.kr * ~out.kr,
				(1 + (~ring.kr * ~out.kr)) * EnvGen.kr(Env.perc(a, r, 1.0), doneAction: 2));
			Out.ar(~out, temp);
			Out.ar(0, temp * ~vol.kr);//output audio
		}, variants: (alpha: [a: 0.5, r: 0.5], beta: [a: 3, r: 0.01], gamma: [a: 0.01, r: 4])
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