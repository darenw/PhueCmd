/*
 * Hub:  object for interfacing with a Philips Hue hub
 */
 
 
import std.stdio;
import std.string;
import std.format;
import std.json;
import std.net.curl;

alias bulbnumber = uint;



class Hub  
{
    int index;
    string key;
    string ipaddr;
    string macaddr;
    string name; 
    string myurl;   // for convenience, "http://192.168.1.2/api/<key>/" pre-computed
    
    
    this(string _name, string _ipaddr, string _key)   {
        key = _key;
        ipaddr = _ipaddr;
        name = _name;
        index = -1; // undefined for now
        myurl = format("http://%s/api/%s/", ipaddr, key);
    }
    
    
    void write_config(ref File config)  {
        config.writefln("[hub.%s]",  name);
        config.writefln("name=\"%s\"", name);  
        config.writefln("ipaddr=\"%s\"", ipaddr);
        config.writefln("key=\"%s\"", key);
        if (macaddr.length>4) {
            config.writefln("mac=\"%s\"",  macaddr);
        }
    }
    
    
    void setbulbstate(bulbnumber bulbnum, string json)   {
        string api = format("lights/%d/state", bulbnum);
        put(myurl ~ api, json);
    }
    
    JSONValue get_bulb_json_info(bulbnumber bulbnum)  {
        auto reply = get(myurl ~ format("lights/%d", bulbnum));
        return parseJSON(reply);
    }  
}






