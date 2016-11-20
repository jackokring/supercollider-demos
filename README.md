# supercollider-demos

This repository contains the work in progress of some SuperCollider audio demos. It is mainly a toolkit and synth def
experience, and is not a set of tunes. There are things I don't like about the language, but in general it rates very
good. The files included are as follows:

## basics.scd

This is the main toolkit adaptation loader. It sets many defaults, and makes GUI building easier. It is the only file which has
to be directly loaded. The rest are loaded relative to it. There are some exceptions such as C++ UGens, but they are likely
to be added as Quarks. The basic Appegiator works off the keys, and MIDI is used to set the base note (when available). The initial
beat will drop, to maintain sync, as there is a one beat lag. A faster MIDI clocking could be used, but this would waste resources
which are better spent on making noise.

There is a faster MIDI clock, but it is for controller sync only. As resources are better spent on noise instead of controller
GUI updating, the trend is for the GUI to updated at a slower rate. Not that you'd notice but the GUI updates the busses, and so
this is a little more involved than would first appear, and involves controller ID functions, and an occasional value poke back.
It has the effect of snapping GUI controls back sometimes after being altered in the GUI. The motors are strong in this one!

There is the *General Hi* synth, which does the appegiation, and generates some timbral opertunities. It's a filtered harmonic
feedback AM/PM/Sub-harmonic hybrid, and can make very fat sounds, with ease. There is no direct LFO, or much envelope shaping.
Don't worry, this is expected, as the HIHo has all the extras which are useful as it is a modulation synth, producing no
sound itself. Be careful in the twist as some of those dials have quite an effect.

The generation is basically 2 stage phase modulation (4 operator, 3 into 1), with 2 feedbacks. This is fed into a filter 6dB
and some frequency doubler Q plate with soft clip, followed by and extra 6dB (dry or wet). The mix is then a feedback source for
both the base operator as AM and PM. The final control feeds the mix to PM the 3 sub harmonic oscillators an the filter cut.
It can all lead to chaos on just a sine of the times.

The *Captain HiHo* is an LFO and envelope modulation unit. It also selects the MIDI source device for channel listening. It has
fills based on changing note sequencin, and has a semitone offset control for each loop. In general it's a good one for more
expression and control.