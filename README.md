# supercollider-demos

This repository contains the work in progress of some SuperCollider audio demos. It is mainly a toolkit and synth def
experience, and is not a set of tunes. There are things I don't like about the language, but in general it rates very
good. The files included are as follows:

## basics.scd

This is the main toolkit adaptation loader. It sets many defaults, and makes GUI building easier. It is the only file which has
to be directly loaded. The rest are loaded relative to it. There are some exceptions such as C++ UGens, but they are likely
to be added as Quarks. The basic Appegiator works off the keys, and MIDI is used to set the base note (when available).

There is the General Hi synth, which does the appegiation, and generates some timbral opertunities. It's a filtered harmonic
feedback AM/PM/Sub-harmonic hybrid, and can make very fat sounds, with ease. There is no direct LFO, or much envelope shaping.
Don't worry, this is expected, as the HIHo has all the extras which are useful.