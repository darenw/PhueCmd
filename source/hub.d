// Hub.d
//
// Hub is our representative for the physical Phue bridge aka hub device, which 
// has direct control over the bulbs via Zigbee. 
// 
// A physical Hub is identified by an IP address (which could change, likely subject to
// DHCP), a MAC address (permanently set in its hardware) and a user-friendly name (optional).
// 

import std.stdio;
import std.string;
import std.conv;
import std.format;
import core.thread;

import std.json;
import std.net.curl;


// Hub's number for a bulb.
// Unique among bulbs belonging to a hub, 
// but same number may be used for a different bulb with a different hub.
alias BulbNumber = ushort;  // Hub's number for a bulb


class Hub  {
    string macaddr;      // what's best, ubyte[]? string? other?
    string ipaddr;       // something like "12.34.56.78"
    string password;     // mile long string of base 62
    string name;
    string myurl;        // for easy routine use of get/post/put/delete
    
    this(string mac0, string ip0, string pw0, string name0) {
        macaddr=mac0;
        ipaddr=ip0;
        password=pw0;
        name=name0;
        myurl = format("http://%s/api/%s/", 
                        ipaddr, password);
    }
    
    ~this() {
    }
    
    void describe_self_one_line()   {
        writefln("hub %s  %s  %s", ipaddr,  macaddr, name);
    }
    
    
    void send_bulb_settings(BulbNumber bulbnum, JSONValue cmd)  {
        string b = format("lights/%d/state", bulbnum);
writefln("Hub:sending(json) to bnum=%d <<%s>>((%s))", bulbnum, b, cmd);
        put(myurl ~ b, cmd.toString);
        
    }

    void send_bulb_settings(BulbNumber bulbnum, string jsoncmd)  {
        string b = format("lights/%d/state", bulbnum);
writefln("Hub:sending(str) to bnum=%d <<%s>>((%s)) myurl %s", bulbnum, b, jsoncmd, myurl);
        put( myurl ~ b, jsoncmd);
    }
    
    
    void get_all_hub_info()   {
        // https://dlang.org/phobos/std_format.html 
        auto stuff = get(myurl);
        writeln(stuff);
    }
    
    
    void find_new_physical_bulbs()  {
        writeln("Requesting search for new bulbs...");
        
        // An http POST with no body triggers hub into seeking new bulbs
        auto z = post( myurl ~ "lights", "" );
        Thread.sleep( dur!("msecs")( 600 ) );
        
        // Obtain list of newly found bulbs with GET lights/new
        auto newbulbs = JSONValue( get( myurl ~ "lights/new") );
        string newbulbnums = "";
        int count=0;
        foreach (string k, JSONValue x; newbulbs) {
            writef(" <<%s>> ", k);
            newbulbnums ~= format(" %d", k.to!int);
            count++;
        }
        writefln("Found %d new bulbs since %s:  %s", 
            count, newbulbs["lastscan"],  newbulbnums);
    }    
    
    void forget_all_physical_bulbs()  {
        auto spewage = get( myurl ~ "lights/");
        JSONValue lightslist = parseJSON(spewage);
        foreach (string bkey, JSONValue binfo; lightslist)  {
            int bnum = bkey.to!int;
            writef("deleting bulb num %s from hub %s (%s)... ", bnum, name, ipaddr);
            del( myurl ~ "lights/" ~ bkey);
            writefln("gone!");
        }

    }    
}

