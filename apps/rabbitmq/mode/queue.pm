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

package apps::rabbitmq::mode::queue;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

my $maps_counters = {
    messages => { thresholds => {
                                warning_messages  =>  { label => 'warning-messages', exit_value => 'warning' },
                                critical_messages =>  { label => 'critical-messages', exit_value => 'critical' },
                                },
                 output_msg => 'Number of messages : %d',
                },
    messages_ready => { thresholds => {
                                warning_messages_ready    =>  { label => 'warning-messages_ready', exit_value => 'warning' },
                                critical_messages_ready   =>  { label => 'critical-messages_ready', exit_value => 'critical' },
                                },
                 output_msg => 'Number of ready messages : %d',
               },
    messages_unacknowledged => { thresholds => {
                                warning_messages_unacknowledged  =>  { label => 'warning-messages_unacknowledged', exit_value => 'warning' },
                                critical_messages_unacknowledged  =>  { label => 'critical-messages_unacknowledged', exit_value => 'critical' },
                               },
                 output_msg => 'Number of unacknowledged messages : %d',
                },
    consumers => { thresholds => {
                                warning_consumers  =>  { label => 'warning-consumers', exit_value => 'warning' },
                                critical_consumers  =>  { label => 'critical-consumers', exit_value => 'critical' },
                               },
                 output_msg => 'Number of consumers : %d',
                },
};

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
            "urlpath:s"         => { name => 'url_path', default => '/api/queues' },
            "vhost:s"           => { name => 'vhost', default => '/' },
            "queue:s"           => { name => 'queue' },
            "credentials"       => { name => 'credentials' },
            "username:s"        => { name => 'username' },
            "password:s"        => { name => 'password' },
            "ssl:s"             => { name => 'ssl' },
            "cert-file:s"       => { name => 'cert_file' },
            "key-file:s"        => { name => 'key_file' },
            "cacert-file:s"     => { name => 'cacert_file' },
            "timeout:s"         => { name => 'timeout' },
        });

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $options{options}->add_options(arguments => {
                                                         $maps_counters->{$_}->{thresholds}->{$name}->{label} . ':s'    => { name => $name },
                                                        });
        }
    }

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{queue})) {
        $self->{output}->add_option_msg(short_msg => "You need to specify the queue option");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{vhost} eq '/') {
        $self->{option_results}->{vhost} = '%2f';
    }

    $self->{option_results}->{url_path} = $self->{option_results}->{url_path} . "/" . $self->{option_results}->{vhost} . "/" . $self->{option_results}->{queue} ;
    $self->{http}->set_options(%{$self->{option_results}});

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            }
        }
    }
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

    my @exits;

    foreach my $object (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$object}->{thresholds}}) {
           push @exits, $self->{perfdata}->threshold_check(value => $webcontent->{$object}, threshold => [ { label => $maps_counters->{$object}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$object}->{thresholds}->{$name}->{exit_value} }]);
        }
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    my $str_output = '';
    my $str_append = '';

    foreach my $object (keys %{$maps_counters}) {
        $str_output .= $str_append . sprintf($maps_counters->{$object}->{output_msg}, $webcontent->{$object});
        $str_append = ', ';
        my ($warning, $critical);
        foreach my $name (keys %{$maps_counters->{$object}->{thresholds}}) {
            $warning = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$object}->{thresholds}->{$name}->{label}) if ($maps_counters->{$object}->{thresholds}->{$name}->{exit_value} eq 'warning');
            $critical = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$object}->{thresholds}->{$name}->{label}) if ($maps_counters->{$object}->{thresholds}->{$name}->{exit_value} eq 'critical');
        }

        $self->{output}->perfdata_add(label => $object,
                                      value => sprintf("%d", $webcontent->{$object}),
                                      warning => $warning,
                                      critical => $critical,
                                      min => 0,);
    }

    $self->{output}->output_add(severity => $exit,
                                short_msg => $str_output);

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

=item B<--vhost>

Specify one vhost's name (Default: '/')

=item B<--queue>

Specify one queue's name

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
Can be: 'messages', 'messages_ready', 'messages_unacknowledged', 'consumers'.

=item B<--critical-*>

Threshold critical.
Can be: 'messages', 'messages_ready', 'messages_unacknowledged', 'consumers'.

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
