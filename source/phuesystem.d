// PhueSystem combines Bulbs, Hubs, with some useful actions

import std.stdio;
import std.format;
import std.conv;
import std.string;
import std.ascii : isDigit, toUpper;
import std.file : read;
import std.algorithm;
import core.thread;
import phuecolor;
import hub;
import bulb;
import std.json;
import toml;


alias bulbindex = ushort;  // uniquely identifies bulbs in System
alias hubindex = ushort;   // uniquely identifies hubs


class PhueSystem 
{
    Hub[] hubs;
    Bulb[] bulbs;
    
    this()  {
    }
    
    
    /**
     * remove all Hubs, Bulbs.
     * Probably better to just create a new PhueSystem, but forget() is handy 
     * for certain tests.
     */
    void forget_all()   {
        bulbs.length = 0;
        hubs.length = 0;
    }
    
    
    
    // Finds a hub by name, index in hubs array, ip addr, or MAC (or ...?)
    //   "H2"  is hubs[2]   (Remember 0-based indexing)
    //   "UpperFloorHub"  is a Hub.name 
    //   ".32"   is final byte of ip address  (may give full address)
    //   "mac:00:17:88:01:02:64:9a:8b"   is mac  NOT IMPLEMENTED YET
    // Return null if no match found.  
    // Multiple matches ignored - only first match returned.
    
    
    Hub find_hub(string name)   {
        if (name.length>=2 && name[0]=='H' && name[1].isDigit )  {
            writefln("%s appears to be a system hub list index", name);
            hubindex hi;
            try {
                writefln("Parsing index \"%s\"", name[1 .. $]);
                hi = to!ushort( to!int(name[1 .. $]) );
                writefln(" [%d] ", hi);
            }catch (Exception e) {
                writefln("Couldn't parse hub identifier %s", name);
                return null;
            }
            if (0 <= hi  &&  hi < hubs.length)   
                return hubs[hi];
            else  {
                writefln("Hub system index % is out of range 0 .. %d", hi, hubs.length);
                return null;
            }
        }
        if (name.length>=2  && name[0]=='.')  {
            writefln("%s appears to be an IP address (or tail)", name);
            foreach (h; hubs) {
                if (h.ipaddr.endsWith(name))
                    return h;
            } 
        }
        else {
            foreach (h; hubs)  {
                if (h.name==name) return h;
            }
        }
        return null;
    }


    // Find any bulb in system by name, system index, hub's id, ...
    //   "B[13]"  is the bulb kept in system's list at bulbs[13]
    //   "Lamp3"   is the bulb given the name "Lamp3"
    //   "H2B34"   is bulb known as 34 to Hub kept at hubs[2] (square brackets optional)
    //   "UpperFloorHub.B34"   same thing but using Hub's .name (must have .)
    //
    // Note that "B13" has 13 as the index into full system array, while
    // "H2B34" takes 34 to be the hub's number for a bulb.
    //
    // Returns null if no matching bulb found.
    Bulb find_bulb(string name)   {
        if (name.length>=4  && toUpper(name[0])=='B' && name[1]=='[' && name[2].isDigit() )   {
            writefln("Appears to be a bulb with system list index ");
            bulbindex ibulb;
            try {
                long iclose = indexOf(name, ']');
                ibulb = to!ushort(name[2 .. iclose]);
            }catch(Exception e){
                writefln("Couldn't parse \"%s\" - %s", name, e.msg);
            }
            if (0 <= ibulb  &&  ibulb < bulbs.length)  
                return bulbs[ibulb];
            else  {
                writefln("System bulb index %d isn't in range 0 to %d", ibulb, bulbs.length-1);
                return null;
            }
        }
        else if (name.length >= 4 &&  toUpper(name[0])=='H' && name[1].isDigit() )   {
            auto iB = indexOf(name, "B");
            if (iB<2) return null;
            hubindex ihub = to!ushort(name[1 .. iB]);
            bulbindex bnum = to!ushort(name[iB+1 .. $]);
            writefln("hub i=%d from \"%s\", bnum=%d from \"%s\"", ihub, name[1 .. iB], bnum, name[iB+1 .. $]);
            if (0 <= ihub  &&  ihub < hubs.length)   {
                foreach (b; bulbs) {
                    if (b.bnum==bnum && b.hub.index==ihub) return b;
                }
                writefln("Bulb number %d not found for hub [%d] %s", bnum, ihub, hubs[ihub].name);
                return null;
            }
            else  {
                writefln("ihub=%d not in range 0 to %d", ihub, hubs.length);
                return null;
            }
        }
        
        else {
            foreach (b; bulbs) {
                if (b.name==name) return b;
            }
        }
        
        return null;
    }

