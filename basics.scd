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
	ref.action.value;//eval once
	~patch.put(label, ref);
	ref;
};

~butt = { arg states = [ "is?" ], colors = [ Color.white ], actions = [{ }];
	var ref = Button(~win, 50@90);
	ref.action = {
		if(ref.value >= actions.size) { ^nil; };
		actions.at(ref.value).value;
	};
	ref.states = states.collect({ arg it, i;
		[ it, Color.black, colors.at(i % colors.size) ];
	});
	ref.action.value;//eval once
	~patch.put(states.at(0), ref);
	ref;
};

// Make default window
~cont.value("Global Controls",  {
	~sync.clear;
	s.quit;
	Window.closeAll;
});
~win.alwaysOnTop = true;
);

//======================
// CONSTRUCT GLOBAL GUI
//======================
(
~tick = {arg beats, time, clock; [beats, time, clock].postln; 1;};
~jig = 0.0;

~vol = 1.0;
~ring = 0.0;
~mute = false;

~hz = 440;
~buzz = 0.0;

~butt.value(["STOP", "RUN"], [ Color.red, Color.green ], [{ ~sync.clear; }, { ~sync.playNextBar(~tick); }]);
~butt.value(["LOUD", "MUTE"], [ Color.green, Color.red ], [{ ~mute = false; }, { ~mute = true; }]);

~bpmSpec = ControlSpec(20, 220, \lin, 1, 120);
~jigSpec = ControlSpec(0, 100, \lin, 0, 0);

~volSpec = ControlSpec(-inf, 0, \db, 0, -12);
~ringSpec = ControlSpec(0, 100, \lin, 0, 0);

~freqSpec = ControlSpec(110, 1760, \exp, 0, 440);
~buzzSpec = ControlSpec(0, 100, \lin, 0, 0);

~knob.value("Tempo", Color.yellow, { |val| ~sync.tempo = val; }, ~bpmSpec, 1/60);
~knob.value("Jiggle", Color.yellow, { |val| ~jig = val; }, ~jigSpec);

~knob.value("Volume", Color.yellow, { |val| ~vol = 10 ** (val / 10); }, ~volSpec);
~knob.value("Ring", Color.yellow, { |val| ~ring = val; }, ~ringSpec, 1/100);

~knob.value("Tune", Color.yellow, { |val| ~hz = val; }, ~freqSpec);
~knob.value("Buzz", Color.yellow, { |val| ~buzz = val; }, ~buzzSpec, 1/100);

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


