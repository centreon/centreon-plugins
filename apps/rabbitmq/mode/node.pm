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

package apps::rabbitmq::mode::node;

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
            "urlpath:s"         => { name => 'url_path', default => '/api/nodes' },
            "node:s"            => { name => 'node' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "ssl:s"             => { name => 'ssl' },
            "cert-file:s"       => { name => 'cert_file' },
            "key-file:s"        => { name => 'key_file' },
            "cacert-file:s"     => { name => 'cacert_file' },
            "timeout:s"         => { name => 'timeout' },
        });

    foreach my $label ('memory', 'fd', 'socket', 'process') {
        $options{options}->add_options(arguments => {"warning-" . $label . ":s"    => { name => "warning-" . $label },
                                                     "critical-" . $label . ":s"    => { name => "critical-" . $label }
                                                    });
    }

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{node})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify the node option");
        $self->{output}->option_exit();
    }

    $self->{option_results}->{url_path} = $self->{option_results}->{url_path} . "/" . $self->{option_results}->{node} ;
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

    my $memory = $webcontent->{mem_used} / $webcontent->{mem_limit};
    my $fd = $webcontent->{fd_used} / $webcontent->{fd_total};
    my $socket = $webcontent->{sockets_used} / $webcontent->{sockets_total};
    my $process = $webcontent->{proc_used} / $webcontent->{proc_total};

    my @exits;
    foreach my $label ('memory', 'fd', 'socket', 'process') {
        push @exits, $self->{perfdata}->threshold_check(value => $label ,threshold => [ { label => 'critical-' . $label, 'exit_litteral' => 'critical'}, { label => 'warning-' . $label, 'exit_litteral' => 'warning'} ]);
        $self->{output}->perfdata_add(label => $label, unit => '%',
                                      value => $label,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $label),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $label),
                                      min => 0,
                                      max => 0,
                                     );
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory usage : %.2f%% - FD usage : %.2f%% - Socket usage : %.2f%% - Process usage : %.2f%%",
                                                    $memory, $fd, $socket, $process));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check messages pending and consumers on a given queue

=over 8

=item B<--hostname>

IP Addr/FQDN of the RabbitMQ server

=item B<--port>

Port used by RabbitMQ Management API (Default: '15672')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get RabbitMQ information (Default: '/api/queues')

=item B<--node>

Specify one node's name

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--ssl>

Specify SSL version (example : 'sslv3', 'tlsv1'...)

=item B<--cert-file>

Specify certificate to send to the webserver

=item B<--key-file>

Specify key to send to the webserver

=item B<--cacert-file>

Specify root certificate to send to the webserver

=item B<--warning-*>

Threshold warning.
Can be: 'memory', 'fd', 'socket', 'process'.

=item B<--critical-*>

Threshold critical.
Can be: 'memory', 'fd', 'socket', 'process'.

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
