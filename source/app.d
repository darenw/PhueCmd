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
import dlangui;
import core.thread;
import phuecolor;
import bulb;
import phuesystem;
import randomshow;
import wakeup;


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
        case "check":
            system.testflash();
            break;
        
        case "random":
            run_random_show(system);
            break;
            
        case "random1":
            foreach (b; system.bulbs)   {
                b.set( random_color() );
            }
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
            writefln("Unknown command %s", cmd);
    }
}



void main(string[] args)
{
    //
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
                
        case 3: 
                if (args[1]=="wakeup")
                    run_wakeup(system, args[2]);
                else
                    RunGui(system,args);
                break;
                
        default:
                RunGui(system, args);
    }
}
