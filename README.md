Riak Redis Backend
==================

Installing
----------

You need :

 - [credis](http://code.google.com/p/credis/). compile (`make`)

 - [erlang_credis](http://github.com/videlalvaro/erlang_credis). compile (`make`)
 
 You have to specify the path to your credis installation.

 - [Redis](http://code.google.com/p/redis/) (Any version will do). 

 - [Riak](http://riak.basho.com/)

 - compile (`erlc riak_redis_backend.erl`)

Configure riak :

In `etc/app.config` change the option storage_backend to:

  `{storage_backend, riak_redis_backend}`
  
And add the paths to the driver and the backedn so riak can find them:

  '{add_paths, ["/path/to/riak_redis_backend", "/path/to/erlang_credis/ebin"]}'

For the time being, Redis must run locally. I will certainly add the line to configure the redis host and port.

Other files
-----------

 * `riak_redis_prof` : runs the Riak `standard_backend_test`.

 * `riak_playground` : runs an insert test and 2 map-reduce tasks and give timing information.s

License
---------

Apache 2 license.

Author
--------
Eric Cestari 

[http://www.cestari.info/](http://www.cestari.info/)

ecestari+riak-backend@mac.com


Port to CREDIS Driver
---------------------
Alvaro Videla

[http://obvioushints.blogspot.com/](http://obvioushints.blogspot.com/)