// PhueCmd  main
// THIS INITIAL WRITING: hackwork! hardcoded, classes not put into own files, messy, etc


import std.stdio;
import std.string;
import std.format;

import std.ascii; 
//import std.uni;
//https://forum.dlang.org/post/dfpyivbwueemnyadknco@forum.dlang.org

import std.conv;
import std.math;
import std.algorithm.searching;
import std.algorithm.comparison;
import std.json;
import std.net.curl;
//import std.thread;
import core.thread;



alias bulbnumber = ushort;    // number of bulb known hub
alias bulbindex = ushort;     // unique id number within a multi-hub system
alias groupindex = ushort;    // 
alias paletteindex = ushort;





class Hub  {
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
    }
    
    ~this() {
    }
    
    void describe_self_one_line()   {
        writefln("hub %s  %s  %s (%s)", 
               ipaddr,  macaddr, name, shortname);
    }
    
    
    void send_bulb_settings(bulbnumber bulbnum, JSONValue cmd)  {
        string b = format("lights/%d/state", bulbnum);
writefln("Hub:sending(json) to bnum=%d <<%s>>((%s))", bulbnum, b, cmd);
        put(myurl ~ b, cmd.toString);
        
    }

    void send_bulb_settings(bulbnumber bulbnum, string jsoncmd)  {
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
            writef("deleting bulb num %s from hub %s (%s)... ", bnum, shortname, ipaddr);
            del( myurl ~ "lights/" ~ bkey);
            writefln("gone!");
        }

    }

    
    Bulb[] all_my_bulbs()   {
        /*TODO*/ // DANGER! Does not check if bulb already in bulbs[]
        Bulb[] mybulbs;
        auto spewage = get( myurl ~ "lights/");
        JSONValue lightslist = parseJSON(spewage);
        foreach (string bkey, JSONValue binfo; lightslist)  {
            ushort bnum = bkey.to!ushort;
            JSONValue bulbinfo = lightslist[bkey];
            string boringname = format("H%sB%d", shortname, bnum);
            string longername = format("Hub %s-Bulb%d", name, bnum);
            JSONValue state = bulbinfo["state"];
            Bulb b = new Bulb(this, longername, boringname, bnum);
            writefln("  + bulb[%d] hub %s, bnum=%d   %s %s   on:%s bri:%s  reachable:%s ", 
                    b.myindex,  shortname,  bnum,
                    bulbinfo["modelid"],
                    bulbinfo["name"],
                    state["on"], state["bri"], state["reachable"]
                    );
            mybulbs ~= b;
        }
        return mybulbs;
    }
}



enum BulbState { OFF, ON }

class Bulb {
    bulbindex myindex;
    Hub myhub;
    string name, shortname, descr;
    ushort bulbnum;        // number assigned by hub
    CIEColor latest_color;
    HSVColor latest_color_hsv;
    float    latest_color_temp;
    BulbState     latest_onoff_state;
    
    this(Hub hub, string name0, string shortname0, ushort bulbnum0) {
        /*TODO*/ // check if any existing bulb has same bulbnum
        myhub = hub;
        name=name0;
        shortname=shortname0;
        bulbnum = bulbnum0;
    }
    
    void describe_self_one_line()   {
        writefln("bulb[%d] hub[%s] bnum=%d   %s %s", 
            myindex, myhub.shortname, bulbnum, shortname, descr);
    }
    
    
    void turn(BulbState desired)   {
        writefln("Bulb.turn(%d)   msg=%s", desired,  (desired==BulbState.ON)? "{\"on\":true}" : "{\"on\":false}" );
        send( (desired==BulbState.ON)? "{\"on\":true}" : "{\"on\":false}" );
        // if successful, 
            latest_onoff_state = desired;
    }
    
    
    void send(string jsoncmd)  {
    writefln("Bulb[bnum=%d,i=%d].SEND(str) %s  myhub.name=%s", bulbnum, myindex, jsoncmd,myhub.shortname);
        myhub.send_bulb_settings(bulbnum, jsoncmd);
    }

