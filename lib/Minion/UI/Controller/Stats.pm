package Minion::UI::Controller::Stats;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON 'encode_json';

sub minion {
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
}

sub workers {
  my $c = shift;

  my $stats = $c->app->minion->backend->list_workers(@{$c->stash}{qw/offset limit/});

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
}

sub jobs {
  my $c = shift;

  my $options = {
    state => $c->param('state'),
    task  => $c->param('task'),
  };
  my $stats = $c->app->minion->backend->list_jobs(@{$c->stash}{qw/offset limit/}, $options);

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
}

1;

