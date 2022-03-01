// Palette.d
//
// Sets of colors with names. 
// Defines a default basic colors palette, and a color code palette



import std.string;
import std.stdio;
import std.json;

import phuecolor;


struct NamedColor  {
    CIEColor cie;
    string name;  
}

class Palette  {
    string name;
    NamedColor[] colors;
    
    this(NamedColor[] colordefs, string palette_name)  {
        name = palette_name;
        colors = colordefs;  // want to copy, not just a ref
    }
    
    Color find(string colorname)  {
        return new Color(MAXGREEN);  // dumb place-holder for now
    }
}



Palette[] palettes;


void initialize_palettes()   {
    palettes ~= new Palette(basic_named_colors, "Basic-Colors");
    palettes ~= new Palette(color_code_colors,  "Digit-Color-Code");
}




// Define some handy "obvious" colors, just to have some useful quick
// functionality before dealing with palettes, sequences, good design.
// Note: intent with names is to be case-don't-matter, but
// print out colors as camel case
NamedColor[] basic_named_colors = [
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


NamedColor[10] color_code_colors = [
    { cie:{ 0.10, 0.33, 0.33},  "0"},
    { cie:{ 0.26, 0.54, 0.39},  "1"},
    { cie:{ 0.70, 0.63, 0.32},  "2"},
    { cie:{ 0.87, 0.56, 0.39},  "3"},
    { cie:{ 0.98, 0.48, 0.46},  "4"},
    { cie:{ 0.70, 0.30, 0.48},  "5"},
    { cie:{ 0.61, 0.18, 0.19},  "6"},
    { cie:{ 0.64, 0.22, 0.12},  "7"},
    { cie:{ 0.30, 0.36, 0.36},  "8"},
    { cie:{ 0.98, 0.33, 0.33},  "9"}
];


