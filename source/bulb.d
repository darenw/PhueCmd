// Bulb.d
//
// A Bulb object is our representative, or ambassador, to one specific physical bulb.
// During runtime, there are normally as many Bulb objects in a PhueSystem as there
// are physical bulbs to be controlled. 
// 
// Bulb know how to relate user-space concepts such as color, brightness changes
// to JSON for use by the HTTP REST interface. It does not actually perform any http though;
// this is up to the Hub object which in most use cases there is only one of.
// Hub knows the IP address and other mumbo-jumbo to perform the http REST work.

import std.stdio;
import std.string;
import std.conv;
import std.format;
import std.json;
import std.math;

import hub;
import phuecolor;


enum BulbState { OFF, ON }


alias bulbindex = ushort;     // unique id number within a multi-hub PhueSystem


class Bulb {
    bulbindex myindex;   // number unique among all bulbs, all hubs in a PhueSystem
    Hub myhub;
    string name, descr;
    BulbNumber num;        // number assigned by hub
    CIEColor latest_color;
    HSVColor latest_color_hsv;
    float    latest_color_temp;
    BulbState     latest_onoff_state;
    
    this(Hub hub, string name0,  BulbNumber bnum) {
        /*TODO*/ // check if any existing bulb has same bulbnum
        myhub = hub;
        name=name0;
        num = bnum;
    }
    
    void describe_self_one_line()   {
        writefln("bulb[%d] hub[%s] bnum=%d   %s %s", 
            myindex, myhub.name, num, name, descr);
    }
    
    
    void turn(BulbState desired)   {
        writefln("Bulb.turn(%d)   msg=%s", desired,  (desired==BulbState.ON)? "{\"on\":true}" : "{\"on\":false}" );
        send( (desired==BulbState.ON)? "{\"on\":true}" : "{\"on\":false}" );
        // if successful, 
            latest_onoff_state = desired;
    }
    
    
    void send(string jsoncmd)  {
    writefln("Bulb[bnum=%d,i=%d].SEND(str) %s  myhub.name=%s", num, myindex, jsoncmd, myhub.name);
        myhub.send_bulb_settings(num, jsoncmd);
    }

    void send(JSONValue cmd)  {
    writefln("Bulb[bnum=%d,i=%d].SEND(json) %s myhub:name=%s", num, myindex, cmd,myhub.name);
        myhub.send_bulb_settings(num, cmd);
    }

    void set_color(Color color)   {
        int bri = cast(int)floor(0.5+255*color.cie.L);
        string cmd = format(`{"bri":%d,"xy":[%.3f,%.3f]}`, bri,  color.cie.x, color.cie.y);
        send(cmd);
    }
    
    void set_color(CIEColor cie)  {
        set_color(new Color(cie));
    }
    
    void set_color_BAD(Color color)  {
        JSONValue cmd = [ "on": "true"];
        writeln("aaaaa json=",  cmd);
        cmd.object["bri"] = JSONValue(color.cie.L);
        writeln("bbbbbb json=", cmd);
        cmd.object["xy"] = JSONValue( [color.cie.x, color.cie.y] );
        writeln("ccccc  json=", cmd);
        send(cmd);
        writeln("ssssss");
    }
}

