
# PhueCmd

WORK IN PROGRESS!  ALL DOCUMENTATION SUBJECT TO HUGE CHANGE!

Command line tool for manipulating Philips Hue LED bulbs, 
to define and play back color change sequences, 
and generally do mad artist antics with systems of Hue bulbs.

This tool is intended for creative technologists, theater geeks, 
high tech interior decorators, mad scientists, and anyone wanting to manipulate 
Philips Hue bulbs by command line. It is not a slick GUI app for non-geeky common folk. 

PhueCmd is imagined to be useful only on desktop and laptop computers, not for mobile devices.




## Operating System
----------------
So far, it runs only on Linux. Probably, it would work on any system for which a D compiler exists and
the Phobos library works. The build system is Dub. If you have Dub, can build D programs,
and know that http and json as made available by Phobos will work, then cool, have fun!



## Home Automation?
----------------
Phuecmd is not intended for normal civilian home automation.  It is for geeks! 
While eventually (assuming I ever finish this) phuecmd will be able to set bulbs according to 
time of day, or special events, this won't be suitable for integration into home automation
systems from Google, Amazon etc.  It is a toy (for now) or tool (later) for lighting designers,
theater techies, mad scientists and such.



#Installation

Grab the source from https://github.com/darenw/PhueCmd  

Build with Dub:

    cd to top of directory tree, wherein one sees source/, dub.sdl and more
    bash> dub build
     
There is no installation procedure, packaging etc. Maybe someday...


____


# Usage

Phuecmd is a command line program to be run from a bash command line in a terminal 
such as Konsole, Terminology or gnome-terminal.

Upon startup, phuecmd acquires a list of hubs and bulbs from a configuration file or
by probing the local network. There may be config files defining user-defined colors,
sequences, etc.  


Most commands are like this:   

    phuecmd>   _entity_  _action_ _action_ _action_

where the "entity" is a hub, bulb, color sequence, or some other thing (TBD).
Any number of actions may be given (where it makes sense) and applied one after the other.

If the entity is omitted, whatever entity was used in the previous command is assumed. 
Every time command starts with an entity, it sets a context for all following commands
that don't state an entity. Sometimes you don't want this effect. Stop assuming context
for any further commands by using a single period as a command:

    phuecmd> .    
    

Some commands are the opposite, starting with an action:

    phuecmd>  _action_  _object_

Examples are:

    phuecmd> list bulbs                      -- you can list bulbs, hubs, colors, palettes...
    phuecmd> forget hub47
    phuecmd> +  foo barre blarg              -- add these three things to current entity
    phuecmd> quit                            -- exits phuecmd.

See system commands for a bunch of these. 



## Hub Commands

Hubs (aka Bridges) are identified by:
* a number assigned by phuecmd, as in H2 (always with an 'H' or 'h')
* a name, always starting with 'H' or 'h', as in "Hnorth"
* it MAC address (enough last few bytes to be unique), as in H:4E:7C

Always give the MAC-based identity with a colon after the H, as "H:4E:7C", 
because phuecmd isn't smart enough to make sense of "H4E:7C".

    phuecmd> list hubs            -- shows IP, MAC, more
    phuecmd> forget hubs          -- forget everything about all hubs
    phuecmd> forget H56           -- make amnesia of the hub named "H56"
    phuecmd> find hubs            -- searches LAN for hardware
    phuecmd> hsouth = h:51:E9     -- give name to the hub whose MAC ends 51:E9
    phuecmd> detail hsouth        -- print out a lot of tech info from this hub
    


## Bulb Commands

Each bulb is identified by
* Bulb Index - unique number 1 .. Nbulbs, assigned by phuecmd, as in "B14"
* Hub-Bulb number - a number assigned to the bulb by its hub: "B32H1" 
* (optional) name assigned by user:  "arch-top", "kitchen-middle"
* (someday) its ""uniqueid"", built into the hardware: "B00:17:88:01:02:51:7b:8b-0b"
* Its Location, 

