// PhueSystem combines Bulbs, Hubs, with some useful actions

import std.stdio;
import std.format;
import core.thread;
import phuecolor;
import hub;
import bulb;

alias bulbindex = ushort;  // uniquely identifies bulbs in System
alias hubindex = ushort;   // uniquely identifies hubs


class PhueSystem 
{
    Hub[] hubs;
    Bulb[] bulbs;
    
    this()  {
    }
    
    
    void loadCannedSystemDSW()  {
        Hub hub1 =  new Hub("H1",  "192.168.11.17",  "VHQitrMnCUvVb4YLmuTmYQvO54ZjUgihgSJGKTFy");
        Hub hub2 =  new Hub("H2",  "192.168.11.50",  "78g2lrMNHZHZFozjDJ7z7lneQhl8guZpzssU0HIr");
        hubs ~= hub1;   hub1.index=0;
        hubs ~= hub2;   hub2.index=1;
        
        bulbs ~= new Bulb(hub1, 29, "Lamp1");
        bulbs ~= new Bulb(hub2, 35, "Lamp2");
        bulbs ~= new Bulb(hub2, 36, "Lamp3");
    }
    
    
    void listAll()   {
        foreach (hi,hub; hubs) {
            writefln("hub%d %s %s  %s", hi, hub.name, hub.ipaddr, hub.key);
        }
        foreach (bi, bulb; bulbs)  {
            writefln("B%02d  %s H%dB%d",  bi, bulb.name, bulb.hub.index, bulb.bnum);
        }
    }
    
    
    void set_all_bulbs(BulbState state)  {
        foreach (b; bulbs) 
            b.turn(state);
    }

    void set_all_bulbs(PhueColor color)  {
        foreach (b; bulbs) 
            b.set(color);
    }
    
}
