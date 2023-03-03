// anykey.d
// Spin off a thread to watch for "any key" except it really works only for Enter key
// Doesn't quite provide a is_any_key_pressed() function,
// but sorta works if it's a good day.

import std.stdio;
import std.concurrency;
//import core.stdc.stdio;    // for getchar()



shared bool bkeypressed = false;


static
void key_watcher_proc()  {
    readln;
    bkeypressed=true;
}




void launch_key_checker()   {
    bkeypressed=false;
    //auto thr = new Thread(&key_watcher_proc).start();
    auto x = spawn(&key_watcher_proc);
}



bool is_key_pressed()  {
    return bkeypressed;
}


