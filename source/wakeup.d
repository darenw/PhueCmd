// Wakeup procedure - waits until given clock time, then runs light sequence


import std.stdio;
import std.format;
import std.string;
import std.datetime;
import core.thread;
import core.time;
import dlangui;
import bulb;
import phuecolor;
import phuesystem;



void run_wakeup(PhueSystem system,  string alarm_start_time, bool keep_init_state=false) {

    if (!keep_init_state) {
        system.set_all_bulbs(BulbState.off);
    }

    // Just a crude sanity check: prove we're here by making dim red
    system.bulbs[0].set( PhueColor(0.2, 0.55, 0.2) );

    Duration oneminute = dur!("minutes")(1);
    Duration tensec = dur!("seconds")(10);
    
    auto wakeup_time1 =  SysTime.fromSimpleString( "2023-Jan-08 06:53:28" );
    auto wakeup_time2  =  SysTime.fromSimpleString( "2023-Jan-08 07:02:28" );
    writeln("Time now:  ",  Clock.currTime());
    writeln("  wakeup:  ",  wakeup_time1);
    writeln("    peak:  ",  wakeup_time2);
    
    bool running = true;
    while (running)  {
        Thread.sleep(oneminute);
        //Thread.sleep(tensec);
        
        SysTime now = Clock.currTime();
        writeln(now, "  ", wakeup_time1, "  ", now > wakeup_time1  );
        if (now > wakeup_time1) {
            running=false;
            system.set_all_bulbs(BulbState.on);
            system.set_all_bulbs( PhueColor( 0.2, 0.2, 0.3) );
        }
    }


    running = true;
    while (running)  {
        //Thread.sleep(oneminute);
        Thread.sleep(tensec);
        
        SysTime now = Clock.currTime();
        writeln(now, "  ", wakeup_time2, "  ", now > wakeup_time2  );
        if ( now > wakeup_time2 ) {
            running=false;
            system.set_all_bulbs( PhueColor( 1.0, 0.3, 0.3) );
        }
    }

}
