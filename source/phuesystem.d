// PhueSystem combines Bulbs, Hubs, with some useful actions

import std.stdio;
import std.format;
import std.file : read;
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
    
    
    void loadSystemConfig(string filepath)  {
        auto sysconfig = parseTOML( cast(string)read(filepath) );
        writeln(sysconfig);
    }
    
    
    
    
    void saveSystemConfig(string filepath)   {
        
        try {
            auto config = File(filepath, "w");
            config.writefln("[hubs]");
            foreach (i,h; hubs)   {
                config.writefln("H%d=\"%s\"", i, h.name);
            }
            config.writeln("");
            foreach (h; hubs)   {
                h.write_config(config);
                config.writeln("");
            }
            config.writeln("");
            
            config.writeln("[bulbs]");
            foreach (i, b; bulbs)  {
                config.writefln("B%d=\"%s\"", i, b.name);
            }
            config.writeln("");
            foreach (b; bulbs)  {
                b.write_config(config);
                config.writeln("");
            }
            config.writeln("");
            config.close();
            
        } catch (Exception e)  {
            writeln("Can't write config file ", filepath, ":  ", e.msg);
        }
    }
    
    
    void SaveBulbStates(string filepath)   {
        writeln("Saving color states of bulbs...");
        try {
            auto file = File(filepath, "w");
            file.writefln("[bulb-states]");
            foreach (b; bulbs)   {
                b.update_state_from_reality();
                b.write_state(file);
            }
        } catch (Exception e)  {
            writeln("Can't write bulb state file ", filepath, ":  ", e.msg);
        }
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
