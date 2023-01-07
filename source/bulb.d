// Bulb.d    object to interface with physical bulb via a Hub


import std.format;
import std.math;
import phuecolor;
import hub;


class Bulb 
{
    bulbnumber bnum;   // id number known to Hub
    Hub hub;           // the Hub that knows about this Bulb
    string name;       // name for humans to use

    PhueColor current_color;
    
    this(Hub _hub,  bulbnumber _bnum, string _name) {
        bnum = _bnum;
        hub  = _hub;
        name = _name;
        
    }
    
    void turn(bool on)  {
        hub.setbulbstate(bnum, format(`{"on":%s}`,  on? "true" : "false"));
    }
    
    void set(PhueColor color)  {
        current_color = color;
        int b  = cast(int)floor(color.bri*255);
        string json = format(`{"bri":%d,"xy":[%.3f,%.3f]}`, b, color.x, color.y);
        hub.setbulbstate(bnum, json);
    }
    
    
}
