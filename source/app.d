/*
 * MorningPhue: a GUI app for automatically controlling Philips Hue lights 
 * Intended to turn up lights gradually before sunrise to wake up sleepy humans
 * but may be used for all sorts of other things.
 * 
 * For now, Linux only.
 * 
 */


import std.stdio;
import std.format;
import std.string;
import std.ascii;
import std.algorithm;
import std.datetime;
import core.thread;
import phuecolor;
import bulb;
import phuesystem;
import randomshow;
import wakeup;
import dlangui;


immutable string helptext = q"ZZZ
PhueCmd: operate your Philips Hue bulbs in fun and useful ways.
(Work in progress, may be buggy, don't use for life-critical applications, etc.)

Usage:
     bash> phuecmd help          -- prints this help
     bash> phuecmd check         -- sets all bulbs white, off, white, random
     bash> phuecmd random        -- infinite loop running bulbs with random colors
     bash> phuecmd wakeup 7:40   -- all off, then slow brighten stating at 7:40
     bash> phuecmd  ...          -- other usages TBD 
ZZZ";


void RunGui(PhueSystem system,  string[] args) {
    writeln("Pretend running gui...");
}


void SimpleCommand(PhueSystem system, string cmd)  {
    switch (cmd)   {
        case "list":
            system.listAll();
            break;
                
        case "random":
            run_random_show(system);
            break;
            
        case "random1":
            foreach (b; system.bulbs)   {
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

        case "help":
            writeln(helptext);
            break;
            
        default:
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


TimeOfDay tod(string arg)   {
    auto parts = arg.findSplit(":");
    if (parts[1].length==0) {
        throw new DateTimeException("no : in time of day");
    }
    int h = to!int(parts[0]);
    int m, s;
    auto x = parts[2].findSplit(":");
    try {
        if (x[2].length>0)  {
            m = to!int(x[0]);
            s = to!int(x[2]);
        } else {
            m = to!int(x[0]);
            s = 0;
        }
    } catch (Exception) {
        throw new DateTimeException("Can't parse mm:ss");
    }
    return TimeOfDay(h, m, s);
}



void FancierCommand(PhueSystem system, string[] args)  {
    
    string cmd = args[1];
    
    switch (cmd)  {

        case "wakeup": 
            TimeOfDay tawake;
            try {
                tawake = tod(args[2]);
                writeln("wakeup set for ", tawake);
            } catch (DateTimeException) {
                writeln("Muddled alarm start time: ", args[2], " - ignoring");
                return;
            }
            run_wakeup(system, tawake, true);
            break;
        
        case "set": 
            bulbindex ibulb = to!ushort(args[2]);
            PhueColor color = PhueColor( 
                                to!float(args[3]),
                                to!float(args[4]),
                                to!float(args[5]));
            system.bulbs[ibulb].set( color );
            break;
        
        
        default:
                RunGui(system, args);
    }
}



void main(string[] args)
{
    // Should create system from config file, network search, or other means
    // but for now, all I have is hardcoded info
    PhueSystem system = new PhueSystem();
    system.loadCannedSystemDSW();
    
 
    switch (args.length)  {
        case 1: 
                RunGui(system, null);
                break;
                
        case 2: 
                SimpleCommand(system, args[1]);
                break;
        
        default:
                FancierCommand(system, args);
    }
}
