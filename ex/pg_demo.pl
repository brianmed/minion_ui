use Mojolicious::Lite;

plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/jobs"};

eval {
    if (-d app->home->rel_dir("log")) {
        plugin(AccessLog => {log => app->home->rel_file("log/access.log"), format => '%h - %u %t "%r" %>s %b %D "%{Referer}i" "%{User-Agent}i"'});
    }
    else {
        plugin(AccessLog => {log => \*STDERR, format => '%h - %u %t "%r" %>s %b %D "%{Referer}i" "%{User-Agent}i"'});
    }
};

app->minion->add_task(slow_log => sub {
    my ($job, $msg) = @_;

    Mojo::IOLoop->timer(5 => sub {
        $job->app->log->debug(qq{Received message "$msg"});
    });
});

app->start;
