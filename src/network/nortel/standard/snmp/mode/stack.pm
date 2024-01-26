#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::nortel::standard::snmp::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use network::nortel::standard::snmp::mode::components::resources qw($map_comp_status);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{serial},
        value => floor($self->{result_values}->{detected_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{detected_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_unit_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'operational state: %s [admin state: %s]',
        $self->{result_values}->{operState},
        $self->{result_values}->{adminState}
    );
}

sub unit_long_output {
    my ($self, %options) = @_;

    return "checking stack unit '" . $options{instance} . "'";
}

sub prefix_unit_output {
    my ($self, %options) = @_;

    return "Stack unit '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'units', type => 3, cb_prefix_output => 'prefix_unit_output', cb_long_output => 'unit_long_output', indent_long_output => '    ', message_multiple => 'All stack units are ok',
            group => [
                { name => 'unit_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'unit_detected', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'units-total', nlabel => 'stack.units.count', set => {
                key_values => [ { name => 'units' } ],
                output_template => 'Number of units: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{unit_global} = [
        {
            label => 'unit-status',
            type => 2,
            warning_default => '%{adminState} eq "enable" && %{operState} =~ /nonFatalErr|warning/i',
            critical_default => '%{adminState} eq "enable" && %{operState} =~ /fatalErr/i',
            set => {
                key_values => [ { name => 'operState' }, { name => 'adminState' }, { name => 'serial' } ],
                closure_custom_output => $self->can('custom_unit_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{unit_detected} = [
        { label => 'unit-detected', nlabel => 'stack.unit.detected', set => {
                key_values      => [ { name => 'detected_seconds' }, { name => 'detected_human' }, { name => 'serial' } ],
                output_template => 'detected: %s',
                output_use => 'detected_human',
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unit:s' => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

my $mapping_admin_state = {
    1 => 'other', 2 => 'notAvail', 3 => 'disable', 4 => 'enable', 5 => 'reset', 6 => 'test'
};

my $mapping = {
    serial     => { oid => '.1.3.6.1.4.1.45.1.6.3.3.1.1.7' }, # s5ChasComSerNum
    lastChange => { oid => '.1.3.6.1.4.1.45.1.6.3.3.1.1.8' }, # s5ChasComLstChng
    adminState => { oid => '.1.3.6.1.4.1.45.1.6.3.3.1.1.9', map => $mapping_admin_state }, # s5ChasComAdminState
    operState  => { oid => '.1.3.6.1.4.1.45.1.6.3.3.1.1.10', map => $map_comp_status } # s5ChasComOperState
};
my $oid_s5ChasComEntry = '.1.3.6.1.4.1.45.1.6.3.3.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_s5ChasGrpType = '.1.3.6.1.4.1.45.1.6.3.2.1.1.2';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_s5ChasGrpType,
        nothing_quit => 1
    );

    my $groups = {};
    foreach (keys %$snmp_result) {
        next if ($snmp_result->{$_} ne '.1.3.6.1.4.1.45.1.6.1.2.8');
        /^$oid_s5ChasGrpType\.(\d+)/;
        $groups->{$1} = 1;
    }

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_s5ChasComEntry,
        start => $mapping->{serial}->{oid},
        end => $mapping->{operState}->{oid}
    );

    $self->{global} = { units => 0 };
    $self->{units} = {};
    foreach (keys %$snmp_result) {
        next if (!(/^$mapping->{serial}->{oid}\.(\d+)\.(.*)$/ && defined($groups->{$1})));

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1 . '.' . $2);

        $self->{units}->{ $result->{serial} }->{unit_global} = $result;
        $self->{units}->{ $result->{serial} }->{unit_detected} = {
            detected_seconds => floor($result->{lastChange} / 100),
            detected_human => centreon::plugins::misc::change_seconds(
                value => floor($result->{lastChange} / 100)
            ),
            serial => $result->{serial}
        };
        $self->{global}->{units}++;
    }
}

1;

__END__

=head1 MODE

Check stack units.

=over 8

=item B<--unknown-unit-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{operState}, %{adminState}, %{serial}

=item B<--warning-unit-status>

Define the conditions to match for the status to be WARNING (default: '%{adminState} eq "enable" && %{operState} =~ /nonFatalErr|warning/i').
You can use the following variables: %{operState}, %{adminState}, %{serial}

=item B<--critical-unit-status>

Define the conditions to match for the status to be CRITICAL (default: '%{adminState} eq "enable" && %{operState} =~ /fatalErr/i').
You can use the following variables: %{operState}, %{adminState}, %{serial}

=item B<--unit>

Select the time unit for the performance data and thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'units-total', 'unit-detected'.

=back

=cut