    void send(JSONValue cmd)  {
    writefln("Bulb[bnum=%d,i=%d].SEND(json) %s myhub:name=%s", bulbnum, myindex, cmd,myhub.shortname);
        myhub.send_bulb_settings(bulbnum, cmd);
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


class Group    {
    
    bulbindex[] members;
    string name;
    
    void eat(bulbindex ibulb)  {
        // can a bulb belong to more than one group? yes.
        // example: 
        //       all bulbs on top of bookshelf, 
        //       all bulbs along north wall, 
        //       all bulbs in corner of room
        // A bulb in the northwest corner is in two groups.
        // A bulb on the bookshelf along the north wall is in two groups
        
        if (canFind(members, ibulb)) 
                return;
        members.length++;
        members[$-1] = ibulb;
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
    { cie:{0.17, 0.556, 0.410},   name:"brown"},
    { cie:{0.75, 0.280, 0.451},   name:"green"},
    { cie:{0.76, 0.205, 0.185},   name:"blue"},
    { cie:{0.50, 0.221, 0.115},   name:"violet"},
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
    /* 6 */  { 0.61, 0.18, 0.19},
    /* 7 */  { 0.64, 0.22, 0.12},
    /* 8 */  { 0.30, 0.36, 0.36},
    /* 9 */  { 0.98, 0.33, 0.33},
];




class Sequence  {
    struct Point {
        CIEColor color;
        float tstart;  // seconds, rel to sequence start
        float duration;
    }
    Point[] points;
}



class PhueSystem  {
    
    Bulb[] bulbs;
    Hub[] hubs;
    Group[] groups;
    Sequence[] seqs;
    
    this() {
        writeln(" inside SYS Construct  ");
    }
    
    void add(Hub h) {
        hubs ~= h;        
        writefln("+ Hub[%d]  %s  %s  %s ", 
                   hubs.length-1,  
                   h.ipaddr, h.macaddr, h.name);
    }
    
    
    Bulb get_bulb_by_bulbnum(int bulbnum)  {
        // DO NOT USE except as development scaffolding. 
        // Can't handle different hubs with bulbs of same bulb number.
        bulbindex i = 0;
        while (i < bulbs.length) {
            if (bulbs[i].bulbnum==bulbnum) {
                return bulbs[i];
            }
        }
        return null;
    }
    
    void turn_all_bulbs(BulbState desired)  {
        writefln("TURN ALL %d" ,desired);
        foreach (Bulb b; bulbs)  {
            b.turn(desired);
        }
    }

    void dim_all_bulbs() {
        set_color_all_bulbs(new Color(ZEROBRIGHT));
    }

    void set_color_all_bulbs(Color c) {
        foreach (Bulb b; bulbs)  {
            b.set_color(c);
        }
    }
    

    void list_all_bulbs()    {
        writefln("PhuSystme.list_all_bulbs() ENTER  len(bubls[])=%d", bulbs.length);
        foreach (Bulb bulb; bulbs)  {
            bulb.describe_self_one_line();
        }
    }
    
    void colorize_bulbs_by_digit(int idigit, bool want_bulbnum)  {
        Thread.sleep( dur!("msecs")( 300 ) );    
        writefln("COLORIZE digit %d, bulbs.len=%d", idigit, bulbs.length);
        dim_all_bulbs();
        for (bulbindex ib=0; ib<bulbs.length; ib++)  {
            ushort n = to!ushort( (want_bulbnum)? bulbs[ib].bulbnum : bulbs[ib].myindex );
            ushort[3] digit;
            digit[2]=n/100;
            ushort r = to!ushort( n-100*digit[2] );
            digit[1]=r/10;
            digit[0]= to!ushort( r-10*digit[1] );
            bulbs[ib].set_color(new Color(color_code_colors[digit[idigit]]));
        }
        Thread.sleep( dur!("msecs")( 900 ) );
    }

    void animate_color_code(bool want_bulbnum)   {
        colorize_bulbs_by_digit(2,want_bulbnum);
        colorize_bulbs_by_digit(1,want_bulbnum);
        colorize_bulbs_by_digit(0,want_bulbnum);
        for (bulbindex ib=0; ib<bulbs.length; ib++)  {
            bulbs[ib].set_color(new Color(ZEROBRIGHT));
        }
    }


    void rebuild_bulbs_list() {
        bulbs.length=0;
        foreach (hub; hubs)  {
            writefln("Asking hub %s for its bulbs, before len=%d", hub.shortname, bulbs.length);
            auto bb =hub.all_my_bulbs(); 
            bulbs ~= bb;
            writefln("bulbs.len=%d  given %s", bulbs.length, bb );
        }
        for (bulbindex i=0; i<bulbs.length; i++)  
                bulbs[i].myindex=i;
    }


    void list_all_hubs()  {
        foreach (Hub hub; hubs)  {
            hub.describe_self_one_line();
        }
    }

    Bulb find_bulb_by_index(bulbindex i)  {
        if (i>=bulbs.length) return null;
        return bulbs[i];
    }
    
    
    Hub find_hub_by_name(string name) {
        string n = toLower(name);
        foreach (hub; hubs)  {
            if (toLower(hub.name)==n) return hub;
            if (toLower(hub.shortname)==n) return hub;
        } 
        return null;
    }
    
    void find_new_physical_bulbs(string recipient_hub_name)  {
        // hub_name may be short name or long name
        Hub the_chosen_one = find_hub_by_name(recipient_hub_name);
        if (!the_chosen_one){
            writefln("No hub named %s.  Bulb search cancelled.", recipient_hub_name);
            return;
        }
         the_chosen_one.find_new_physical_bulbs();
        /*TODO*/ // don't rebuild whole list, but add just new ones
        // for now, take the easy way.  
        rebuild_bulbs_list();
        list_all_bulbs();
        writeln("LISTED KNOWN BULBS");    
    }

}


class Commander {
    PhueSystem system;        // 
    Bulb currentbulb;
    ushort current_group;
    ushort current_other_thing;  // etc...   bad idea?
    // class ControllableThing -> Bulb, Group, Sequence, Show etc
    // commands -> Controllable.exec(cmd)    ??

    
    this(PhueSystem s) {
        system = s;
    }
    
    immutable string prompt_colorizer = "\033[38;2;122;188;208m";
    immutable string contexts_colorizer = "\033[38;2;252;188;78m";
    immutable string normal_colorizer = "\033[0m";
    
    void prompt()  {
        write(contexts_colorizer);
        if (currentbulb) write(currentbulb.shortname, " ");
        writef("%sphuecmd> %s", prompt_colorizer, normal_colorizer);
    }
    
    
    void list_stuff(string what)  {
        switch (toLower(what))  {
            case "bulb": case "bulbs":
                    writefln("TO list-all-bulbs() system=%s", system);
                    system.list_all_bulbs();
                    break;
            case "hub": case "hubs":
                    system.list_all_hubs();
                    break;
            default:
                break;
        }
    }
    
    
    bool execute(string cmdline)  {
        auto tokens = cmdline.split!isWhite;
        if (tokens.length==0)  return false;
        string cmd = toLower(tokens[0]);
        switch (cmd) {
            case ".":  
                    currentbulb=null;
                    return true;
                    
            case "list":
                    if (tokens.length<2)
                        list_stuff("bulbs");
                    else
                        list_stuff(tokens[1]);
                    return true;
                    
            case "all":
                    writefln(" -- ALL -- ");
                    if (tokens.length==1) {
                        currentbulb = null;   // indicates next on/off/color is for all bulbs
                    } else {
                        switch (tokens[1])  {
                            case "on": 
                                    system.turn_all_bulbs(BulbState.ON); 
                                    break;
                            case "off": 
                                    system.turn_all_bulbs(BulbState.OFF); 
                                    break;
                            default:
                                    return false;
                        }
                    }
                    return true;
                    
            case "num":
                    system.animate_color_code(true);
                    return true;
                    
            case "index":
                    system.animate_color_code(false);
                    return true;
                    
            default: 
                    break;
        }

        // No direct match? Maybe command is index or name of bulb?
        if ((cmd[0]=='B' || cmd[0]=='b') && cmd.length>0 && isDigit(cmd[1]))  {
                string therest = cmd[1..$];
                writefln("The Rest = <<%s>> ", therest);
                bulbindex i = therest.to!bulbindex;
                writefln("   i=%d", i);
                currentbulb = system.find_bulb_by_index(i);
                if (currentbulb)  {
                writefln("Current bulb: cmd= %s for bulbi %d=%d %s b%d-%s actions=%s", 
                              cmd, 
                              currentbulb.myindex, i, 
                              currentbulb.shortname,
                              currentbulb.bulbnum, currentbulb.myhub.shortname,
                              tokens[1..$]);
                }else{
                    writefln("No bulb of that number");
                    return false;
                }
                return true;
        }

        // Not like "B12", maybe is a bulb's name?
        
        // No?  Maybe is a color name?
        //ColorPalette currentpal = null;
        
        return false;
    }
}


int main(string[] args)  {
    init_named_colors();    
    PhueSystem system = new PhueSystem;
    
    // Hardcoded for my actual hardware at this time
    /*TODO*/  // read from config file, or call find_hubs() scanning network
    Hub hub1 = new Hub("00:17:88:21:8A:2E",
             "192.168.11.41",
             "78g2lrMNHZHZFozjDJ7z7lneQhl8guZpzssU0HIr",
             "Hub1-1537-2016",  "hub1"
             );
    Hub hub2 = new Hub("00:17:88:4D:97:4D",
             "192.168.11.10",
             "VHQitrMnCUvVb4YLmuTmYQvO54ZjUgihgSJGKTFy",
             "Hub2-1707-2017",   "hub2"
             );

    system.add(hub1);
    system.add(hub2);
    system.rebuild_bulbs_list();
    
    Commander commander = new Commander(system);
    
    bool running = true;
    while (running)  {
        commander.prompt();
        auto cmdline = readln().chomp.strip;
        if (cmdline=="quit") {
            running=false;
        } else {
            commander.execute(cmdline);
        }
    }
    
    writeln("BYE!");
    return 0;
}

