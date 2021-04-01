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

package apps::antivirus::kaspersky::snmp::mode::protection;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Protection status is '%s'", $self->{result_values}->{status});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_protectionStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'status',
            type => 2,
            warning_default => '%{status} =~ /Warning/i',
            critical_default => '%{status} =~ /Critical/i',
            set => {
                key_values => [ { name => 'protectionStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'no-antivirus', nlabel => 'protection.hosts.antivirus.notrunning.count', set => {
                key_values => [ { name => 'hostsAntivirusNotRunning' } ],
                output_template => '%d host(s) without running antivirus',
                perfdatas => [
                    { label => 'no_antivirus', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'no-real-time', nlabel => 'protection.hosts.realtime.notrunning.count', set => {
                key_values => [ { name => 'hostsRealtimeNotRunning' } ],
                output_template => '%d hosts(s) without running real time protection',
                perfdatas => [
                    { label => 'no_real_time', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'not-acceptable-level', nlabel => 'protection.hosts.realtime.unacceptable.level.count', set => {
                key_values => [ { name => 'hostsRealtimeLevelChanged' } ],
                output_template => '%d host(s) with not acceptable level of real time protection',
                perfdatas => [
                    { label => 'not_acceptable_level', value => 'hostsRealtimeLevelChanged', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'not-cured-objects', nlabel => 'protection.hosts.uncured.objects.count', set => {
                key_values => [ { name => 'hostsNotCuredObject' } ],
                output_template => '%d host(s) with not cured objects',
                perfdatas => [
                    { label => 'not_cured_objects', value => 'hostsNotCuredObject', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'too-many-threats', nlabel => 'protection.hosts.toomanythreats.count', set => {
                key_values => [ { name => 'hostsTooManyThreats' } ],
                output_template => '%d host(s) with too many threats',
                perfdatas => [
                    { label => 'too_many_threats', template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my %map_status = (
    0 => 'OK',
    1 => 'Info',
    2 => 'Warning',
    3 => 'Critical'
);

my $oid_protectionStatus = '.1.3.6.1.4.1.23668.1093.1.3.1';
my $oid_hostsAntivirusNotRunning = '.1.3.6.1.4.1.23668.1093.1.3.3';
my $oid_hostsRealtimeNotRunning = '.1.3.6.1.4.1.23668.1093.1.3.4';
my $oid_hostsRealtimeLevelChanged = '.1.3.6.1.4.1.23668.1093.1.3.5';
my $oid_hostsNotCuredObject = '.1.3.6.1.4.1.23668.1093.1.3.6';
my $oid_hostsTooManyThreats = '.1.3.6.1.4.1.23668.1093.1.3.7';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_protectionStatus, $oid_hostsAntivirusNotRunning,
            $oid_hostsRealtimeNotRunning, $oid_hostsRealtimeLevelChanged,
            $oid_hostsNotCuredObject, $oid_hostsTooManyThreats
        ],
        nothing_quit => 1
    );

    $self->{global} = { 
        protectionStatus => $map_status{$snmp_result->{$oid_protectionStatus}},
        hostsAntivirusNotRunning => $snmp_result->{$oid_hostsAntivirusNotRunning},
        hostsRealtimeNotRunning => $snmp_result->{$oid_hostsRealtimeNotRunning},
        hostsRealtimeLevelChanged => $snmp_result->{$oid_hostsRealtimeLevelChanged},
        hostsNotCuredObject => $snmp_result->{$oid_hostsNotCuredObject},
        hostsTooManyThreats => $snmp_result->{$oid_hostsTooManyThreats}
    };
}

1;

__END__

=head1 MODE

Check protection status.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '%{status} =~ /Warning/i').
Can use special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} =~ /Critical/i').
Can use special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'no-antivirus', 'no-real-time', 'not-acceptable-level',
'not-cured-objects', 'too-many-threats'.

=item B<--critical-*>

Threshold critical.
Can be: 'no-antivirus', 'no-real-time', 'not-acceptable-level',
'not-cured-objects', 'too-many-threats'.

=back

=cut
