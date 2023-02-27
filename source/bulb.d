// Bulb.d    object to interface with physical bulb via a Hub

import std.stdio;
import std.format;
import std.math;
import phuecolor;
import hub;
import std.json;



enum BulbState { off, on };


class Bulb 
{
    string name;       // name for humans to use
    Hub hub;           // the Hub that knows about this Bulb
    bulbnumber bnum;   // id number known to Hub
    string model;
    string gamut;
    float  maxlumens;

    // Our idea of bulb's current physical state, on/off, color...
    BulbState state;
    PhueColor current_color;
    float  hue, sat;
    float colortemp;
    
    
    this(ref Hub _hub,  bulbnumber _bnum, string _name) {
        bnum = _bnum;
        hub  = _hub;
        name = _name;
    }
    
    void describe_self() {
        writefln("Bulb  %s H%dB%d %s  %s gamut %s",  
            name, 
            hub.index, 
            bnum,       
            current_color,
            model,
            gamut);
    }
    
    
    void turn(BulbState state)  {
        hub.setbulbstate(bnum, format(`{"on":%s}`,  state==BulbState.on?  "true" : "false"));
    }
    
    void turn(bool on)  {
        turn((on)? BulbState.on : BulbState.off);
    }
    
    
    void set(PhueColor color)  {
        current_color = color;
        int bri  = cast(int)floor(color.bri*255);
        string json = format(`{"bri":%d,"xy":[%.3f,%.3f]}`, bri, color.x, color.y);
        hub.setbulbstate(bnum, json);
    }
    
    
    
    void read_bulb_characteristics()  {
        JSONValue json = hub.get_bulb_json_info(bnum);
        gamut = json["capabilities"]["control"]["colorgamuttype"].str;
        model = json["modelid"].str;
    }
    
    
    void update_state_from_reality()   {
        JSONValue json = hub.get_bulb_json_info(bnum);
        auto statejson = json["state"];
        //writeln(name, ": ", statejson);
        this.state = (statejson["on"].boolean)? BulbState.on : BulbState.off;
        float bri;
        try {
            bri = statejson["bri"].integer/255.0f;
        } catch (Exception e) {
            writeln(e.msg);
        }
        auto x =  statejson["xy"][0].floating;
        auto y =  statejson["xy"][1].floating;
        current_color = PhueColor(bri, x, y);
    }
    
    
    void write_state(ref File statefile)  {
        statefile.writefln("\n[Bulb.%s]",  name);
        statefile.writefln("name=\"%s\"", name);
        statefile.writefln("state=\"%s\"", (state==BulbState.on)? "on":"off");
        statefile.writefln("bri=%.3f", current_color.bri);
        statefile.writefln("xy=[%.4f,%.4f]", current_color.x, current_color.y);

    // Our idea of bulb's current physical state, on/off, color...
    BulbState state;
    PhueColor current_color;
    float  hue, sat;
    float colortemp;
    

    }
    
    
    void write_config(ref File config)   {
        config.writefln("[Bulb.%s]", name);
        config.writefln("name=\"%s\"", name);
        if (model.length>0)
            config.writefln("model=\"%s\"", model);
        config.writefln("hubname=\"%s\"",  hub.name);
        config.writefln("idh=%d", bnum);
    }
}
