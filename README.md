# Minion UI

To get started put lib/ in your perl lib path somehow.

```
use Mojolicious::Lite;
...
plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/jobs"};
...
app->start;
```
  
and visit the designated path or simply run the ui command

```
$ ./myapp.pl minion ui
```

which takes the same arguments as the `daemon` command.

## Dashboard

<img align="middle" src="http://bmedley.org/adhoc/2017-01-23/minion_ui-2017-01-23.png" width="50%" height="50%">


Released under the same terms as Perl itself.

Copyright (c) 2016 Joel Berger and Brian Medley
