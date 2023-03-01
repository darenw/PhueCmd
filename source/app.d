/*
 * MorningPhue: a GUI app for automatically controlling Philips Hue lights 
 * Intended to turn up lights gradually before sunrise to wake up sleepy humans
 * but may be used for all sorts of other things.
 * 
 * For now, Linux only.
 * 
 * How to build:
 *    bash>  dub build
 * 
 */


import std.stdio;
import std.format;
import std.string;
import std.ascii;
import std.uni : isWhite;
import std.algorithm;
import std.datetime;
import core.thread;
import gnu.readline;
//import gnu.history;
import timeofday;
import phuecolor;
import bulb;
import hub;
import phuesystem;
import randomshow;
import wakeup;
import dlangui;
import toml;

extern (C) {
    void add_history(const char*);
}


immutable PHUECMD_Version = "PhueCmd Version 0.1";

immutable string helptext = q"ZZZ
PhueCmd: operate your Philips Hue bulbs in fun and useful ways.
(Work in progress, may be buggy, don't use for life-critical applications, etc.)

Usage:
     bash> phuecmd help          -- prints what you are reading now
     bash> phuecmd list          -- prints out all hubs and bulbs known atm
     bash> phuecmd gui           -- run GUI version (NOT IMPLEMENTED YET!)
     bash> phuecmd <cmd>         -- any command listed below is fine on command line
     bash> phuecmd quit          -- why? makes no sense, but legal.
     bash> phuecmd               -- no args => command mode
     
     phuecmd> help           -- prints what you are reading now
     phuecmd> random         -- infinite loop running bulbs with random colors
     phuecmd> random1        -- Just once right now, set bulbs to random colors
     phuecmd> wakeup 7:40    -- all off, then slow brighten stating at 7:40
     phuecmd> now            -- prints date, time right now
     phuecmd> wait 12        -- wait for 12 seconds (for command mode)
     phuecmd> canned         -- load hardcoded setup (works only for me!)
     phuecmd> load somename  -- load setup from somename.sys.toml
     phuecmd> save somename  -- save system setup and bulb states to toml files
     phuecmd> on             -- turn on all bulbs. Colors same as before.
     phuecmd> off            -- turn off all bulbs.
     phuecmd> set n bri x y  -- set brightness, color of one bulb. Bri=0.0 to 1.0
     phuecmd> 6500K          -- all bulbs set to Planck blackbody temperature 6500K
     phuecmd> bright         -- set all bulbs to brightest white (
     phuecmd> dimblue        -- set all bulbs to dim blue-violet
     phuecmd> half           -- make all bulbs half as bright 
     phuecmd> random1 ; wait 15 ; random1
     phuecmd> quit           -- exit command mode
ZZZ";





class Commander  {
    bool running;
    PhueSystem system;

    this(PhueSystem ps)  {
        system = ps;
        running = true;
    }
    
    
    void  turn_bulbs(BulbState desired_state, string[] args)  {
        if (args.length==1)
            system.set_all_bulbs(desired_state);
        else foreach (arg; args[1 .. $]) {
            Bulb  b = system.find_bulb(arg);
            if (b)  b.turn(desired_state);
        }
    }

    
    void blink(string[] names)  {
        
        Duration pause = dur!("seconds")(1); 
        bool performing = true;
        bool on = true;
        int count = 11;   // odd number to leave them on when done
        while (performing && count>0)  {
            foreach (name; names)  {
                Hub h = system.find_hub(name);
                if (h)   {
                    foreach (b; system.bulbs) {
                        if (b.hub == h) {
                            b.turn(on);
                        }
                    }
                }
                else {
                    Bulb b = system.find_bulb(name);
                    if (b)
                        b.turn(on);
                }
                    
            }
            Thread.sleep(pause);
            count--;
            on = !on;
        }
    }
    
    
    
    void obey_command(string[] args)   {
    //    writeln("Obeying ", args);
        
        string cmd = args[0];

        switch (cmd)   {
            
            case "quit":
                running = false;
                break;
                
                
            case "gui":
                writeln("Pretend running gui...");
                break;
                
                
            case "list":
                system.listAll();
                break;
                
                
            case "find":
                foreach (arg; args[1 .. $])  {
                    writef("Searching for entity \"%s\"... ", arg);
                    bool found_anything=false;
                    Hub h = system.find_hub(arg);
                    Bulb b = system.find_bulb(arg);
                    if (h)  {
                        found_anything=true;
                        h.describe_self();
                    }
                    if (b)  {
                        found_anything=true;
                        b.describe_self();
                    }
                    if (!found_anything) {
                        writefln("   %s not found among bulbs or hubs", arg);
                    }
                }
                break;
                
            case "saveconfig":
                system.saveSystemConfig("x.toml");
                break;
                
                
            case "random":
                run_random_show(system);
                break;
                
                
            case "random1":
                foreach (ref b; system.bulbs)   {
                    b.set( random_color() );
                }
                break;


            case "now":
                auto now = Clock.currTime().toString();
                writeln(now[0 .. 20]);
                break;
                
            case "on":
                turn_bulbs(BulbState.on, args);
                break;
            

            case "off":
                turn_bulbs(BulbState.off, args);
                break;
            
            
            case "dimblue":
                system.set_all_bulbs(BulbState.on);
                system.set_all_bulbs(PhueColor(0.06, 0.17, 0.13));
                break;


            case "bright":
                system.set_all_bulbs(BulbState.on);
                system.set_all_bulbs(PhueColor(1.0, 0.33, 0.33));
                break;

            
            case "dimred":
                system.set_all_bulbs(BulbState.on);
                system.set_all_bulbs(PhueColor(0.013, 0.6, 0.35));
                break;

            
            case "half":
                foreach (ref b; system.bulbs)  {
                    auto c = b.current_color;
                    b.set( PhueColor( c.bri/2, c.x, c.y ) );
                }
                break;


            case "help":
            case "--help":
            case "-h":
                writeln(helptext);
                break;
            
            
            case "version":
            case "-v":
            case "--version":
                writeln(PHUECMD_Version);
                break;


            case "wait":
                Duration dur = dur!("seconds")( to!int(args[1]) ); 
                Thread.sleep(dur);
                break;
                
                
            case "blink":
                if (args.length<2)  {
                    writeln("usage:  blink  name name name ...  where name is a hub or bulb designation");
                    return;
                }
                blink(args[1 .. $]);
                break;
                
                
            case "canned":
                system.loadCannedSystemDSW();
                break;
            
            
            case "load": 
                system.loadSystemConfig(format("%s.sys.toml", args[1]));
                break;
                
                
            case "save":
                string n = "phuecmd";
                if (args.length>=2)  
                        n = args[1];
                system.saveSystemConfig( format("%s.sys.toml", n) );
                system.SaveBulbStates( format("%s.state.toml", n) );
                break;
            
            
            case "colorcode":
                writeln("Pretend setting bulbs to color codes for id numbers");
                break;


            case "wakeup": 
                std.datetime.date.TimeOfDay tawake;
                try {
                    tawake = tod(args[1]);
                    writeln("wakeup set for ", tawake);
                } catch (DateTimeException) {
                    writeln("Muddled alarm start time: ", args[1], " - ignoring");
                    return;
                }
                run_wakeup(system, tawake, true);
                break;


            case "set": 
                writeln("SET given: ", args);
                if (args.length < 4) {
                }
/*                bulbindex ibulb = to!ushort(args[1]);
                if (ibulb >= system.bulbs.length) {
                    writefln("Bulb index too large; list has only %d bulbs", system.bulbs.length);
                    return;
                }
*/ 
                Bulb bulb = system.find_bulb(args[1]);
                PhueColor color = PhueColor( 
                                    to!float(args[2]),
                                    to!float(args[3]),
                                    to!float(args[4]));
                //system.bulbs[ibulb].set( color );
                if (bulb) {
                    bulb.set(color);
                }
                break;
            

            case "adj":
                // parse for bulbname;   bri, sat, hue x, y;  +-11, +-%, ...
                break;
                
                
            default:
                // See if it's a temperature like "3600K"
                char last = cmd[$-1];
                if (isDigit(cmd[0]) && (last=='K' || last=='k')) {
                    float T = to!float(cmd[0 .. $-1]);
                    writeln(" /", last, "/   T=", T, "   allbutlast ", cmd[$-1] );
                    system.set_all_bulbs( blackbody(T) );
                } else {
                    writefln("Unknown command %s", cmd);
                }
        }
    }


    void obey_command(string line)  {
        // User may be entering multiple commands sep'd by ; 
        foreach (subline; (strip(line)).split(";")) 
            //obey_command( strip(subline).split!isWhite );
            obey_command( strip(subline).split );
    }



    void run_command_loop()  {
        while (running)  {
            string line = to!string( readline("phuecmd> ") );
            line = strip(line);
            if (line.length>0)  {
                add_history( std.string.toStringz(line) );
                obey_command(line);
            }
        }
    }


}


void main(string[] args)
{
    // Should create system from config file, network search, or other means
    // but for now, all I have is hardcoded info
    PhueSystem system = new PhueSystem();
    Commander  commander = new  Commander(system);
    
    //system.loadCannedSystemDSW();
    system.loadSystemConfig("phuecmd.sys.toml");

    
    switch (args.length)  {
        case 1: 
                commander.run_command_loop();
                break;
                
        default:
                commander.obey_command(args[1 .. $]);
    }
    
}
