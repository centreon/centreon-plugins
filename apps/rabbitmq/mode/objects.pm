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

package apps::rabbitmq::mode::objects;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

my $maps_counters = {
    consumers => { thresholds => {
                                warning_consumers => { label => 'warning-consumers', exit_value => 'warning' },
                                critical_consumers => { label => 'critical-consumers', exit_value => 'critical' },
                                },
                 output_msg => 'Number of consumers : %d',
                },
    queues => { thresholds => {
                                warning_queues => { label => 'warning-queues', exit_value => 'warning' },
                                critical_queues => { label => 'critical-queues', exit_value => 'critical' },
                                },
                 output_msg => 'Number of queues : %d',
               },
    exchanges => { thresholds => {
                                warning_exchanges => { label => 'warning-exchanges', exit_value => 'warning' },
                                critical_exchanges => { label => 'critical-exchanges', exit_value => 'critical' },
                               },
                 output_msg => 'Number of exchanges : %d',
                },
    connections => { thresholds => {
                                warning_connections => { label => 'warning-connections', exit_value => 'warning' },
                                critical_connections => { label => 'critical-connections', exit_value => 'critical' },
                               },
                 output_msg => 'Number of connections : %d',
                },

    channels => { thresholds => {
                                warning_channels => { label => 'warning-channels', exit_value => 'warning' },
                                critical_channels => { label => 'critical-channels', exit_value => 'critical' },
                               },
                 output_msg => 'Number of channels : %d',
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
            "urlpath:s"         => { name => 'url_path', default => '/api/overview' },
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

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            }
        }
    }

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
    next if ($self->check_exclude(object => $object));
        foreach my $name (keys %{$maps_counters->{$object}->{thresholds}}) {
            push @exits, $self->{perfdata}->threshold_check(value => $webcontent->{object_totals}->{$object}, threshold => [ { label => $maps_counters->{$object}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$object}->{thresholds}->{$name}->{exit_value} }]);
        }
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    my $str_output = '';
    my $str_append = '';

    foreach my $object (keys %{$maps_counters}) {
        next if ($self->check_exclude(object => $object));
        $str_output .= $str_append . sprintf($maps_counters->{$object}->{output_msg}, $webcontent->{object_totals}->{$object});
        $str_append = ', ';
        my ($warning, $critical);
        foreach my $name (keys %{$maps_counters->{$object}->{thresholds}}) {
            $warning = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$object}->{thresholds}->{$name}->{label}) if ($maps_counters->{$object}->{thresholds}->{$name}->{exit_value} eq 'warning');
            $critical = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$object}->{thresholds}->{$name}->{label}) if ($maps_counters->{$object}->{thresholds}->{$name}->{exit_value} eq 'critical');
        }

        $self->{output}->perfdata_add(label => $object,
                                      value => sprintf("%d", $webcontent->{object_totals}->{$object}),
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

Check RabbitMQ number of objects

=over 8

=item B<--hostname>

IP Addr/FQDN of the RabbitMQ host

=item B<--port>

Port used by RabbitMQ API (Default: '9200')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get RabbitMQ information (Default: '/')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--warning-*>

Threshold warning.
Can be: 'consumers', 'queues', 'exchanges', 'connections', 'channels'.

=item B<--critical-*>

Threshold critical.
Can be: 'consumers', 'queues', 'exchanges', 'connections', 'channels'.

=item B<--exlude>

Exclude specific object (comma seperated list) (Example: --exclude=exchanges,connections)

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=back

=cut
