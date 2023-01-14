// Run lights randomly

import std.stdio;
import core.stdc.stdlib;
import std.format;
import std.string;
import dlangui;
import core.thread;
import phuecolor;
import phuesystem;

//extern (C) int kbhit();
//extern (C) int getch();


// Settings - hardcoded for now. In future, will be GUI sliders, checkboxes etc

float max_brightness = 0.5f;
Duration pause = dur!("seconds")(15);    // fast-paced for testing
int nsteps = 11;


void run_random_show(PhueSystem system)  {
    
    writeln("Tap ctrl-C or 'Q' to quit");
    ulong nbulbs = system.bulbs.length;
    
    PhueColor[] color1;   color1.length = nbulbs; 
    PhueColor[] color2;   color2.length = nbulbs;

    foreach (i, ref b; system.bulbs)  {
        b.set( ZERO_COLOR );
        color1[i] = ZERO_COLOR;
        color2[i] = random_color(0.5*max_brightness, max_brightness);
    }
    
    
    bool running = true;
    while (running) {
        for (float f = 0.0f;  f < 1.001f; f += 1.0f/nsteps)  {
            foreach (i, ref b; system.bulbs)  {
                b.set( sine_mix(color1[i], f, color2[i]) );
            }
            Thread.sleep(pause);
        }
        
        // Update color targets.
        color1[] = color2;
        foreach (i; 0 .. nbulbs)  {
            color2[i] = random_color(0.2f*max_brightness, max_brightness);
        }
//        writeln("  ", color1);
//        writeln("  ", color2);        
    }
    
}
