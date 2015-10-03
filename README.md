# Mojolicious::Lite Minion UI

To get started edit this line to suite your needs:

```
plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/jobs"};
```
  
Then run:

```
$ perl minion_ui.pl daemon
```

## Minion View

<img  align="middle" src="http://bmedley.org/minion_ui_minion.png" width="50%" height="50%">

<hr>

## Workers View

<img  align="middle" src="http://bmedley.org/minion_ui_workers.png" width="50%" height="50%">

Released under the same terms as Perl itself.

Copyright (c) 2015 Brian Medley
