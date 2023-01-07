// Wakeup procedure - waits until given clock time, then runs light sequence


import std.stdio;
import std.format;
import std.string;
import std.datetime;
import core.thread;
import core.time;
import dlangui;
import phuecolor;
import phuesystem;




void run_wakeup(PhueSystem system,  string alarm_start_time) {


    system.set_all_bulbs(PhueColor(0.1, 0.2, 0.2));
    system.set_all_bulbs(false);

    // Just a crude sanity check: prove we're here by making dim red
    system.bulbs[0].set( PhueColor(0.2, 0.55, 0.2) );

    Duration oneminute = dur!("minutes")(1);
    Duration tensec = dur!("seconds")(10);
    
//    auto wakeup_time1 =   SysTime.fromSimpleString( "2023-Jan-07 08:35:28" );
 //   auto wakeup_time2 =  SysTime.fromSimpleString( "2023-Jan-07 08:43:28" );
    auto wakeup_time1 =   SysTime.fromSimpleString( "2023-Jan-07 08:25:08" );
    auto wakeup_time2 =  SysTime.fromSimpleString( "2023-Jan-07 08:40:48" );
    writeln(Clock.currTime(), "  T1=", wakeup_time1, "  T2=", wakeup_time2);
    
    bool running = true;
    while (running)  {
        //Thread.sleep(oneminute);
        Thread.sleep(tensec);
        
        SysTime now = Clock.currTime();
        writeln(now, "  ", wakeup_time1, "  ", now > wakeup_time1  );
        if (now > wakeup_time1) {
            running=false;
            system.set_all_bulbs(true);
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
