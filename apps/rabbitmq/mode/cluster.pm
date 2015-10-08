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

package apps::rabbitmq::mode::cluster;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;
use Data::Dumper;

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
            "urlpath:s"         => { name => 'url_path', default => '/api/overview' },
            "nodes:s@"          => { name => 'nodes' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "ssl:s"             => { name => 'ssl', },
            "cert-file:s"       => { name => 'cert_file' },
            "key-file:s"        => { name => 'key_file' },
            "cacert-file:s"     => { name => 'cacert_file' },
            "timeout:s"         => { name => 'timeout' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);


    if (!defined($self->{option_results}->{nodes}) || scalar(@{$self->{option_results}->{nodes}}) == 0) {
            $self->{output}->add_option_msg(short_msg => "Need to specify nodes option.");
            $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
}


sub run {
    my ($self, %options) = @_;

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

    foreach my $listener (@{$webcontent->{listeners}}) {
        foreach my $node (@{$self->{option_results}->{nodes}}) {
            if ($listener->{node} eq $node && $listener->{protocol} eq 'amqp') {
                $self->{$node}->{amqp}++;
            }
        }
    }

    my $str_output = '';
    my $str_append = '';
    my @exits;

    $str_output = sprintf("All nodes are clustered");
    my $exit = 'ok';

    foreach my $node (@{$self->{option_results}->{nodes}}) {
        if (!defined($self->{$node}->{amqp})) {
            push @exits, 'critical';
            if ($exit eq 'ok') {
                $str_output = $str_append . sprintf("Nodes not clustered : %s", $node);
                $str_append = ', ';
            } else {
                $str_output .= $str_append . sprintf("%s", $node);
                $str_append = ', ';
            }
            $exit = 'critical';
        }
    }

    $self->{output}->output_add(severity => $exit,
                                short_msg => $str_output);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check RabbitMQ cluster

=over 8

=item B<--hostname>

IP Addr/FQDN of the RabbitMQ host

=item B<--port>

Port used by RabbitMQ API (Default: '9200')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get RabbitMQ information (Default: '/')

=item B<--nodes>

Specify list of nodes in the cluster (can be multiple)
(Example: --nodes=rabbit@foo --nodes=rabbit@bar).

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
