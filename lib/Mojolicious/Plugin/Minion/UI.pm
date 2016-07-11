package Mojolicious::Plugin::Minion::UI;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Server;

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';

use Carp;

sub register {
  my ($plugin, $app, $opts) = @_;
  my $path = $opts->{path} or croak 'A "path" argument is required';

  my $minion = eval { $app->minion } || croak 'App does not have a minion attached';
  my $ui = Mojo::Server->new->build_app('Minion::UI')->minion($minion);

  my $base = catdir dirname(__FILE__), 'MinionUIAssets';
  push @{$ui->renderer->paths}, catdir($base, 'templates');
  push @{$ui->static->paths},   catdir($base, 'public');

  $app->routes->route($path)->detour(app => $ui);
}

1;
