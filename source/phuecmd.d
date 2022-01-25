// PhueCmd  main
// THIS INITIAL WRITING: hackwork! hardcoded, classes not put into own files.


import std.stdio;
import std.string;
import std.format;

import std.ascii; 
//import std.uni;
//https://forum.dlang.org/post/dfpyivbwueemnyadknco@forum.dlang.org

import std.conv;
import std.math;
import std.algorithm.searching;
import std.json;
import std.net.curl;
//import std.thread;
import core.thread;


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
    
    void describe_self_one_line()   {
        writefln("hub[%d] %s %s  %s (%s)", myindex, ipaddr,  macaddr, name, shortname);
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
    
    void find_new_physical_bulbs()  {
        writeln("Requesting search for new bulbs...");
        
        // An http POST with no body triggers hub into seeking new bulbs
        auto z = post( myurl ~ "lights", "" );
        Thread.sleep( dur!("msecs")( 600 ) );
        
        // Obtain list of newly found bulbs with GET lights/new
        auto newbulbs = JSONValue( get( myurl ~ "lights/new") );
        
        
    }    
    
    void forget_all_physical_bulbs()  {
        auto spewage = get( myurl ~ "lights/");
        JSONValue lightslist = parseJSON(spewage);
        foreach (string bkey, JSONValue binfo; lightslist)  {
            int bnum = bkey.to!int;
            writef("deleting bulb num %s from hub[%s]... ", bnum,  myindex);
            del( myurl ~ "lights/" ~ bkey);
            writefln("gone!");
        }

    }

    
    void read_known_bulbs()   {
        // DANGER! Does not check if bulb already in bulbs[]
        auto spewage = get( myurl ~ "lights/");
        JSONValue lightslist = parseJSON(spewage);
        foreach (string bkey, JSONValue binfo; lightslist)  {
            int bnum = bkey.to!int;
            string boringname = format("H%dB%d", myindex, bnum);
            writefln("FOUND BULB: H=%d BN=%d %s %s %s", myindex, bnum, 
                lightslist[bkey]["state"],
                lightslist[bkey]["modelid"],
                lightslist[bkey]["name"]
                );
            Bulb b = new Bulb(myindex, boringname, boringname, bnum);
        }
    }
}


void add_hub(string mac0, string ip0, string pw0, string name0, string shortname0)  {
    hubs.length++;
    hubs[$-1] = new Hub(mac0,ip0,pw0,name0,shortname0);
}

void list_all_hubs()  {
    foreach (Hub hub; hubs)  {
        hub.describe_self_one_line();
    }
}


enum BulbState { OFF, ON }

class Bulb {
    bulbindex myindex;
    hubindex  imyhub;
    string name, shortname, descr;
    int bulbnum;        // number assigned by hub
    CIEColor latest_color;
    HSVColor latest_color_hsv;
    float    latest_color_temp;
    BulbState     latest_onoff_state;
    
    this(hubindex ihub, string name0, string shortname0, int bulbnum0) {
        /*TODO*/ // check if any existing bulb has same bulbnum
        imyhub = ihub;
        name=name0;
        shortname=shortname0;
        bulbnum = bulbnum0;
        myindex = cast(bulbindex)bulbs.length;
        bulbs ~= this;
    }
    
    void describe_self_one_line()   {
        writefln("B%d hnum=%d  %s %s", imyhub, bulbnum, shortname, descr);
    }
    
    
    void turn(BulbState desired)   {
        send( (desired==BulbState.ON)? "{\"on\":true}" : "{\"on\":false}" );
        // if successful, 
            latest_onoff_state = desired;
    }
    
    
    void send(string jsoncmd)  {
        hubs[imyhub].send_bulb_settings(myindex, jsoncmd);
    }

    void send(JSONValue cmd)  {
        hubs[imyhub].send_bulb_settings(myindex, cmd);
    }

    void set_color(Color color)   {
        int bri = cast(int)floor(0.5+255*color.cie.L);
        string cmd = format(`{"bri":%d,"xy":[%.3f,%.3f]}`, bri,  color.cie.x, color.cie.y);
        send( cmd);
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

immutable CIEColor MAXWHITE   = {1.0, 0.351, 0.350};
immutable CIEColor DIMGRAY    = {0.1, 0.351, 0.350};
immutable CIEColor ZEROBRIGHT = {0.0, 0.333, 0.333};
immutable CIEColor MAXGREEN   = {1.0, 0.300, 0.59};

immutable min_color_temp =  1400;  // ?? min somewhere around here
immutable max_color_temp = 20000;  // another guess. no appearance change beyond this.


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
    }
    
        
    Color create_brighter(float brightnes_change_percent)  const {
        return new Color(cie); 
    }
    
    Color mix(float percent_toward, Color target) const  {
        return new Color(1.0, 0.33, 0.3);// dumb place-holder /*TODO*/
    }
}


