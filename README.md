
PhueCmd
=======
WORK IN PROGRESS!  ALL DOCUMENTATION SUBJECT TO HUGE CHANGE!

Command line tool for manipulating Philips Hue LED bulbs.

This tool is intended for creative technologists, theater geeks, high tech interior decorators,
mad scientists, anyone wanting to manipulate 
Philips Hue bulbs by command line. It is not a slick app for non-geeky common folk. 


Operating System
----------------
So far, it runs only on Linux. Probably, it would work on any system for which a D compiler exists and
the Phobos library works. The build system is Dub. 



Home Automation?
----------------
Phuecmd is not intended for normal civilian home automation.  It is for geeks! 
While eventually (assuming I ever finish this) phuecmd will be able to set bulbs according to 
time of day, or special events, this won't be suitable for integration into home automation
systems from Google, Amazon etc.  It is a toy (for now) or tool (later) for lighting designers,
theater techies, mad scientists and such.



Installation
------------
Grab the source from https://github.com/

Build with Dub:

    cd * top of directory tree, wherein one sees source/ * 
    dub build
    

Usage
-----

Phuecmd is a command line program to be run from a bash command line in a terminal 
such as Konsole, Terminology or gnome-terminal.

Upon running, phuecmd obtains a list of hubs, the bulbs known to each hub, 
and reads defined colors, animations and whatever else from a config file,
or can find hubs and bulbs scannned live on the local network.  

WORK IN PROGRESS: phuecmd has my two hubs hard-coded = useless to anyone else!

Most commands name some entity followed by one or more actions:

    phuecmd> B12 orange -11%

This tells bulb #12 to turn orange and be 11% dimmer.
    
If you want to fuss with the color of one bulb for a while,
tap in the name once. This sets a "context" for all following commands. 
When done, tap in a period as an "end context" command.

Here are examples of the hard way and the easy way for tweaking a bulb's color:

    phuecmd> B7 berryred    -- set color, assuming you've defined "berryred"
    phuecmd> B7 s-20%       -- reduces color saturation for bulb 7.
    phuecmd> B7  +8%        -- brighten it by 8%
    phuecmd> B7 off         -- turn it off 
    
    phuecmd> B7             -- sets context of Bulb 7 for the next commands
    phuecmd> berryred       -- do the same actions as before
    phuecmd> s-27%
    phuecmd> +8%
    phuecmd> off
    phuecmd> .              -- done working with B7 
    

To deal with all bulbs at once, use 'all bulbs'  (may leave out the 'bulbs') or "BB"
(or "bb" since everything's case insensitive)

    phuecmd> all on
    phuecmd> all on
    phuecmd> all dim     -- sets all to low brightness


Get a list of all the bulbs known to all the hubs you have active.  
There are other commands for dealing with your configuration:

    phuecmd> list bulbs   -- prints out essential info on every bulb known to phuecmd, one bulb per line.
    phuecmd> detail bulb B15    -- print out all the details of bulb B15
    phuecmd> detail kitchentop   -- don't need explicit "bulb"
    phuecmd> list hubs    -- lists IP address, MAC, etc for each hub
    phuecmd> num          -- blinks bulbs according to a numerical color code, to identify which is which.

A bulb may be referred to by various means.
*  its index (place in a Bulbs List internal to phuecmd).
* its hub index and that hub's notion of the bulb's number. Note that two hubs may each have a "bulb #24" but these are different physical bulbs. /*NOT IMPLEMENTED YET*/
* a name    /*TODO*/ doesn't work yet!
* a location. WORK IN PROGRESS! There will be ways to define names of location and assign bulbs to them.


Colors
------
* There are some built-in color names, "red", "green"  etc. 
* Numbers in the range of 1000 to 20000 (?) are color temperatures. 2000
* Single digits are interpreted as color used in the electronics industry, for example 2 = red.
* CIE coordinates & brightness:  (?)  bri=23 x=.583 y=0.37   
* HSV  bri=23 h=3973 s=224     
     note: brightness is on a scale 0 to 100 
* JSON as sent to the bulb:   {"bri":50,  "sat":255,  "hue":6600 }


Define a color by name:

    phuecmd> color brown = {"bri":50,  "sat":255,  "hue":6600 }

The 'num' command causes all bulbs to blink out a three digit color code showing the bulb's index 
in the Bulb List, or each one's number as known to its hub. (WIP: Currently hardcoded to be one or other, 
should make it choosable with different commands)

    phuecmd> color berryred = bri 0.91 x 0.582 y 0.308      --syntax TBD

System Commands
---------------
There are commands for a hub to forget its bulbs, search for new bulbs, transfer a bulb's
ownership from one hub to another, etc but these are currently (Jan 2022) in flux and
will remain undocumented for now.


Work To Do
----------
* Massive switch statement for processing commands. Replace with dictionary of commands and patterns, 
  nicely separated executive functions.
* No existence of sequences (series of colors over time), animation
* Needs a play thread, to scan through sequences, look for alarms, 
   and update bulbs periodically, probably once/second or thereabouts.
* hubs[] and bulbs[] are global objects. I have a notion to define PhueSystem, so that entirely 
separate sets of hubs and bulb could be manipulated by one instance of phuecmd. 
hubs[] and bulbs[] would have to be shoveled into PhueSystem, and multiple instances of PhueSystem
managed with commands.  Someday...




Resources
---------
Philips Hue bulbs 

Controlling bulbs through HTTP: https://github.com/tigoe/hue-control 

HTTP API in detail, bulb api: https://developers.meethue.com/develop/hue-api/lights-api/ 
(requires developer account)

How to reset your Philips Hue bulbs and Bridge
And how to reconfigure your Hue network https://www.the-ambient.com/how-to/reset-philips-hue-1565

https://www.techhive.com/article/578312/if-philips-hue-lights-unresponsive-move-your-hue-bridge.html


Contact
-------

I, Daren Scot Wilson, am a person, not a company. No 800 number for you to call!  
Contact me through Github, Twitter @drunkenufopilot, Linkedin, darenw@darenscotwilson.com, 
or just holler real loud.


License
-------
MIT

