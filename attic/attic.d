
    void get_all_hub_info_SOCKET()   {
        // https://dlang.org/phobos/std_format.html 
        auto url = format("http://%s/api/%s/", 
                        ipaddr, password);
        writeln("URL = ", url);
        const req = [
            "GET / HTTP/1.1",
            "host: " ~ ipaddr ~ ":80",
            "User-Agent: ",
            "Accept: */*",
            "Content-Length: 50" 
            ].join("\r\n");
        //tcpsock.send();
        ubyte[2400] buf;
        //auto stuff = tcpsock.receive(buf);
        //writeln(stuff);
    }
