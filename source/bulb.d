// Bulb.d    object to interface with physical bulb via a Hub

import std.stdio;
import std.format;
import std.math;
import phuecolor;
import hub;


enum BulbState { off, on };


class Bulb 
{
    bulbnumber bnum;   // id number known to Hub
    Hub hub;           // the Hub that knows about this Bulb
    PhueColor current_color;
    string gamut;
    string model;
    string name;       // name for humans to use

    
    this(ref Hub _hub,  bulbnumber _bnum, string _name) {
        bnum = _bnum;
        hub  = _hub;
        name = _name;
    }
    
    void turn(BulbState state)  {
        hub.setbulbstate(bnum, format(`{"on":%s}`,  state==BulbState.on?  "true" : "false"));
    }
    
    void set(PhueColor color)  {
        current_color = color;
        int b  = cast(int)floor(color.bri*255);
        string json = format(`{"bri":%d,"xy":[%.3f,%.3f]}`, b, color.x, color.y);
        hub.setbulbstate(bnum, json);
    }
    
    
}
