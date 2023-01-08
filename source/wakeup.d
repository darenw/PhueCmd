// Wakeup procedure - waits until given clock time, then runs light sequence


import std.stdio;
import std.format;
import std.string;
import std.ascii;
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
    
    auto tnow = Clock.currTime();
    string nowstr = tnow.toString();

    // Yeah, this is bad messy logic, works for happy cases and catches only a few bad cases.
    bool good = false;
    if (alarm_start_time.length==3)  {
        good =  isDigit( alarm_start_time[0] ) &&
                alarm_start_time[1]==':'       &&
                isDigit( alarm_start_time[2] ) &&
                isDigit( alarm_start_time[3] );
        if (good)
            alarm_start_time = "0" ~ alarm_start_time;
    } 
    else if (alarm_start_time.length==4)  {
        good =  isDigit( alarm_start_time[0] ) &&
                isDigit( alarm_start_time[1] ) &&
                alarm_start_time[2]==':'       &&
                isDigit( alarm_start_time[3] ) &&
                isDigit( alarm_start_time[4] );    
    }
    
    if (false &&  !good)   {
        writeln("Muddled alarm start time: ", alarm_start_time, " - ignoring");
        system.set_all_bulbs(BulbState.on);
        return;
    }
    
    string startstr = nowstr[0 .. 12] ~ alarm_start_time ~ ":00";    
    auto t_alarm_start = SysTime.fromSimpleString(startstr);
    auto t_alarm_peak =  t_alarm_start; // PLUS TEN MINUTES  how to do???
    
    // Alternative: hardcoded to use during dev, in case above manipulations don't work
   //   t_alarm_start =  SysTime.fromSimpleString( "2023-Jan-08 06:53:28" );
   //   t_alarm_peak  =  SysTime.fromSimpleString( "2023-Jan-08 07:02:28" );
    t_alarm_start =  SysTime.fromSimpleString( "2023-Jan-08 07:53:18" );
    t_alarm_peak  =  SysTime.fromSimpleString( "2023-Jan-08 07:59:48" );
    
    
    writeln("Time now:  ",  Clock.currTime());
    writeln("  wakeup:  ",  t_alarm_start);
    writeln("    peak:  ",  t_alarm_peak);
    
    bool running = true;
    while (running)  {
        //Thread.sleep(oneminute);
        Thread.sleep(tensec);
        
        SysTime now = Clock.currTime();
        writeln(now, "  ", t_alarm_start, "  ", now > t_alarm_start  );
        if (now > t_alarm_start) {
            running=false;
            system.set_all_bulbs(BulbState.on);
            system.set_all_bulbs( PhueColor( 0.2, 0.2, 0.3) );
        }
    }


    running = true;
    while (running)  {
        Thread.sleep(oneminute);
        //Thread.sleep(tensec);
        
        SysTime now = Clock.currTime();
        writeln(now, "  ", t_alarm_peak, "  ", now > t_alarm_peak  );
        if ( now > t_alarm_peak ) {
            running=false;
            system.set_all_bulbs( PhueColor( 1.0, 0.3, 0.3) );
        }
    }

}