A typical bulb command names a bulb then sets a color, modifies a color, 
turns it on or off, and possibly other actions (work in progress).
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
    phuecmd> .              -- next commands shouldn't affect B7

Confusion could result if you have a bulb named "berryred" or a location named "s-27%" but that's
weird. We'll assume no one would do such things. *You* wouldn't anything like that, right?

Give a name to a bulb. You'd have to sketch out a map, mark "B1", "B2", etc. to remember which
one is which.  Human-meaningful names may be defined and used in place of any "B#".

    phuecmd> kitchenL = B15
    phuecmd> kitchenM = B18
    phuecmd> kitchenR = B10
    phuecmd> kitchenM white
    phuecmd> kitchenL  off

Besides referring to specific individual bulbs, you can apply an action to all bulbs:

    phuecmd> all -60%           -- make all bulbs dimmer
    phuecmd> all hotgreen
    phuecmd> all off
    phuecmd> all on
    phuecmd> all dim            -- all made dimmer (1/4 bri?) (remember original colors)
    phuecmd> all on             -- restores all to same colors as before dimming
    
You can control several bulbs, but not all, the same way by using bulb groups:

    phuecmd> new group "corners"     -- create a new bulb group  (quotes optional?)
    phuecmd> corners + B2 B4 B8 B9   -- add these four bulbs (in corners of room)
    phuecmd> ...                     -- do other things for a while
    phuecmd> corners s-20%           -- decrease saturation for these four bulbs
    
If those four bulbs have different colors, red orange yellow and cyan, then that last command will
decrease the saturation of those colors for each bulb, preserving red orange yellow cyan, but
all just a bit less intense in color. It's as if you had done "s-20%" as individual bulb
commands.

Creating a group as in the first line creates a context. You could have done this:

    phuecmd> new group "corners"     -- create a new bulb group  (quotes optional?)
    phuecmd> + B2 B4 B8 
    phuecmd> +  B9
    


## Colors


Specify a color several ways:
* CIE x,y and brightness
* hue, saturation and brightness
* color temperature (only for "white")
* changes to a bulb's current color
* by user-defined or built-in names

Brightness is just a plain number.  Saturation, hue, x, y have single letter prefixes.

    phuecmd> B9 76.7 x.313 y.355  
    phuecmd> B8  100 s100 h3300       -- sets brightness and sat to maximum, warm red hue
    phuecmd> warmpink = 80 x.56 y.32  -- define new color named "warmpink"
    phuecmd> new color "coldpink"     -- another way to define a new color
    phuecmd> 80 x.43                  -- that set a "context"; give actions in following lines
    phuecmd> y.22
    phuecmd> .                        -- any further stuff won't be taken as actions for this color
    phuecmd> B19 coldpink             -- make use of this newly made color

Changes to colors may be applied to bulbs or to defined colors. 
 
    phuecmd> hotgreen s+5%        -- changes definition of "hotgreen", nudge saturation up
    phuecmd> B5      x+.011       -- whatever color bulb 5 has, nudge CIE x up this much
    phuecmd> gold    .4           -- set new brightness for "gold"
    
    .6      no letter: brightness  from 0 to 1, or 0% to 100% 
    x       CIE coordinate, from 0.000 to 1.000 (realistically 0.15 to 0.65)
    y       CIE coordinate, 0.000 to 1.000 (realistically, .05 to 0.6)
    s       saturation in HSV system, 0 to 1.0, or 0% to 100%
    h       hue, from 0 to 65535, or ? (TBD)
    t       color temperature: white (or whitepoint for HSV system)  t3800  
    
    
Maybe: specify hues with one or more letters:
       M R O Y G C B V    = magenta red orange yellow green cyan blue violet
       RO  = halfway between red and orange
       YYG  = between yellow and green, with more yellow. YG, YGG are greener.
       
       
Named colors may be organized into palettes. One palette you're stuck with no matter
what is the built-in palette.  

    phuecmd> new palette "kitchenglory"
    phuecmd> + darkgold  hotgreen muddygreen yellow1 yellow2
    phuecmd> .
    phuecmd> list palettes         -- names of all palettes
    phuecmd> list kitchenglory     -- list all colors in this palette
    phuecmd> forget kitchenglory   -- delete this palette
    


