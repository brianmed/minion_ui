# Mojolicious::Lite Minion UI

To get started edit this line to suite your needs:

```
plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/jobs"};
```
  
Then run:

```
$ perl minion_ui.pl daemon
```
