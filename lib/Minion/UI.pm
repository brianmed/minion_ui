package Minion::UI;

use Mojo::Base 'Mojolicious';

use Mojo::JSON qw(encode_json decode_json);

use Minion;

has minion => sub { Minion->new({File => 'minion.db'}) };

sub startup {
  my $app = shift;
  my $r = $app->routes;

  $r->get('/' => {template => 'minion_ui'});

  my $api = $r->any('/api/v1');
  my $stats = $api->any('/stats');

  $stats->get('/minion')->name('stats_minion')->to(cb => sub {
    my $c = shift;

    my $stats = $c->app->minion->stats;

    my $ret = {
      inactive_workers => $stats->{inactive_workers},
      active_workers => $stats->{active_workers},
      active_jobs => int($stats->{active_jobs}),
      failed_jobs => int($stats->{failed_jobs}),
      finished_jobs => int($stats->{finished_jobs}),
      epoch => time,
    };

    $c->render(json => $ret);
  });

  $stats->get('/workers')->name('stats_workers')->to(cb => sub {
    my $c = shift;

    my $stats = $c->app->minion->backend->list_workers(@_);

    # $c->app->log->debug($c->dumper($stats));

    my $ret = [];

    foreach my $worker (@{ $stats }) {
      push(@{ $ret }, {
        id => $worker->{id},
        host => $worker->{host},
        pid => $worker->{pid},
      });
    }

    $c->render(json => $ret);
  });

  $stats->get('/jobs')->name('stats_jobs')->to(cb => sub {
    my $c = shift;

    my $stats = $c->app->minion->backend->list_jobs(@_);

    # $c->app->log->debug($c->dumper($stats));

    my $ret = [];

    foreach my $job (@{ $stats }) {
      push(@{ $ret }, {
        args => encode_json($job->{args}),
        id => $job->{id},
        priority => $job->{priority},
        state => $job->{state},
        task => $job->{task},
        queue => $job->{queue},
      });

      last if 30 <= @{ $ret };
    }

    $c->render(json => $ret);
  });

  my $job = $api->any('/job')->name('job');
  $job->post->to(cb => sub {
    my $c = shift;

    my $task = $c->param("task");
    my $queue = $c->param("queue");
    my $priority = $c->param("priority");
    my $delay = $c->param("delay");
    my $args = decode_json($c->param("args") || "[]");

    my $options = {};

    $options->{priority} = $priority if $priority;
    $options->{delay} = $delay if $delay;
    $options->{queue} = $queue if $queue;

    my $job_id = $c->app->minion->enqueue($task, $args, $options);

    $c->render(json => {job_id => $job_id});
  });

}

1;

