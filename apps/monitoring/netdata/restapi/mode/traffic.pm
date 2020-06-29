#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::monitoring::netdata::restapi::mode::traffic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_traffic_output {
    my ($self, %options) = @_;

    return "Interface '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_traffic_output', message_multiple => 'All interfaces are ok' }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'traffic-in', nlabel => 'network.trafficin.bitspersecond', set => {
                key_values => [ { name => 'traffic_in' }, { name => 'traffic_out' }, { name => 'display' } ],
                output_template => 'Traffic In: %.2f%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', value => 'traffic_in', template => '%d', min => 0, max => 'speed',
                      unit => 'b/s', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'network.trafficin.bitspersecond', set => {
                key_values => [ { name => 'traffic_out' }, { name => 'traffic_in' }, { name => 'display' } ],
                output_template => 'Traffic Out: %.2f%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', value => 'traffic_out', template => '%d', min => 0, max => 'speed',
                      unit => 'b/s', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
          'chart-period:s'      => { name => 'chart_period', default => '300' },
          'chart-statistics:s'  => { name => 'chart_statistics', default => 'average' },
          'interface-name:s'    => { name => 'interface_name' },
          'speed:s'             => { name => 'speed', default => '1000000000'}
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $full_list = $options{custom}->list_charts();

    foreach my $chart (values %{$full_list->{charts}}) {
        next if ($chart->{name} !~ '^net\.');
        push @{$self->{interface_list}}, $chart->{name};
    }

    foreach my $interface (@{$self->{interface_list}}) {
        my $result = $options{custom}->get_data(
            chart => $interface,
            dimensions => 'received,sent',
            points => $self->{option_results}->{chart_point},
            after_period => $self->{option_results}->{chart_period},
            group => $self->{option_results}->{chart_statistics},
            absolute => 1
        );

        $interface =~ s/net.//;

        next if (defined($self->{option_results}->{interface_name}) &&
            $self->{option_results}->{interface_name} ne '' &&
            $interface !~ /$self->{option_results}->{interface_name}/
        );

        foreach my $interface_value (@{$result->{data}}) {
            foreach my $interface_label (@{$result->{labels}}) {
                $self->{interface}->{$interface}->{$interface_label} = shift @{$interface_value};
            }
        }

        $self->{interfaces}->{$interface} = {
            display => $interface,
            traffic_in => $self->{interface}->{$interface}->{received} * 1000,
            traffic_out => $self->{interface}->{$interface}->{sent} * 1000,
            speed => $self->{option_results}->{speed}
        };
    }

    if (scalar(keys %{$self->{interfaces}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No interfaces found');
        $self->{output}->option_exit();
    }
};

1;

__END__

=head1 MODE

Check traffic on interfaces of *nix based servers using the Netdata agent RestAPI.

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::netdata::restapi::plugin
--mode=traffic --hostname=10.0.0.1 --chart-period=300 --warning-traffic-in='70000000' --critical-traffic-in='80000000' --verbose

More information on 'https://learn.netdata.cloud/docs/agent/web/api'.

=over 8

=item B<--chart-period>

The period in seconds on which the values are calculated
Default: 300

=item B<--chart-statistic>

The statistic calculation method used to parse the collected data.
Can be : average, sum, min, max
Default: average

=item B<--interface-name>

Filter on a specific interface. Regexp can be used.
Example: --interface-name='^eth0$'

=item B<--speed>

Set interfaces speed in B/s.
Default: 1000000000 (1GB/s).

=item B<--warning-traffic-*>

Warning threshold on interface traffic where '*' can be:
in,out.

=item B<--critical-traffic-*>

Critical threshold on interface traffic where '*' can be:
in,out.

=back

=cut
