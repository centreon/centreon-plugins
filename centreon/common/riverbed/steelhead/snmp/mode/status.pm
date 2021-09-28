#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package centreon::common::riverbed::steelhead::snmp::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Health is '%s', Status is '%s'",
        $self->{result_values}->{health},
        $self->{result_values}->{status}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{health} = $options{new_datas}->{$self->{instance} . '_health'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_serviceStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_status_output' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{health} !~ /Healthy/ || %{status} !~ /running/', set => {
                key_values => [ { name => 'health' }, { name => 'serviceStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'uptime', set => {
                key_values => [ { name => 'serviceUptime' }, { name => 'serviceUptime_human' } ],
                output_template => 'Uptime: %s', output_use => 'serviceUptime_human',
                perfdatas => [
                    { label => 'uptime', template => '%d', min => 0, unit => 's' }
                ]
            }
        }
    ];
}

sub prefix_status_output {
    my ($self, %options) = @_;

    return "Optimization Service ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>  {
    });

    return $self;
}

my $mappings = {
    common    => {
        health => { oid => '.1.3.6.1.4.1.17163.1.1.2.2' },
        serviceStatus => { oid => '.1.3.6.1.4.1.17163.1.1.2.3' },
        serviceUptime => { oid => '.1.3.6.1.4.1.17163.1.1.2.4' }
    },
    ex => {
        health => { oid => '.1.3.6.1.4.1.17163.1.51.2.2' },
        serviceStatus => { oid => '.1.3.6.1.4.1.17163.1.51.2.3' },
        serviceUptime => { oid => '.1.3.6.1.4.1.17163.1.51.2.4' }
    },
    interceptor => {
        health => { oid => '.1.3.6.1.4.1.17163.1.3.2.2' },
        serviceStatus => { oid => '.1.3.6.1.4.1.17163.1.3.2.3' },
        serviceUptime => { oid => '.1.3.6.1.4.1.17163.1.3.2.4' }
    },
};

my $oids = {
    common => '.1.3.6.1.4.1.17163.1.1.2',
    ex => '.1.3.6.1.4.1.17163.1.51.2',
    interceptor => '.1.3.6.1.4.1.17163.1.3.2'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oids->{common}, start => $mappings->{common}->{health}->{oid}, end => $mappings->{common}->{serviceUptime}->{oid} },
            { oid => $oids->{ex}, start => $mappings->{ex}->{health}->{oid}, end => $mappings->{ex}->{serviceUptime}->{oid} },
            { oid => $oids->{interceptor}, start => $mappings->{interceptor}->{health}->{oid}, end => $mappings->{interceptor}->{serviceUptime}->{oid} }
        ]
    );

    foreach my $equipment (keys %{$oids}) {
        next if (!%{$results->{$oids->{$equipment}}});

        my $result = $options{snmp}->map_instance(mapping => $mappings->{$equipment}, results => $results->{$oids->{$equipment}}, instance => 0);

        $self->{global} = {
            health => $result->{health},
            serviceStatus => $result->{serviceStatus},
            serviceUptime => $result->{serviceUptime} / 100,
            serviceUptime_human => centreon::plugins::misc::change_seconds(value => $result->{serviceUptime} / 100),
        };
    }
}

1;

__END__

=head1 MODE

Check the current status of the optimization service.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{health}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{health} !~ /Healthy/ || %{status} !~ /running/').
Can used special variables like: %{health}, %{status}

=item B<--warning-uptime>

Warning thresholds in seconds.

=item B<--critical-uptime>

Critical thresholds in seconds.

=back

=cut
