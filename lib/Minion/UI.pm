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

  my $stats = $api->any('/stats')->to('Stats#');
  $stats->get('/minion')->to('#minion')->name('stats_minion');
  $stats->get('/workers')->to('#workers')->name('stats_workers');
  $stats->get('/jobs')->to('#jobs')->name('stats_jobs');

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

