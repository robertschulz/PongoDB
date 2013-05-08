PongoDB
=======

A super lightweight, perl-based rest layer for MongoDB

 MongoDB Rocks. But it comes with a read-only webservice.
 There *is* a decent python-based rest layer for mongo, but it is in nacent stages as well.
 
 The goal here was to have something with virtually zero setup, and an API that very closely models the way mongodb is used on the command line. 
 
 For folks who want to immediately start prototyping ideas against MongoDB,
 here is a very simple rest API for development:
 
    Start the python test-webserver for this dir (localhost:8080):
     ./python_server

    Run the Demo:
    ./restful_mongo.t

    Kill the ./python_server with ctrl-c

This Demo starts a test DB, and populates it with 
the following sample JSON structure:

    {
      a=>[1,2,3],
      b=>{a=>'1',b=>'2',c=>'3'},
      c=>[{a=>1,b=>2,c=>3}, {a=>4,b=>5,c=>6}],
      d=>1,
      e=>'foo'
    }

The demo will then loop you through several example
invocations, showing you the structure both before
and after the change. Hit enter to continue after each.

If this is at all helpful to you, please feel free to improve this prototype.
