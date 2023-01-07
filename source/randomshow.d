// Run lights randomly

import std.stdio;
import std.format;
import std.string;
import dlangui;
import core.thread;
import phuecolor;
import phuesystem;




void run_random_show(PhueSystem system)  {
    
    // Just a crude sanity check: prove we're here by making bright yellow
    system.bulbs[0].set( PhueColor(0.98, 0.53, 0.45) );
}