CIEColor blackbody(float temp)   {
	// https://en.wikipedia.org/wiki/Planckian_locus 
	float m = 1000.0/temp;
	float x,y;
	
	if (temp<=4000.0)  {
		x = ((-0.2661239*m - 0.2343589)*m + 0.8776956)*m + 0.179910;
		if (temp<2222.0)  
			y = ((-1.1063814*x - 1.34811020)*x + 2.18555832)*x - 0.20219683;
		else
			y = ((-0.9549476*x - 1.37418593)*x + 2.09137015)*x - 0.16748867;
		
	}else{
		x = ((-3.0258469*m + 2.10703790)*m + 0.2226347)*m + 0.240390;
		y = (( 3.0817580*x - 5.87338670)*x + 3.75112997)*x - 0.37001483;
	}
	return CIEColor(1.0, x, y);
}



struct NamedColorDef  {
    CIEColor cie;
    string name;  
}



// Define some handy "obvious" colors, just to have some useful quick
// functionality before dealing with palettes, sequences, good design.
// Note: intent with names is to be case-don't-matter, but
// print out colors as camel case
NamedColorDef[] named_colors = [
    { cie:{1.0, 0.333, 0.333},  name:"equal"},  // Equal Energy White
    { cie:{1.00, 0.381, 0.370},   name:"white"},
    { cie:{0.25, 0.381, 0.380},   name:"gray"},
    { cie:{1.00, 0.482, 0.440},   name:"yellow"},
    { cie:{0.20, 0.524, 0.395},   name:"brown"},
    { cie:{0.75, 0.280, 0.451},   name:"green"},
    { cie:{0.76, 0.215, 0.196},   name:"blue"},
    { cie:{0.60, 0.251, 0.115},   name:"violet"},
    { cie:{0.70, 0.321, 0.12},   name:"purple"},
    { cie:{0.83, 0.381, 0.13},   name:"magenta"},
    { cie:{0.70, 0.441, 0.320},   name:"scent"},
    { cie:{0.50, 0.505, 0.255},   name:"coldred"},
    { cie:{0.81, 0.601, 0.320},   name:"red"},
    { cie:{1.00, 0.262, 0.300},   name:"sky"},
    { cie:{0.16, 0.386, 0.430},   name:"olive"},
    { cie:{0.91, 0.584, 0.379},   name:"orange"},
];


CIEColor[string] named_color_dictionary;

void init_named_colors() {
    if (named_color_dictionary.length==0)  {
        foreach (NamedColorDef z; named_colors)  {
            named_color_dictionary[z.name]=z.cie;
        }
    }    
}


CIEColor[10] color_code_colors = [
    /* 0 */  { 0.10, 0.33, 0.33},
    /* 1 */  { 0.26, 0.54, 0.39},
    /* 2 */  { 0.70, 0.63, 0.32},
    /* 3 */  { 0.87, 0.56, 0.39},
    /* 4 */  { 0.98, 0.48, 0.46},
    /* 5 */  { 0.70, 0.30, 0.48},
    /* 6 */  { 0.71, 0.21, 0.21},
    /* 7 */  { 0.64, 0.22, 0.12},
    /* 8 */  { 0.35, 0.33, 0.33},
    /* 9 */  { 0.98, 0.33, 0.33},
];


void dim_all_bulbs() {
    for (bulbindex ib=0; ib<bulbs.length; ib++)  {
        bulbs[ib].set_color(new Color(ZEROBRIGHT));
    }
}

void colorize_bulbs(int idigit, bool wantbulbindex)  {
    Thread.sleep( dur!("msecs")( 300 ) );    
    dim_all_bulbs();
    for (bulbindex ib=0; ib<bulbs.length; ib++)  {
        ushort n = to!ushort( (wantbulbindex)? bulbs[ib].myindex : bulbs[ib].bulbnum );
        ushort[3] digit;
        digit[2]=n/100;
        ushort r = to!ushort( n-100*digit[2] );
        digit[1]=r/10;
        digit[0]= to!ushort( r-10*digit[1] );
        
        bulbs[ib].set_color(new Color(color_code_colors[digit[idigit]]));
    }
    Thread.sleep( dur!("msecs")( 900 ) );
}


void animate_color_by_bulbindex( )   {
    colorize_bulbs(2,false);
    colorize_bulbs(1,false);
    colorize_bulbs(0,false);
    for (bulbindex ib=0; ib<bulbs.length; ib++)  {
        bulbs[ib].set_color(new Color(ZEROBRIGHT));
    }
}


void list_all_bulbs()    {
    foreach (Bulb bulb; bulbs)  {
        bulb.describe_self_one_line();
    }
}


void refresh_bulbs_list() {
    bulbs.length=0;
    foreach (hub; hubs)  {
        hub.read_known_bulbs();
    }
}


