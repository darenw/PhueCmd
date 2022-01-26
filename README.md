
PhueCmd
=======
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
Phuecmd is not intended for normal civilian home automation. 
While eventually (assuming I finish this) phuecmd will be able to set bulbs according to 
time of day, or special events, this won't be suitable for integration into home automation
systems from Google, Amazon etc.  



Installation
------------
Grab the source from https://github.com/

Build with Dub:

    cd * top of directory tree, wherein one sees source/ * 
    dub build
    

Usage
-----

Upon running, phuecmd obtains a list of hubs, bulbs known to each hub, 
defined colors, animations and whatever else from a config file (/*TODO*/)
or scannned live on the local network.  
WORK IN PROGRESS: phuecmd has my two hubs hard-coded = useless to anyone else!

Phuecmd is a command line program to be run from a bash command line in a terminal 
such as Konsole, Terminology or gnome-terminal.

A prompt will appear. Enter the name of a bulb, pattern, animation, etc. then tap ENTER. 
The action will take place.  When done, enter 'quit' to end phuecmd, return to the bash prompt.

    phuecmd> B12 orange
    
Most commands start with an entity to work with, but sometimes don't. If you want to fuss with
the color of one bulb, it would be tedious to type in its ID number or name on every line.
Instead, tap in the name of the bulb once, then that sets a "context" for all following 
commands. 

Here are examples of the hard way and the easy way for tweaking a bulb's color:

    phuecmd> B7 s-20%       -- reduces color saturation for bulb 7.
    phuecmd> B7  +8%        -- brighten by 8%
    phuecmd> B7 off         -- turn it off
    
    phuecmd> B7             -- sets context of Bulb 7 for the next commands
    phuecmd> s-27%
    phuecmd> +8%
    phuecmd> off
    

There are a few commands to affect all known bulbs at once:
    
    phuecmd> all on
    phuecmd> all on
    phuecmd> all dim     -- sets all to low brightness

    phuecmd> list bulbs   -- prints out essential info on every bulb known to phuecmd, one bulb per line.

    phuecmd> list hubs    -- lists IP address, MAC, 
    phuecmd> num          -- blinks bulbs according to a numerical color code, to identify which is which.

A bulb may be referred to by various means.
*  its index (place in the Bulbs List internal to phuecmd),
* its hub index (ignorable if there's only one hub) and that hub's notion of the bulb's number,
* a name    /*TODO*/ doesn't work yet!
* a location. WORK IN PROGRESS! There will be ways to define names of location and assign bulbs to them.


Colors
------
* There are some built-in color names, "red", "green"  etc. 
* Numbers in the range of 1000 to 20000 (?) are color temperatures. 2000
* Single digits are interpreted as color used in the electronics industry, for example 2 = red.

The 'num' command causes all bulbs to blink out a three digit color code showing the bulb's index 
in the Bulb List, or each one's number as known to its hub. (WIP: Currently hardcoded to be one or other, 
should make it choosable with different commands)


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

