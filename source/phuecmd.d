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

import phuecolor;
import palette;
import hub;
import bulb;



// formerly all_my_bulbs() 
Bulb[] all_bulbs_of_hub(Hub hub)   { 
    /*TODO*/ // DANGER! Does not check if bulb already in bulbs[]
    Bulb[] bulbs;
    auto spewage = get( hub.myurl ~ "lights/");
    JSONValue lightslist = parseJSON(spewage);
    foreach (string bkey, JSONValue binfo; lightslist)  {
        ushort bnum = bkey.to!ushort;
        JSONValue bulbinfo = lightslist[bkey];
        string bname = format("H%sB%d", hub.name, bnum);
        JSONValue state = bulbinfo["state"];
        Bulb b = new Bulb(hub,  bname, bnum);
        writefln(
           "  + bulb[%d] hub %s, bnum=%d   %s %s   on:%s bri:%s  reachable:%s ", 
                b.myindex,  hub.name,  bnum,
                bulbinfo["modelid"],
                bulbinfo["name"],
                state["on"], state["bri"], state["reachable"]
                );
        bulbs ~= b;
    }
    return bulbs;
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
            if (bulbs[i].num==bulbnum) {
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
            ushort n = to!ushort( (want_bulbnum)? bulbs[ib].num : bulbs[ib].myindex );
            ushort[3] digit;
            digit[2]=n/100;
            ushort r = to!ushort( n-100*digit[2] );
            digit[1]=r/10;
            digit[0]= to!ushort( r-10*digit[1] );
            bulbs[ib].set_color(new Color( color_code_colors[digit[idigit]].cie ) );
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
            writefln("Asking hub %s for its bulbs, before len=%d", hub.name, bulbs.length);
            auto bb =all_bulbs_of_hub(hub); 
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
        if (currentbulb) write(currentbulb.name, " ");
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
        
        // First, check for fixed canned commands
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
                    switch (tokens[1])  {
                        case "on": 
                                system.turn_all_bulbs(BulbState.ON); 
                                break;
                        case "off": 
                                system.turn_all_bulbs(BulbState.OFF); 
                                break;
                        default:
                                //allifier(tokens[1..$]) // loop over bulbs, execute(B#~[1..]) 
                                return false;
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
                              currentbulb.name,
                              currentbulb.num, currentbulb.myhub.name,
                              tokens[1..$]);
                }else{
                    writefln("No bulb of that number");
                    return false;
                }
                return true;
        }

        // Not like "B12", maybe is a bulb's name?
        /*TODO*/  // bulb names defined in Bulb but not really used, only shown (for now)
        
        // No?  Maybe is a color name?
        // current palette ... /*TODO*/
        if (tokens[0].length==1 && isDigit(tokens[0][0]))  {
            if (currentbulb) {
                ubyte n = tokens[0].to!ubyte;
                currentbulb.set_color(color_code_colors[n].cie );

            }
        }
        
        return false;
    }
}


int main(string[] args)  {

    initialize_palettes();
    writefln("Color palettes loaded: %d", palettes.length);
    

    PhueSystem system = new PhueSystem;
    
    // Hardcoded for my actual hardware at this time
    /*TODO*/  // read from config file, or call find_hubs() scanning network
    
    Hub hub1 = new Hub("00:17:88:21:8A:2E",
             "192.168.11.41",
             "78g2lrMNHZHZFozjDJ7z7lneQhl8guZpzssU0HIr",
             "Hub1-1537"
             );
    Hub hub2 = new Hub("00:17:88:4D:97:4D",
             "192.168.11.10",
             "VHQitrMnCUvVb4YLmuTmYQvO54ZjUgihgSJGKTFy",
             "Hub2-1707"
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

