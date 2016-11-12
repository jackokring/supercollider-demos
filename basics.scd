//generic synth template
//(C)2016 K Ring Technologies Ltd, Simon Jackson


//=========================
// START AND TEMPLATE CTRL
//=========================
(
s.boot;
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
	s.quit;
	Window.closeAll;
});
~win.alwaysOnTop = true;
);

//===============
// CONSTRUCT GUI
//===============
(
~sync = TempoClock(1);
~vol = 1.0;

~butt.value(["RUN", "STOP"], [ Color.green, Color.red ]);
~butt.value(["LOUD", "MUTE"], [ Color.green, Color.red ]);

~bpmSpec = ControlSpec(20, 220, \lin, 1, 120);
~volSpec = ControlSpec(0, 10, \db, 0, 0.3);
~freqSpec = ControlSpec(110, 1760, \exp, 0, 440);

~knob.value("Tempo", Color.yellow, { |val| ~sync.tempo = val; }, ~bpmSpec, 1/60);
~knob.value("Jiggle", Color.yellow, { |val| ~sync.tempo = val; }, ~bpmSpec, 1/60);

~knob.value("Volume", Color.yellow, { |val| ~vol = val; }, ~volSpec, 1/10);
~knob.value("Ring", Color.yellow, { |val| ~vol = val; }, ~volSpec, 1/10);

~knob.value("Tune", Color.yellow, { |val| ~vol = val; }, ~freqSpec);
~knob.value("Buzz", Color.yellow, { |val| ~vol = val; }, ~volSpec);

);

(
~cont.value("HiHo");

~butt.value(["ON\nJZ", "OFF"], [ Color.green, Color.red ]);
);