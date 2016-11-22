# supercollider-demos

This repository contains the work in progress of some SuperCollider audio demos. It is mainly a toolkit and synth def
experience, and is not a set of tunes. There are things I don't like about the language, but in general it rates very
good. The files included are as follows:

## basics.scd

This is the main toolkit loader. It sets many defaults, and makes GUI building easier. It is the only file which has
to be directly loaded. The rest are loaded relative to it. There may be some exceptions such as C++ UGens, but they are likely
to be added as Quarks. The basic appegiator works off the keys, and MIDI is used to set the base note (when available). The initial
beat should drop, to maintain sync, as there is a one beat lag. A faster MIDI clocking could be used, but this would waste resources
which are better spent on making noise.

There is a MIDI clock, but it is for  sync only. As resources are better spent on noise instead of controller
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
expression and control. MIDI is not sent by this suite, it is not a bus master.

Well, I could go on but here's a list with the MIDI channel controllers (0 to 31) should be on.

  * *01 - General Hi* (completed) - A rythum synth described above.
  * *02 - Captain HiHo* (completed) - An LFO and envelope modulation controller for *General Hi*. Multibus MIDI selection too.
  * *03 - Sargent Sift* (in development) - A mixer for sound card ins, and the machines within, plus effects.
  * *04 - Corporal Beat* (in development) - A simple drum sound modelling interface.
  * *05 - Private Stick* (in development) - A four pattern drum sequencer. Select the pattern on *Corporal Beat* per drum sound.
  * 06
  * 07
  * 08
  * 09
  * 10
  * 11
  * 12
  * *13 - Unlucky Jack* (completed) - A controller test app. To test out your controller numbers. Set your device to 13, select source on *Captain HiHo*.
  * *14 - Sparkie* (in development) - A note to controller remapper. For access to any controller on the channel.
  * *15 - Fluff* (in development) - A velocity to controller remapper. For access to any controller on the channel.
  * *16 - Notary Nob* (completed) - A virtual MIDI note event (on all channels) to controls (on 16). Also the about box.
  
## Blerb

The SuperCollider version for development is 3.8, and it has been tested and failed on 3.6, so be aware. Anything not marked *completed*
is subject to change and alteration, and although may be stable, it's likely not final, as testing sorts out things like controller
ranges, and subtle regressions. The overall aim is to make a kit suitable for 'live' performance.

There is currently no versioning system but tags such as 'ch2-1.1.0' indicate that the machine on channel 2 is 'working' and maybe
it would be version 1, revision 1 (added feature), bug fix revision 0, and so forth. There is not any branching system in operation
and master is bleeding edge alpha at present.

There is some very kludgy work arounds, such as the use of a control bus for feedback, as an audio bus would render one block late for
feedback. Luckly, you can at present route audio over control buses. I'm not really happy with the solution, and hope some future
release has a more appropriate method of single sample feedback. This has been fixed with little sound change.

The methodology of adding new machines to add extensions to other machines is to keep the GUI build consistent, and allows minimizing
windows not in the current focus. I think this better than having massive windows of controls, when other software in the performance
may be open too. This does lead to some unexpected locations for features, such as the *General Hi* mute having a global effect.

## Useful Things to Know

  * The global MUTE button is on *General Hi*, along with the global RUN button. It even mutes the input channels.
  * The MIDI bus (not channel on bus) selector is on *Captain HiHo*, if you have multiple MIDI in ports.
  * The master volumes are on *Sargent Sift* and in many ways this is the audio path output machine.
  * *Captain HiHo* is run 8 times slower than *General Hi* and has a transposer pattern. It also is the location of the tempo speed multiplier.
  * The global master volume is in the system tray.
  * The last three machines can be controlled such that the sequence can adapt the role of the keyboard on all channels.
  * Feature are generally added as and when I find the need, or would find utility in them. There is no feature request process.
  * The bug tracker is not used, but feel free to use it. I may not respond, but at some point I may consider so.
  * There are as yet no hooks for development in other files for easy pull requests.
  
This project is released LGPL, and as such you can use the 'library', but the code remains copyright K Ring Technologies Ltd. for any
other purpose than as an associated set of files to put with your own code. I may optimize the code later, and make some Quarks
with custom UGens, but this does rely on there being an effective build system for Windows. And yes I often VirtualBox Linux.

Have fun.

*The Management*.