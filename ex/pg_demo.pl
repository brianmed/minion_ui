use Mojolicious::Lite;

plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/jobs"};

app->minion->add_task(slow_log => sub {
    my ($job, $msg) = @_;

    Mojo::IOLoop->timer(5 => sub {
        $job->app->log->debug(qq{Received message "$msg"});
    });
});

app->start;
