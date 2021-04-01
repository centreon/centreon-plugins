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

package hardware::devices::eltek::enexus::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use centreon::plugins::misc;

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf('status: %s',
        $self->{result_values}->{status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'alarm', type => 1, cb_prefix_output => 'prefix_alarm_output', message_multiple => 'All alarms are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alarms-active', nlabel => 'alarms.active.count', display_ok => 0, set => {
                key_values => [ { name => 'active' }, { name => 'total' } ],
                output_template => 'current active alarms: %d',
                perfdatas => [
                    { value => 'active', template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{alarm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub prefix_alarm_output {
    my ($self, %options) = @_;

    return "Alarm '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} eq "alarm"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $map_status = { 0 => 'normal', 1 => 'alarm' };

my $mapping = {
    alarmGroupStatus      => { oid => '.1.3.6.1.4.1.12148.10.14.1.1.2', map => $map_status }, 
    alarmGroupDescription => { oid => '.1.3.6.1.4.1.12148.10.14.1.1.3' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_alarmGroupEntry = '.1.3.6.1.4.1.12148.10.14.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_alarmGroupEntry,
        start => $mapping->{alarmGroupStatus}->{oid},
        nothing_quit => 1
    );

    $self->{global} = { total => 0, active => 0 };
    $self->{alarm} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{alarmGroupStatus}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        $result->{alarmGroupDescription} = centreon::plugins::misc::trim($result->{alarmGroupDescription});
        $result->{alarmGroupDescription} = $instance if ($result->{alarmGroupDescription} eq '');

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{alarmGroupDescription} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping alarm '" . $result->{alarmGroupDescription} . "'.", debug => 1);
            next;
        }

        $self->{alarm}->{$instance} = {
            name => $result->{alarmGroupDescription},
            status => $result->{alarmGroupStatus}
        };
        $self->{global}->{total}++;
        $self->{global}->{active}++ if ($result->{alarmGroupStatus} eq 'alarm');
    }
}

1;

__END__

=head1 MODE

Check alarms.

=over 8

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{state}, %{status}, %{lastOpError}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{name}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "alarm").
Can used special variables like: %{name}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'alarms-active'.

=back

=cut
