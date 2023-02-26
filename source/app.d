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
import timeofday;
import phuecolor;
import bulb;
import phuesystem;
import randomshow;
import wakeup;
import dlangui;
import toml;

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
                system.set_all_bulbs(BulbState.on);
                break;
            

            case "off":
                system.set_all_bulbs(BulbState.off);
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
                if (args.length<4)  {
                    writeln("usage:  blink  hub/bulb");
                    return;
                }
                string what = args[1];
                string id = args[2];
                switch (what)  {
                    case "hub":
                        writefln("Pretend to blink all lights on hub %s", id);
                        break;
                        
                    case "bulb":
                        writefln("Pretend to blink bulb %s", id);
                        break;
                        
                    default:
                }
                write("Any key to stop blinking...");
                auto x = stdin.readln();
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
                bulbindex ibulb = to!ushort(args[1]);
                if (ibulb >= system.bulbs.length) {
                    writefln("Bulb index too large; list has only %d bulbs", system.bulbs.length);
                    return;
                }
                PhueColor color = PhueColor( 
                                    to!float(args[2]),
                                    to!float(args[3]),
                                    to!float(args[4]));
                system.bulbs[ibulb].set( color );
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
            obey_command( strip(subline).split!isWhite );
    }



    void run_command_loop()  {
        while (running)  {
            string line = to!string( readline("phuecmd> ") );
            obey_command(line);
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
