// PhueSystem combines Bulbs, Hubs, with some useful actions

import std.stdio;
import std.format;
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
    
    
    
    Hub find_hub_by_name(string name)  {
        foreach (h; hubs) {
            if (h.name==name) return h;
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
            writeln(sysconfig, " ");
        } catch (Exception e)  {
            writeln("Couldn't parse config file ", filepath, ":  ", e.msg);
        }            
        
        writeln("hubs: ", sysconfig["Hub"]);
        
        foreach (k, hubinfo; sysconfig["Hub"])   {
            writeln("hub  " , k, "  ", hubinfo);
            hubs ~= new Hub(k, hubinfo["ipaddr"].str, hubinfo["key"].str);
        }

        foreach (k, bulbinfo; sysconfig["Bulb"])   {
            writeln("bulb  " , k, "  ", bulbinfo);
            string hubname = bulbinfo["hubname"].str;
            //Hub h = hubs.find!( (a,b) => a.name == b )(hubname);
            //Hub h = hubs.find!( (x) => x.name == hubname );
            Hub h = find_hub_by_name(hubname);
            string bulbname = bulbinfo["name"].str;
            bulbindex i = cast(bulbindex)bulbinfo["idh"].integer;
            writeln("bulb ", bulbname, i, " for hub ", hubname);
            if (h)   {
                Bulb newbulb = new Bulb(h, i, bulbname);
                newbulb.update_state_from_reality();
                bulbs ~= newbulb;
            }
            else {
                writefln("Bulb %s in config file uses unknown hub %s", bulbname, hubname);
            }
        }

        writeln("HUBS AFTER APPEND: ", hubs);
        writeln("========== Phue system loaded: #d hubs, %d bulbs =======", hubs.length, bulbs.length);
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
            writefln("hub%d %s %s  %s", hi, hub.name, hub.ipaddr, hub.key);
        }
        foreach (bi, ref bulb; bulbs)  {
            writefln("B%02d  %s H%dB%d %s %s (gamut %s)",  bi, bulb.name, bulb.hub.index, 
                bulb.bnum, 
                bulb.current_color,
                bulb.model,
                bulb.gamut);
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
