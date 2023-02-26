import std.stdio;
import std.conv;
import std.algorithm;
import std.datetime;



std.datetime.date.TimeOfDay tod(string arg)   {
    auto parts = arg.findSplit(":");
    if (parts[1].length==0) {
        throw new DateTimeException("no : in time of day");
    }
    int h = to!int(parts[0]);
    int m, s;
    auto x = parts[2].findSplit(":");
    try {
        if (x[2].length>0)  {
            m = to!int(x[0]);
            s = to!int(x[2]);
        } else {
            m = to!int(x[0]);
            s = 0;
        }
    } catch (Exception) {
        throw new std.datetime.date.DateTimeException("Can't parse mm:ss");
    }
    return std.datetime.date.TimeOfDay(h, m, s);
}

