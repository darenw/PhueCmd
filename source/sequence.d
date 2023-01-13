

import std.stdio;
import std.math;
import phuecolor;
import bulb;
import phuesystem;




struct LightPoint  
{
    float t;      // seconds relative to start of seq
    PhueColor color;
    BulbState state;   
}


class Track
{
    string trackname;
    LightPoint[]  points;
}


class Sequence 
{
    Track[] tracks;
    
    this()  {
    }
}


class Assignment 
{
    // list of bulbs by name (add cached indexes) that go with each Track
}


void play(Sequence sequence, Assignment assignment)   {
    
}


