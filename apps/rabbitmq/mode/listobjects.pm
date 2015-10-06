#
# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::rabbitmq::mode::listobjects;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"        => { name => 'hostname' },
            "port:s"            => { name => 'port', default => '15672'},
            "proto:s"           => { name => 'proto' },
            "urlpath:s"         => { name => 'url_path', default => '/api' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "ssl:s"             => { name => 'ssl', },
            "cert-file:s"       => { name => 'cert_file' },
            "key-file:s"        => { name => 'key_file' },
            "cacert-file:s"     => { name => 'cacert_file' },
            "exclude:s"         => { name => 'exclude' },
            "timeout:s"         => { name => 'timeout' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{http}->set_options(%{$self->{option_results}});
}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{object}}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping ${options{object}} object."));
        return 1;
    }
return 0;
}


sub list_vhosts {
    my ($self, %options) = @_;
    $self->{option_results}->{url_path} = "/api/vhosts";
    $self->{http}->set_options(%{$self->{option_results}});

    my $jsoncontent = $self->{http}->request();
    my $json = JSON->new;
    my $webcontent;

    eval {
    $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => sprintf("List vhosts :"));
    foreach my $vhost (@$webcontent) {
        return if ($self->check_exclude(object => 'vhost'));
        $self->{output}->output_add(long_msg => sprintf("%s", $vhost->{name}));

        $self->{output}->add_disco_entry(object => 'vhost',
                                         name => $vhost->{name});
    }
}

sub list_exchanges {
    my ($self, %options) = @_;
    $self->{option_results}->{url_path} = "/api/exchanges";
    $self->{http}->set_options(%{$self->{option_results}});

    my $jsoncontent = $self->{http}->request();
    my $json = JSON->new;
    my $webcontent;

    eval {
    $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => sprintf("List exchanges :"));
    foreach my $exchange (@$webcontent) {
        return if ($self->check_exclude(object => 'exchange'));
        $self->{output}->output_add(long_msg => sprintf("%s [vhost = %s]",
                                                        $exchange->{name},
                                                        $exchange->{vhost}));

        $self->{output}->add_disco_entry(object => 'exchange',
                                         name => $exchange->{name},
                                         vhost => $exchange->{vhost},
                                        );
    }
}

sub list_bindings {
    my ($self, %options) = @_;
    $self->{option_results}->{url_path} = "/api/bindings";
    $self->{http}->set_options(%{$self->{option_results}});

    my $jsoncontent = $self->{http}->request();
    my $json = JSON->new;
    my $webcontent;

    eval {
    $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => sprintf("List bindings :"));
    foreach my $binding (@$webcontent) {
        return if ($self->check_exclude(object => 'binding'));
        $self->{output}->output_add(long_msg => sprintf("[vhosts = %s, source = %s, destination = %s, routing_key = %s ]",
                                                        $binding->{vhost},
                                                        $binding->{source},
                                                        $binding->{destination},
                                                        $binding->{routing_key}));

        $self->{output}->add_disco_entry(object => 'binding',
                                         vhost => $binding->{vhost},
                                         source => $binding->{source},
                                         destination => $binding->{destination},
                                         routing_key => $binding->{routing_key},
                                        );
    }
}

sub list_queues {
    my ($self, %options) = @_;
    $self->{option_results}->{url_path} = "/api/queues";
    $self->{http}->set_options(%{$self->{option_results}});

    my $jsoncontent = $self->{http}->request();
    my $json = JSON->new;
    my $webcontent;

    eval {
    $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => sprintf("List queues :"));
    foreach my $queue (@$webcontent) {
        return if ($self->check_exclude(object => 'queue'));
        $self->{output}->output_add(long_msg => sprintf("%s [ vhost = %s, node = %s, state = %s ]",
                                                        $queue->{name},
                                                        $queue->{vhost},
                                                        $queue->{node},
                                                        $queue->{status}));

        $self->{output}->add_disco_entry(object => 'queue',
                                         name => $queue->{name},
                                         vhost => $queue->{vhost},
                                         node => $queue->{node},
                                         status => $queue->{status},
                                        );
    }
}

sub list_channels {
    my ($self, %options) = @_;
    $self->{option_results}->{url_path} = "/api/channels";
    $self->{http}->set_options(%{$self->{option_results}});

    my $jsoncontent = $self->{http}->request();
    my $json = JSON->new;
    my $webcontent;

    eval {
    $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => sprintf("List channels :"));
    foreach my $channel (@$webcontent) {
        return if ($self->check_exclude(object => 'channel'));
        $self->{output}->output_add(long_msg => sprintf("%s [ vhost = %s, user = %s, node = %s ]",
                                                        $channel->{name},
                                                        $channel->{vhost},
                                                        $channel->{user},
                                                        $channel->{node}));

        $self->{output}->add_disco_entry('object' => 'channel',
                                         name => $channel->{name},
                                         vhost => $channel->{vhost},
                                         user => $channel->{user},
                                         node => $channel->{node},
                                        );
     }

}

sub list_nodes {
    my ($self, %options) = @_;
    $self->{option_results}->{url_path} = "/api/nodes";
    $self->{http}->set_options(%{$self->{option_results}});

    my $jsoncontent = $self->{http}->request();
    my $json = JSON->new;
    my $webcontent;

    eval {
    $webcontent = $json->decode($jsoncontent);
    };

    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => sprintf("List nodes :"));
    foreach my $node (@$webcontent) {
        return if ($self->check_exclude(object => 'node'));
        $self->{output}->output_add(long_msg => sprintf("%s [ type = %s, running = %s ]",
                                                        $node->{name},
                                                        $node->{type},
                                                        $node->{running}));

        $self->{output}->add_disco_entry(object => 'node',
                                         name => $node->{name},
                                         type => $node->{type},
                                         running => $node->{running},
                                        );
    }
}

sub disco_format {
    my ($self, %options) = @_;

    my $vhosts = ['object', 'name'];
    my $exchanges = ['object', 'name', 'vhost'];
    my $bindings = ['object', 'vhost', 'source', 'destination', 'routing_key'];
    my $queues = ['object', 'name', 'vhost', 'node', 'status'];
    my $channels = ['object', 'name', 'vhost', 'user', 'node'];
    my $nodes = ['object', 'name', 'type', 'running'];
    $self->{output}->add_disco_format(elements => $vhosts, $exchanges, $bindings, $queues, $channels, $nodes);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->list_vhosts();
    $self->list_exchanges();
    $self->list_bindings();
    $self->list_queues();
    $self->list_channels();
    $self->list_nodes();
}


sub run {
    my ($self, %options) = @_;

    $self->list_vhosts();
    $self->list_exchanges();
    $self->list_bindings();
    $self->list_queues();
    $self->list_channels();
    $self->list_nodes();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List objects:');

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Elasticsearch number of nodes

=over 8

=item B<--hostname>

IP Addr/FQDN of the Elasticsearch host

=item B<--port>

Port used by Elasticsearch API (Default: '9200')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get Elasticsearch information (Default: '/')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--exlude>

Exclude specific object (comma seperated list) (Example: --exclude=vhost,binding)

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
