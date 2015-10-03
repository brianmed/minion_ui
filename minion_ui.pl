#!/usr/bin/env perl

use Mojolicious::Lite;

use Mojo::JSON qw(encode_json);

plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/jobs"};

get '/' => sub {
    my $c = shift;

    $c->render(template => 'slash');
};

get '/v1/minion/stats' => sub {
    my $c = shift;

    my $stats = $c->app->minion->stats;

    my $ret = { 
        inactive_workers => $stats->{inactive_workers},
        active_workers => $stats->{active_workers},
        active_jobs => $stats->{active_jobs},
        failed_jobs => $stats->{failed_jobs},
        finished_jobs => $stats->{finished_jobs},
        epoch => time,
    };

    $c->render(json => $ret);
};

get '/v1/workers/stats' => sub {
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
    <link rel="stylesheet" href="/epoch.min.css" />

    <script src="http://kendo.cdn.telerik.com/2015.3.930/js/jquery.min.js"></script>
    <script src="http://kendo.cdn.telerik.com/2015.3.930/js/kendo.ui.core.min.js"></script>

    <script src="/d3.min.js"></script>
    <script src="/epoch.min.js"></script>
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
            # if (data.text) { #
                #: data.text #
            # } else { #
                [#: id #] #: host # [#:pid#]
            # } #
        </script>
    </ul>
</div>

<div data-role="view" id="tabstrip-jobs" data-title="Jobs" data-layout="mobile-tabstrip" data-model="model.jobs" data-init="model.common.init">
    <ul id="listview-jobs">
        <script type="text/x-kendo-template" id="listview-jobs-template">
            # if (data.text) { #
                #: data.text #
            # } else { #
                #: id #: #: task # [#: queue #]<br>
                State: #: state #<br>
                Args: <code>#: args #</code>
            # } #
        </script>
    </ul>
</div>

<div data-role="view" id="tabstrip-graphs" data-title="Graphs" data-layout="mobile-tabstrip" data-model="model.graphs" data-show="model.graphs.show" data-init="model.graphs.init">
    <h3><b>Inactive and Active Workers</b></h3>
    <div id="minionWorker" class="epoch" style="height: 200px; margin-top: 20px;"></div>
</div>

<div data-role="layout" data-id="mobile-tabstrip">
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
            <a href="#tabstrip-graphs" data-icon="globe">Graphs</a>
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
                },
                schema: {
                    data: function(response) {
                        return [
                            { text: "Inactive Workers", value: response.inactive_workers },
                            { text: "Active Workers", value: response.active_workers },
                            { text: "Active Jobs", value: response.active_jobs },
                            { text: "Failed Jobs", value: response.failed_jobs },
                            { text: "Finished Jobs", value: response.finished_jobs }
                        ];
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
                },
                schema: {
                    data: function(response) {
                        var ret = [];

                        $.each(response, function(idx, value) {
                            ret.push({
                                id: value.id,
                                host: value.host,
                                pid: value.pid,
                            });
                        });

                        if (0 === ret.length) {
                            return [{ text: "No workers" }];
                        }

                        return ret;
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

        graphs: {
            workerGraph: null,

            init: function(e) {
                $(function() {
                    updWorkerData();

                    function updWorkerData() {
                        if ("Graphs" === app.view().title) {
                            $.getJSON("<%= url_for("/v1/minion/stats") %>", function(result) {
                                var data = [
                                    { time: result.epoch, y: result.active_workers },
                                    { time: result.epoch, y: result.inactive_workers } 
                                ];
                                if (null != app.view().model.workerGraph) {
                                    app.view().model.workerGraph.push(data);
                                }
                            });
                        }

                        setTimeout(updWorkerData, 3000);
                    }
                });
            },

            show: function(e) {
                var model = e.view.model;

                $.getJSON("<%= url_for("/v1/minion/stats") %>", function(result) {
                    model.workerGraph = $('#minionWorker').epoch({
                        type: 'time.line',
                        axes: ['left', 'bottom', 'right'],
                        data: [
                            {
                                label: "Active",
                                values: [ { time: result.epoch, y: result.active_workers } ]
                            },
                            {
                                label: "Inactive",
                                values: [ { time: result.epoch, y: result.inactive_workers } ]
                            } 
                        ]
                    });
                });
            },
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
