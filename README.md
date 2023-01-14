PhueCmd 
=======

(complete redo initiated 2023-Jan-06, replaces earlier PhueCmd repo)

WORK IN PROGRESS! Subject to change. Docs may be whacky out of date.

Command line program to do useful and fun things with Philips Hue light bulbs.
For now, Linux only.   Probably will work on other platforms since it's written in D
and doesn't do anything OS specific.  A GUI may be added eventually, later.

"PHue" = Philips Hue



Usage
-----

    bash> phuecmd                     run GUI for variety of usages
    bash> phuecmd <cmd>               see list below
    bash> phuecmd  ....               other usages TBD


commands:
    phuecmd list        prints list of hubs, bulbs, other info
    phuecmd on          turns on all bulbs, whatever colors they're set to
    phuecmd off         turns them all off
    phuecmd bright      sets all bulbs to maximum white. (Turns on any that are off)
    phuecmd dimblue     sets all bulbs to dim blue color (similar commands may exist)
    phuecmd half        sets all bulbs to half as bright, same color
    phuecmd 5000K       blackbody at 5000K.  Can do 2000K to 10000K.
    phuecmd random      run continuously varying random colors. Has GUI.
    phuecmd random1     just once right now, set random colors.
    phuecmd wakeup 8:25          run slow fake sunrise brightening at given time
    phuecmd set 3 0.1 0.55 0.31  sets bulb [3] to bri-0.1, x=0.55, y=0.31 (dim red)


Bulb Numbering
--------------
Each hub "owns" some set of bulbs. 
It numbers those bulbs however it pleases. 
If a bulb is deleted from the hub's internal list, that number won't be used again. 
New bulbs are given higher numbers.  
For example, right now one of my hubs has bulbs 35 and 36.  
Bulbs 1, 2, 3, ... to 34 have over the years been added and deleted during mad scientist
experiments with this system. Note that bulb numbers start with 1 not 0. 

Another hub will number its bulbs as it pleases, with no awareness of what bulb
numbers are in use by other hubs.  Two hubs may each have a bulb #5. 

To uniquely specify a bulb then, one must give the hub id and the bulb id as known to 
that hub.  Example: "H2B29"

### Bulb Index

Separate from that scheme, PhueCmd keeps a list of all bulbs in use. This is 
an array indexed with 0 to Nbulbs-1.  This index has no relation to the hub's numbering.
The 'set' command expects a bulb index
To 

### Bulb Names

For practical use by Humans, bulbs may be given names like "DiningNW" or "Hidden L 6". 
(NOT YET IMPLEMENTED) 


Configuration File
-------------------

(NOT YET IMPLEMENTED!)

Data defining lists of hubs, bulbs, color palettes, color play sequences, etc. may
be stored in a configuration file.   

Lacking a configuration file, or for testing, a "canned" system may be loaded. 
This is hardcoded for a given set of hardware.  Modify the source if you want
it to match your hardware.


Upcoming Work To Do
-------------------

See file phue-to-do.txt which may or may not be up to date.


Source code
-----------

https://github.com/darenw/PhueCmd 





