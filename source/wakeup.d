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



TimeOfDay todnow()  {
    SysTime stnow = Clock.currTime();
    TimeOfDay tnow = cast(TimeOfDay)stnow;
    return tnow;
}



void run_wakeup(PhueSystem system,  TimeOfDay t_awaken,  bool keep_init_state=false) {

    if (!keep_init_state) {
        system.set_all_bulbs(BulbState.off);
    }

    Duration one_minute = dur!("minutes")(1);  // normal
    Duration ten_sec = dur!("seconds")(7);    // fast-paced for testing
    Duration fast = dur!("seconds")(4);
    auto time_check_period = one_minute;
    
    TimeOfDay t_now = todnow();
    writeln("Starting wakeup clockwatching at ", t_now);


    // We are usually setting alarm in late morning, afternoon, evening of
    // prev day.  Wait for EOD before doing anything else.
    // If setting alarm at 2AM, this step is quick, does nothing.
    bool done = false;
    while (!done)   {
        Thread.sleep(time_check_period);
        t_now = todnow();
        done = (t_now < t_awaken);
    }
    writeln("EOD watch is done.");
    
    
    // Now we're in the wee early hours of the day during with to awaken
    // Just watch for t_awake, then being the light sequencing process
    done = false;
    while (!done)   {
        Thread.sleep(time_check_period);
        t_now = todnow();
        done = (t_now > t_awaken);
    }
    

    // Whoo-hoo! Start the light sequence!
    PhueColor twilight       = PhueColor( 0.10, 0.23, 0.21);
    PhueColor sunrise_orange = PhueColor(0.2, 0.57, 0.37);
    PhueColor daylight       =  blackbody(5600);
    
    system.set_all_bulbs(BulbState.on);
    foreach (j; 0 .. 6)   {
      system.set_all_bulbs( mix(twilight, (j/5.0)*(j/5.0), sunrise_orange) );
      Thread.sleep(one_minute);
      //Thread.sleep(fast);
    }
    
    foreach (j; 0 .. 6)   {
      system.set_all_bulbs( mix(sunrise_orange, j/5.0, daylight) );
      Thread.sleep(one_minute);
      //Thread.sleep(fast);
    }
    
}
