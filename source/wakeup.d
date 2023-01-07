// Wakeup procedure - waits until given clock time, then runs light sequence


import std.stdio;
import std.format;
import std.string;
import dlangui;
import core.thread;
import phuecolor;
import phuesystem;


void run_wakeup(PhueSystem system,  string alarm_start_time) {

    // Just a crude sanity check: prove we're here by making dim red
    system.bulbs[0].set( PhueColor(0.2, 0.55, 0.2) );

}
