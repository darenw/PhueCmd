PhueCmd 
=======

(complete redo initiated 2023-Jan-06, replaces earlier PhueCmd repo)

WORK IN PROGRESS! Subject to change. Docs may be whacky out of date.

Command line program to do useful and fun things with Philips Hue light bulbs.
For now, Linux only.   Probably will work on other platforms since it's written in D
and doesn't do anything OS specific.


Planned features:
-----------------
* Capable of handling multiple hubs
* Wakeup mode for gradually bringing up lights in the morning, a fake sunrise.
* Sequences of bulb states for decorative displays, holiday use, theatrical use


Usage
-----

    bash> phuecmd                     run GUI for variety of usages
    bash> phuecmd <cmd>               see list below
    bash> phuecmd wakeup 8:25         run slow sunrise brighten at given time
    bash> phuecmd  ....               other usages TBD

commands:
    phuecmd on          turns on all bulbs, whatever colors they're set to
    phuecmd off         turns them all off
    phuecmd bright      sets all bulbs to maximum white. (Turns on any that are off)
    phuecmd dimblue     sets all bulbs to dim blue color
    phuecmd 5000K       blackbody at 5000K.  Can do 2000K to 10000K.
    phuecmd random      run continuously varying random colors. Has GUI.
    phuecmd random1     just once right now, set random colors.


Source code
-----------

https://github.com/darenw/PhueCmd 




