#!/usr/bin/env perl

use Mojolicious::Lite;

plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/jobs"};

get '/' => sub {
    my $c = shift;

    $c->render(template => 'slash');
};

get '/v1/minion/stats' => sub {
    my $c = shift;

    my $stats = $c->app->minion->stats;
    my $ret = [ 
        { text => "Inactive Workers", value => $stats->{inactive_workers} },
        { text => "Active Workers", value => $stats->{active_workers} },
        { text => "Inactive Jobs", value => $stats->{inactive_jobs} },
        { text => "Active Jobs", value => $stats->{active_jobs} },
        { text => "Failed Jobs", value => $stats->{failed_jobs} },
        { text => "Finished Jobs", value => $stats->{finished_jobs} },
    ];

    $c->render(json => $ret);
};

get '/v1/worker/stats' => sub {
    my $c = shift;

    my $stats = $c->app->minion->backend->list_workers(@_);

    # $c->app->log->debug($c->dumper($stats));

    my $ret = [];

    foreach my $worker (@{ $stats }) {
        push(@{ $ret }, { text => sprintf("[%s] %s PID [%s]", $worker->{id}, $worker->{host}, $worker->{pid}) });
    }

    push(@{ $ret }, { text => "No workers" }) unless @{$ret};

    $c->render(json => $ret);
};

get '/v1/jobs/stats' => sub {
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
    }

    $c->render(json => $ret);
};

app->start;

__DATA__

@@ slash.html.ep

<!DOCTYPE html>
<html>
<head>
    <title></title>
    <link rel="stylesheet" href="http://kendo.cdn.telerik.com/2015.3.930/styles/kendo.mobile.all.min.css" />

    <script src="http://kendo.cdn.telerik.com/2015.3.930/js/jquery.min.js"></script>
    <script src="http://kendo.cdn.telerik.com/2015.3.930/js/kendo.ui.core.min.js"></script>
</head>
<body>

<div data-role="view" id="tabstrip-minion" data-title="Minion" data-layout="mobile-tabstrip" data-model="model.minion" data-init="model.common.init">
    <ul id="listview-minion">
        <script type="text/x-kendo-template" id="listview-minion-template">
            #: text #: #: value #
        </script>
    </ul>
</div>

<div data-role="view" id="tabstrip-workers" data-title="Workers" data-layout="mobile-tabstrip" data-model="model.workers" data-init="model.common.init">
    <ul id="listview-workers">
        <script type="text/x-kendo-template" id="listview-workers-template">
            #: text #
        </script>
    </ul>
</div>

<div data-role="view" id="tabstrip-jobs" data-title="Jobs" data-layout="mobile-tabstrip" data-model="model.jobs" data-init="model.common.init">
    <ul id="listview-jobs">
        <script type="text/x-kendo-template" id="listview-jobs-template">
            #: id #: #: task # [#: queue #]<br>
            State: #: state #<br>
            Args: <code>#: args #</code>
        </script>
    </ul>
</div>

<div data-role="layout" data-id="mobile-tabstrip" data-show="showDemoLayout">
    <header data-role="header">
        <div data-role="navbar">
            <span data-role="view-title"></span>
        </div>
    </header>

    <p>TabStrip</p>

    <div data-role="footer">
        <div data-role="tabstrip">
            <a href="#tabstrip-minion" data-icon="share">Minion</a>
            <a href="#tabstrip-workers" data-icon="settings">Workers</a>
            <a href="#tabstrip-jobs" data-icon="history">Jobs</a>
        </div>
    </div>
</div>

<script>
    var model = kendo.observable({
        common: {
            init: function(e) {
                var model = e.view.model;
                var id = model.listview.id;
                var template = model.listview.template;

                $(id).kendoMobileListView({
                    dataSource: model.dataSource,
                    pullToRefresh: true,            
                    template: $(template).text(),
                });
            },
        },

        minion: {
            listview: {
                id: "#listview-minion",
                template: "#listview-minion-template",
            },

            dataSource: new kendo.data.DataSource({
                transport: {
                    read: {
                        url: "<%= url_for('/v1/minion/stats')->to_abs %>",
                    }
                }
            }),
        },

        workers: {
            listview: {
                id: "#listview-workers",
                template: "#listview-workers-template",
            },

            dataSource: new kendo.data.DataSource({
                transport: {
                    read: {
                        url: "<%= url_for('/v1/workers/stats')->to_abs %>",
                    }
                }
            }),
        },

        jobs: {
            listview: {
                id: "#listview-jobs",
                template: "#listview-jobs-template",
            },

            dataSource: new kendo.data.DataSource({
                transport: {
                    read: {
                        url: "<%= url_for('/v1/jobs/stats')->to_abs %>",
                    }
                }
            })
        },
    });

    var app = new kendo.mobile.Application(document.body, { 
        skin: "nova",

        init: function () {
            kendo.bind($("#tabstrip-minion"), model.minion);
            kendo.bind($("#tabstrip-workers"), model.workers);
            kendo.bind($("#tabstrip-jobs"), model.jobs);
        }
    });
</script>
</body>
</html>
