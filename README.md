# supercollider-demos

This repository contains the work in progress of some SuperCollider audio demos. It is mainly a toolkit and synth def
experience, and is not a set of tunes. There are things I don't like about the language, but in general it rates very
good. The files included are as follows:

## basics.scd

This is the main toolkit adaptation loader. It sets many defaults, and makes GUI building easier. It is the only file which has
to be directly loaded. The rest are loaded relative to it. There are some exceptions such as C++ UGens, but they are likely
to be added as Quarks.