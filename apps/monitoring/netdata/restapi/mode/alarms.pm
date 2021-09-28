#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package apps::monitoring::netdata::restapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status: %s, current state: %s', $self->{result_values}->{status}, $self->{result_values}->{value_string});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'alarms', type => 1, cb_prefix_output => 'prefix_alarm_output', message_multiple => 'No current alarms' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alarms-total', nlabel => 'netdata.alarms.current.total.count', set => {
                key_values      => [ { name => 'total' }  ],
                output_template => 'total: %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'alarms-warning', nlabel => 'netdata.alarms.current.warning.count', set => {
                key_values      => [ { name => 'warning' }  ],
                output_template => 'warning: %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        },
        { label => 'alarms-critical', nlabel => 'netdata.alarms.current.critical.count', set => {
                key_values      => [ { name => 'critical' }  ],
                output_template => 'critical: %s',
                perfdatas       => [ { template => '%d', min => 0 } ]
            }
        }
   ];

    $self->{maps_counters}->{alarms} = [
        { label => 'alarm', threshold => 0, set => {
                key_values => [ { name => 'display' }, { name => 'name' }, { name => 'status' }, { name => 'value_string'} ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-status:s'   => { name => 'filter_status' }
    });

    return $self;
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Alarms ';
}

sub prefix_alarm_output {
    my ($self, %options) = @_;

    return "Alarm on '" . $options{instance_value}->{name} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { warning => 0, critical => 0 };
    $self->{alarms} = {};
    my $result = $options{custom}->get_alarms();
    foreach my $alarm (values %{$result->{alarms}}) {
        next if ( defined($self->{option_results}->{filter_status})
            && $self->{option_results}->{filter_status} ne ''
            && $alarm->{status} !~ /$self->{option_results}->{filter_status}/ );

        $self->{alarms}->{$alarm} = {
            display      => $alarm,
            id           => $alarm->{id},
            name         => $alarm->{name},
            chart        => $alarm->{chart},
            status       => $alarm->{status},
            value_string => $alarm->{value_string}
        };

        $self->{global}->{warning}++ if ($alarm->{status} =~ m/WARNING/);
        $self->{global}->{critical}++ if ($alarm->{status} =~ m/CRITICAL/);
    }

    $self->{global}->{total} = scalar(keys %{$self->{alarms}});
}

1;

__END__

=head1 MODE

Check Netdata agent current active alarms.

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::netdata::restapi::plugin
--mode=alarms --hostname=10.0.0.1 --warning-alarms-warning=0 --critical-alarms-critical=0--verbose

More information on 'https://learn.netdata.cloud/docs/agent/web/api''.

=over 8

=item B<--filter-status>

Filter on specific alarm status.
Can be 'WARNING' or 'CRITICAL'
(Default: both status shown)

=item B<--warning-alarms-*>

Set Warning threshold for alarms count (Default: '') where '*' can be warning or 'critical'

=item B<--critical-alarms-*>

Set Critical threshold for alarms count (Default: '') where '*' can be 'warning' or 'critical'

=back

=cut
