// phuecolor.d
//
// Defines basic types, pre-defined named colors, handy functions for dealing with colors

// DESIGN QUESION: Makes sense to have .name in Color?  Keep color names in Palette instead?
// hmmm... 


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
    CIEColor cie; 
    
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

