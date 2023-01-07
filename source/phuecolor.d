/*
 * phuecolor.d
 * Defines Color struct, a few pre-defined named colors, and
 * a few handy functions for adjusting and mixing colors.
 * All Colors are using the CIE (1931) x,y system
 * 
 * (c) Daren Scot Wilson 2022
 */

import std.math;
import std.random;


struct PhueColor  
{
    float bri;     // brightness, 0 to 1,  with 1 = bulb at max brightness ("bri":255)
    float x,y;   // color coords, 0 to 1, confined to "shoe heel" region of CIE chart
}


// A few canned standard colors
// L  is 0.9 or less than 1
immutable PhueColor WHITED50   = { 0.9,  0.3457, 0.3585 };  
immutable PhueColor WHITED65   = { 0.8,  0.3127, 0.3290 };
immutable PhueColor WHITEEQUAL = { 0.8,  0.3333, 0.3333 };
immutable PhueColor ZERO_COLOR  = { 0.0,  0.3333, 0.3333 };
immutable PhueColor PHGAMUT_GREEN   = { 0.8,  0.300,  0.59   };   // green corner of phue gamut
immutable PhueColor PHGAMUT_RED     = { 0.8,  0.64,   0.33   };   // red corner  ''
immutable PhueColor PHGAMUT_BLUE    = { 0.8,  0.145,  0.045  };   // blue-violet corner ''
immutable PhueColor GREEN       = { 0.8, 0.24, 0.40 };
immutable PhueColor YELLOW      = { 0.8, 0.36, 0.45 };   

   
        
PhueColor brighten(PhueColor C, float factor)  {
    PhueColor R = C;
    R.bri *= factor;
    if (R.bri > 1.0)  R.bri = 1.0;
    return R;
}


// Return random real value from 0.0 to 1.0
float randomfloat()  {
    static bool initialized = false;
    static auto rnd = Xorshift32(1);
    if (!initialized) {
        rnd = Xorshift32(unpredictableSeed());
        initialized=true;
    }
    float v = (rnd.front % 0x3FF) / 1024.0f;
    rnd.popFront();
    return v;
}


PhueColor random_color(float minbri=0.0, float maxbri = 1.0)   {
    PhueColor C;
    C.bri = minbri + randomfloat()*(maxbri-minbri);
    // For random x,y, first pick random point in a square
    // If in upper-right diagonal half, flip to lower-left half.
    // Then affine transform to fit Phue gamut in CIE chart, simple vector addition.
    float a = randomfloat();
    float b = randomfloat();
    if (a+b>1.0)  { 
        a=1-a; b=1-b; 
    }
    C.x = PHGAMUT_BLUE.x + (PHGAMUT_RED.x-PHGAMUT_BLUE.x)*a + (PHGAMUT_GREEN.x-PHGAMUT_BLUE.x)*b; 
    C.y = PHGAMUT_BLUE.y + (PHGAMUT_RED.y-PHGAMUT_BLUE.y)*a + (PHGAMUT_GREEN.y-PHGAMUT_BLUE.y)*b; 
    return C;
}



/*
 * Mix two colors.  
 * frac_toward = 0 returns original color.  1.0 returns target.
 * Mixing done linearly in CIE Lxy space.
 */
PhueColor mix(PhueColor orig,  float frac_toward, PhueColor target) {
    float mix = frac_toward;
    float fade = 1.0 - mix;
    PhueColor M;
    M.bri = fade*orig.bri + mix*target.bri;
    M.x = fade*orig.x + mix*target.x;
    M.y = fade*orig.y + mix*target.y;
    return M; 
}


/* 
 * Same as mix but with easing defined by sine function 
 */
PhueColor sine_mix(PhueColor orig,  float frac_toward, PhueColor target)  {
    return mix(orig,  (1 - cos(frac_toward*PI))/2,  target);
}




immutable min_color_temp =  1300.0f; 
immutable max_color_temp = 20000.0f; 


PhueColor blackbody(float temp)   {
	// https://en.wikipedia.org/wiki/Planckian_locus 
    // Brightness should go up with temperature acc'd to Stefan-Boltzmann law
    // but Color.L, proportional to a bulb's "bri", isn't physical. 
    // We make a simple approximation, not letting brightness get too low for the min temp
    
    if (temp < min_color_temp) temp = min_color_temp;
    if (temp > max_color_temp) temp = max_color_temp;
    
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
    float b = 1.0 + 1000.0/max_color_temp - m;
	return PhueColor(1.0, x, y);
}


bool isclose(float x, float y, float tol=0.002) {
    return fabs(x-y) < tol;
}



unittest {
    import std.stdio;
    
    writefln("%6.3f %6.3f %6.3f %6.3f ", randomfloat(), randomfloat(), randomfloat(), randomfloat() );
    
    PhueColor A = { 0.2, 0.2, 0.6 };
    PhueColor B = { 1.0, 0.6, 0.8 };
    
    PhueColor mixA = mix(A, 0.0, B);
    assert( isclose(mixA.bri, A.bri) );
    assert( isclose(mixA.x, A.x) );
    assert( isclose(mixA.y, A.y) );
    
    PhueColor mixB = mix(A, 1.0, B);
    assert( isclose(mixB.bri, B.bri) );
    assert( isclose(mixB.x, B.x) );
    assert( isclose(mixB.y, B.y) );
    
    PhueColor half = mix(A, 0.5, B);
    assert( isclose(half.bri, 0.6) );
    assert( isclose(half.x, 0.4) );
    assert( isclose(half.y, 0.7) );
    
    PhueColor cool = blackbody(2000);
    assert( isclose(cool.x, 0.525, 0.007) );  // looking at diagram by eye
    assert( isclose(cool.y, 0.415, 0.007) );
}
