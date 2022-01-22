// PhueCmd  main
// THIS INITIAL WRITING: hackwork! hardcoded, classes not put into own files.

import std.algorithm.searching;
import std.stdio;
import std.string;
import std.format;
import std.conv;
import std.json;
import std.net.curl;
import std.math.rounding;


alias hubindex = ushort;
alias bulbindex = ushort;
alias groupindex = ushort;
alias paletteindex = ushort;


Hub[] hubs;
Bulb[] bulbs;
Group[] groups;



class Hub  {
    hubindex myindex;
    string macaddr;      // what's best, ubyte[]? string? other?
    string ipaddr;       // something like "12.34.56.78"
    string password;     // mile long string of base 62
    string name, shortname;
    string myurl;        // for easy routine use of get/post/put/delete
    
    this(string mac0, string ip0, string pw0, string name0, string shortname0) {
        macaddr=mac0;
        ipaddr=ip0;
        password=pw0;
        name=name0;
        shortname=shortname0;
        myurl = format("http://%s/api/%s/", 
                        ipaddr, password);
        writeln("New Hub!  url = ", myurl);
    }
    
    ~this() {
    }
    
    
    void send_bulb_settings(bulbindex ibulb, JSONValue cmd)  {
        string b = format("lights/%d/state", bulbs[ibulb].bulbnum);
        put(myurl ~ b, cmd.toString);
        
    }

    void send_bulb_settings(bulbindex ibulb, string jsoncmd)  {
        string b = format("lights/%d/state", bulbs[ibulb].bulbnum);
        put( myurl ~ b, jsoncmd);
    }
    
    
    void get_all_hub_info()   {
        // https://dlang.org/phobos/std_format.html 
        auto stuff = get(myurl);
        writeln(stuff);
    }
}


void add_hub(string mac0, string ip0, string pw0, string name0, string shortname0)  {
    hubs.length++;
    hubs[$-1] = new Hub(mac0,ip0,pw0,name0,shortname0);
}



enum BulbState { OFF, ON }

class Bulb {
    bulbindex myindex;
    hubindex  imyhub;
    string name, shortname;
    int bulbnum;        // number assigned by hub
    
    this(hubindex ihub, string name0, string shortname0, int bulbnum0) {
        imyhub = ihub;
        name=name0;
        shortname=shortname0;
        bulbnum = bulbnum0;
        myindex = cast(bulbindex)bulbs.length;
        bulbs ~= this;
    }
    
    
    void turn(BulbState desired)   {
        send( (desired==BulbState.ON)? "true" : "false" );
    }
    
    void send(string jsoncmd)  {
        hubs[imyhub].send_bulb_settings(myindex, jsoncmd);
    }

    void send(JSONValue cmd)  {
        hubs[imyhub].send_bulb_settings(myindex, cmd);
    }

    void set_color(Color color)   {
        int bri = cast(int)floor(0.5+255*color.cie.L);
        writeln("SET_COLOR bri=", bri);
        string cmd = format(`{"bri":%d,"xy":[%.3f,%.3f]}`, bri,  color.cie.x, color.cie.y);
        writeln("CMD:  ", cmd);
        send( cmd);
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


class Group    {
    
    bulbindex[] mybulbs;
    string name, shortname;
    
    void eat(bulbindex ibulb)  {
        // can a bulb belong to more than one group? yes.
        // example: 
        //       all bulbs on top of bookshelf, 
        //       all bulbs along north wall, 
        //       all bulbs in corner of room
        // A bulb in the northwest corner is in two groups.
        // A bulb on the bookshelf along the north wall is in two groups
        
        if (canFind(mybulbs, ibulb)) 
            return;
        mybulbs.length++;
        mybulbs[$-1] = ibulb;
    }
}


struct HSVColor {
    float H, S, V;
}

struct CIEColor  {
    float L,x,y;
}

immutable CIEColor WHITE = {1.0f, 0.333, 0.333};  // placeholder 
immutable CIEColor WHITE50 = {0.5f, 0.333, 0.333};  // placeholder 
immutable CIEColor GREEN  = { 0.8, 0.27, 0.37};

class Color   {
    string name;
    CIEColor cie;
    
    this(string letters) { // for example  "RRV" for red, little bit violet
    }
    
    this(float L, float x, float y)   {
        cie.x=x, cie.y=y, cie.L=L;    
    }
    
    this(CIEColor given)  {
        cie = given;
        writeln("Color CONSTRUCT ", given.L,given.x, cie.L, cie.x);
    }
    
    
    this(float L, float temperature) {   // Black body white light
        cie.L = L;
        cie.x = 0.333;
        cie.y = 0.333; /*TODO*/  // palce-holder until i look up the old good code
    }
    
    
    Color create_brighter(float brightnes_change_percent)  const {
        return new Color(cie); 
    }
    
    Color mix(float percent_toward, Color target) const  {
        return new Color(WHITE50);
    }
}




int main(string[] args)  {
    writeln("START");
    
    // Hardcoded for my actual hardware at this time
    add_hub("00:17:88:21:8A:2E",
             "192.168.11.41",
             "78g2lrMNHZHZFozjDJ7z7lneQhl8guZpzssU0HIr",
             "Hub1537-2016",  "h1537"
             );
    add_hub("00:17:88:4D:97:4D",
             "192.168.11.10",
             "VHQitrMnCUvVb4YLmuTmYQvO54ZjUgihgSJGKTFy",
             "Hub1707-2017",   "h1707"
             );
    
    hubindex ihub1 = 0;   // the functional one, controls two bulbs
    hubindex ihub2 = 1;   // the newer one, seems to not control any for now
    
    if (false)  {
        hubs[ihub1].get_all_hub_info();
    }
    
    Bulb bulb29 = new Bulb(0, "Bedroom Lamp", "Bedrm", 29);
    writeln("YEEE!!!");
    bulb29.set_color(new Color(GREEN));
    
    writeln("END");
    return 0;
}