## System Commands

There are commands for a hub to forget its bulbs, search for new bulbs, transfer a bulb's
ownership from one hub to another, etc but these are currently (Jan 2022) in flux and
will remain semi-undocumented for now.

    phuecmd> load *config-file-name*
    phuecmd> save *config-file-name*
    phuecmd> save *config-file-name* colors seq 
    phuecmd> save default hubs bulbs
    phuecmd> 
    phuecmd> forget bulbs
    phuecmd> forget hubs 


____

# Configuration File

For quick and easy startup, phuecmd will read the technical mumbo-jumbo defining
hubs and bulbs and systems from a file. A default file, probably ./config/phuecmd.json (?)
will be read automatically, unless a command line option specifies another file. 

A config file can contain any of:
* definitions of Hubs, Bulbs including Locations, names
* user-defined colors
* assignments of bulbs to playbacks
* user-defined sequences to be played back
* whatever else to get back into the same working state where you left off yesterday

TBD but for now I'm thinking: save all the stuff as JSON


## Loading and saving config files:

* "save" command by itself (with a file name) saves everything to a named file. 
* Optionally list just those types of info you want saved: hubs, bulbs, colors, ... 
(details TBD)
* Upon startup, always read ~/.config/phuecmd/config.json
* Prohibit reading the default config with command line option --no-default
* Upon exit, if hubs or bulbs have changed at all, save new info to that default file.
(Maybe ask: "Save changes of hubs/bulbs configuration to default config file?")
* "load" command reads in whatever is in the named file. Good luck not being surprised
if that file contains more than you expected!



____


# Work To Do


## Coding, internals, commands, short term refactoring and features

* Better way to define and execute commands.
* For initial effort, all things were lumped into one source file. Pull out colors, 
  Hub, Bulb and maybe other things to put into their own files. 
* Add unit tests to some of those new files. Colors: easy. Hub: might be hard to unit test, since
it depends on hardware.  
* Write code to search for hubs using network level actions, similar to running nmap at
the command line and then grepping for "Philips" and then reading the IP, MAC etc. 
* Write hub and bulb info to a config file. Recall that info upon starting phuecmd.
Search for bulbs, hubs only upon explicit request, or if a config file doesn't exist yet.
* No existence of sequences (series of colors over time), animation - this is the fun stuff!
* Needs a play thread, to scan through sequences, look for alarms/events, 
   and update bulbs periodically, on the order of once/second or thereabouts.
* Instead of writing a "to do" list like this, use a proper issue tracker. 
* the "Usage" above is long-winded. Better make it html, use good CSS, not rely on 
limited markdown styling. 

## Future Major Features

Maybe, maybe not.

* Do we really want just a command line program? Provide some sort of API for other
software to use. Make the working guts of phuecmd into a library or service with 
phuecmd as just one simple way for a user to interact with it. 
* Possibility that should be easy: Add an http server to phuecmd. Whenever it's running,
an SPA web app designed for the purpose could provide a GUI for the user, working 
over some specified localhost port.  Possibly, this could be expanded for remote use, 
but then one would have to think about security and networking. Getting outside my modest skillset!
* Define bulb actions for events such as email arriving, doorbell ringing, text messages
or calls arriving to a smartphone.  This involve more IoT and systems integration than
I would have time for, and gets closer to home automation which is already dealt
with adequately by other software. 
* Why are we using Philips' hubs?  Try direct zigbee control of bulbs. I'm not trying
to make use of the capabilities of the hub. 
* Expand to operate Lifx, other brands of controllable bulbs, other devices. Maybe DMX winches
and all sorts of theatrical devices. But that's getting into major app development, where
Philips Hue would be just a relatively small part. Besides, good software for total 
theatrical control over lights, machines, audio etc already exists. 


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
or just holler real loud near the alley with my cardboard box.


License
-------
MIT