int main(string[] args)  {
    writeln("START");
    init_named_colors();
    
    hubindex icurrenthub = 0;   // none
    
    // Hardcoded for my actual hardware at this time
    add_hub("00:17:88:21:8A:2E",
             "192.168.11.41",
             "78g2lrMNHZHZFozjDJ7z7lneQhl8guZpzssU0HIr",
             "Hub1-1537-2016",  "hub1"
             );
    add_hub("00:17:88:4D:97:4D",
             "192.168.11.10",
             "VHQitrMnCUvVb4YLmuTmYQvO54ZjUgihgSJGKTFy",
             "Hub2-1707-2017",   "h2"
             );
    
    hubindex ihub1 = 0;   // the functional one, controls two bulbs
    hubindex ihub2 = 1;   // the newer one, seems to not control any for now
    
    if (false)  {
        hubs[ihub1].get_all_hub_info();
    }
    
    
    // Hardcoded scaffolding, define one bulb for immediate testing
    
    bulbindex icurrentbulb = 0;
    
    
    bool running = true;
    while (running)  {
        if (icurrenthub<9999 && hubs.length>=1 && bulbs.length>=1) {
            writef("H%d %s, B%d %s: phuecmd> ", 
                hubs[icurrenthub].myindex,
                hubs[icurrenthub].shortname,
                bulbs[icurrentbulb].bulbnum,
                bulbs[icurrentbulb].shortname);
        }
        else {
            write("phuecmd> ");
        }
        
        auto cmdline = readln().chomp.strip;
        auto tokens = cmdline.split!isWhite;
        if (cmdline.length==0)  continue;
        
        refresh_bulbs_list();
        
        switch (tokens[0])  {
            
            case "list": 
                    if (tokens.length<2)  {
                        writeln("List what? bulbs hubs palettes ...?");
                    } else {
                        switch (tokens[1]) {
                            case "bulbs": list_all_bulbs(); break;
                            case "hubs":  list_all_hubs();  break;
                            default: continue;
                        }
                    }
                    break;
                    
            case "find":
                    if (tokens.length<2) {
                        writeln("Find what?");
                        continue;
                    }
                    switch (tokens[1]) {
                        case "bulbs":
                            if (!hubs[icurrenthub]) break;
                            hubs[icurrenthub].find_new_physical_bulbs();
                            refresh_bulbs_list();
                            list_all_bulbs();
                            writeln("LISTED KNOWN BULBS");
                            break;
                        case "hubs":
                            goto default;
                        default:
                            { }
                    }
                    break;
            
            case "forget":
                    if (tokens.length<2)  {
                        writeln("Forget what? bulbs, hubs, palette...?");
                        continue;
                    }
                    switch (tokens[1])  {
                        case "all-bulbs":
                                foreach (hub; hubs)  {
                                    hub.forget_all_physical_bulbs();
                                }
                                bulbs.length=0;
                                break;
                        default:
                                continue;
                    }
                    break;
                    
            case "B0":
                    icurrentbulb=0;
                    goto bulb_report;
            case "B1":
                    icurrentbulb=1;
                    bulb_report:
                    writefln("focused on bulb %s num %d", 
                        bulbs[icurrentbulb].shortname, 
                        bulbs[icurrentbulb].bulbnum);
                    break;
                    
            case "hub1":
                    icurrenthub = ihub1;
                    break;
            case "hub2":
                    icurrenthub = ihub2;
                    break;
                    
            case "off":
                    bulbs[icurrentbulb].turn(BulbState.OFF);
                    break;
            case "on":
                    bulbs[icurrentbulb].turn(BulbState.ON);
                    break;
                    
                    
            case "num":
                    animate_color_by_bulbindex();
                    break;
                    
            case "forget-all":
                    hubs[icurrenthub].forget_all_physical_bulbs();
                    break;
                    
            case "create-hardcoded-bulbs":
                    Bulb bulb29 = new Bulb(0, "Bedroom Lamp", "Bedrm", 29);
                    bulb29.descr = "The one with the big shade";
                    Bulb bulb31 = new Bulb(0, "Orange Desklamp", "DeskO", 31);
                    bulb31.descr = "Desk lamp next to guitar amp";
                    break;
                    
            case "quit": 
                    running=false;
                    break;
                    
            case "dim":
                    dim_all_bulbs();
                    break;
                    
            default:
                if (isDigit(tokens[0][0]))  {
                    if (tokens[0].length==1) {
                        int n = tokens[0].to!int;
                        bulbs[icurrentbulb].set_color(color_code_colors[n]);
                    } else {
                        float temp = tokens[0].to!float;
                        if (temp>min_color_temp && temp<max_color_temp) {
                            bulbs[icurrentbulb].set_color(new Color(blackbody(temp)));
                        }else{
                            writefln("Temp %.1f out of range. Must have %.0f < temp < %.0f", 
                                        temp, min_color_temp, max_color_temp);
                        }
                    }
                }else if (tokens[0] in named_color_dictionary) {
                    if (!bulbs.length) continue;
                    bulbs[icurrentbulb].set_color(new Color(named_color_dictionary[tokens[0]]));
                    
                }else{
                    writefln("%s not implement or is gibberish", cmdline);
                }
        }
    }
    
    writeln("BYE!");
    return 0;
}
