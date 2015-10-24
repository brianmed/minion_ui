package Minion::UI::Controller::Job;

use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON 'decode_json';

sub enqueue {
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
}

1;

