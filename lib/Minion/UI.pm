package Minion::UI;

use Mojo::Base 'Mojolicious';

use Minion;

has minion => sub { Minion->new({File => 'minion.db'}) };

sub startup {
  my $app = shift;
  my $r = $app->routes;

  $r->get('/' => {template => 'minion_ui'});

  my $api = $r->under('/api/v1' => sub {
    my $c = shift;
    $c->stash('limit'  => $c->param('limit')  || 100);
    $c->stash('offset' => $c->param('offset') || 0);
    return 1;
  });

  my $stats = $api->any('/stats')->to('Stats#');
  $stats->get('/minion')->to('#minion')->name('stats_minion');
  $stats->get('/workers')->to('#workers')->name('stats_workers');
  $stats->get('/jobs')->to('#jobs')->name('stats_jobs');

  my $job = $api->any('/job')->to('Job#')->name('job');
  $job->post->to('enqueue');
}

1;