    void loadCannedSystemDSW()  {
        Hub hub1 =  new Hub("Hub1",  "192.168.11.17",  "VHQitrMnCUvVb4YLmuTmYQvO54ZjUgihgSJGKTFy");
        Hub hub2 =  new Hub("Hub2",  "192.168.11.50",  "78g2lrMNHZHZFozjDJ7z7lneQhl8guZpzssU0HIr");
        hubs ~= hub1;   hub1.index=0;
        hubs ~= hub2;   hub2.index=1;
        
        bulbs ~= new Bulb(hub1, 29, "Lamp1");
        bulbs ~= new Bulb(hub2, 35, "Lamp2");
        bulbs ~= new Bulb(hub2, 36, "Lamp3");
    }
    
    
    void loadSystemConfig(string filepath)  {
        writeln("Reading config ", filepath);
        
        string toml = "";
        try {
            toml = cast(string)read(filepath) ;
        } catch (Exception e)  {
            writeln("Couldn't open config file ", filepath, ":  ", e.msg);
            return;
        } 
        
        
        TOMLDocument sysconfig;
        try {
            sysconfig = parseTOML( toml, TOMLOptions.unquotedStrings );
           // writeln(sysconfig, " ");
        } catch (Exception e)  {
            writeln("Couldn't parse config file ", filepath, ":  ", e.msg);
        }            
        
        //writeln("hubs: ", sysconfig["Hub"]);
        
        foreach (k, hubinfo; sysconfig["Hub"])   {
            //writeln("hub  " , k, "  ", hubinfo);
            Hub newhub = new Hub(k, hubinfo["ipaddr"].str, hubinfo["key"].str);
            hubs ~= newhub;
            newhub.index = to!int(hubs.length-1);
        }

        foreach (k, bulbinfo; sysconfig["Bulb"])   {
            //writeln("bulb  " , k, "  ", bulbinfo);
            string hubname = bulbinfo["hubname"].str;
            //Hub h = hubs.find!( (a,b) => a.name == b )(hubname);
            //Hub h = hubs.find!( (x) => x.name == hubname );
            Hub h = find_hub(hubname);
            string bulbname = bulbinfo["name"].str;
            bulbindex i = cast(bulbindex)bulbinfo["idh"].integer;
            //writeln("bulb ", bulbname, i, " for hub ", hubname);
            if (h)   {
                Bulb newbulb = new Bulb(h, i, bulbname);
                newbulb.update_state_from_reality();
                bulbs ~= newbulb;
            }
            else {
                writefln("Bulb %s in config file uses unknown hub %s", bulbname, hubname);
            }
        }

        writefln("Phue system loaded: %d hubs, %d bulbs ----", hubs.length, bulbs.length);
    }
    
    
    
    void saveSystemConfig(string filepath)   {
        
        try {
            auto config = File(filepath, "w");
            
            foreach (h; hubs)   {
                h.write_config(config);
                config.writeln("");
            }
            config.writeln("");
            
            foreach (b; bulbs)  {
                b.write_config(config);
                config.writeln("");
            }
            config.close();
            
        } catch (Exception e)  {
            writeln("Can't write config file ", filepath, ":  ", e.msg);
        }
    }
    
    
    void SaveBulbStates(string filepath)   {
        writeln("Saving color states of bulbs...");
        try {
            auto file = File(filepath, "w");
            foreach (b; bulbs)   {
                b.update_state_from_reality();
                b.write_state(file);
            }
        } catch (Exception e)  {
            writeln("Can't write bulb state file ", filepath, ":  ", e.msg);
        }
    }
    
    
    
    
    void update_bulb_states_from_reality()   {
        foreach (ref b; bulbs)   {
            b.update_state_from_reality();
        }
    }

    
    void listAll()   {
        foreach (hi, ref hub; hubs) {
            writef("H[%d] ", hi);
            hub.describe_self();
        }
        foreach (bi, ref bulb; bulbs)  {
            writef("B[%2d] ", bi);
            bulb.describe_self(); 
        }
    }
    

    void set_all_bulbs(BulbState state)  {
        foreach (ref b; bulbs) 
            b.turn(state);
    }


    void set_all_bulbs(PhueColor color)  {
        foreach (ref b; bulbs) 
            b.set(color);
    }
    
}
