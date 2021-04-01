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

package apps::antivirus::kaspersky::snmp::mode::logicalnetwork;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Logical network status is '%s'", $self->{result_values}->{status});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_logicalNetworkStatus'};
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
                key_values => [ { name => 'logicalNetworkStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'new-hosts', nlabel => 'hosts.new.count', set => {
                key_values => [ { name => 'hostsFound' } ],
                output_template => '%d new host(s) found',
                perfdatas => [
                    { label => 'new_hosts', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'groups', nlabel => 'groups.total.count', set => {
                key_values => [ { name => 'groupsCount' } ],
                output_template => '%d group(s) on the server',
                perfdatas => [
                    { label => 'groups', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'not-connected-long-time', nlabel => 'hosts.notconnected.count', set => {
                key_values => [ { name => 'hostsNotConnectedLongTime' } ],
                output_template => '%d host(s) has not connected for a long time',
                perfdatas => [
                    { label => 'not_connected_long_time', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'not-controlled', nlabel => 'hosts.uncontrolled.count', set => {
                key_values => [ { name => 'hostsControlLost' } ],
                output_template => '%d host(s) are not controlled',
                perfdatas => [
                    { label => 'not_controlled', template => '%d', min => 0 }
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

my $oid_logicalNetworkStatus = '.1.3.6.1.4.1.23668.1093.1.5.1';
my $oid_hostsFound = '.1.3.6.1.4.1.23668.1093.1.5.3';
my $oid_groupsCount = '.1.3.6.1.4.1.23668.1093.1.5.4';
my $oid_hostsNotConnectedLongTime = '.1.3.6.1.4.1.23668.1093.1.5.5';
my $oid_hostsControlLost = '.1.3.6.1.4.1.23668.1093.1.5.6';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_logicalNetworkStatus, $oid_hostsFound,
            $oid_groupsCount, $oid_hostsNotConnectedLongTime,
            $oid_hostsControlLost
        ],
        nothing_quit => 1
    );

    $self->{global} = { 
        logicalNetworkStatus => $map_status{$snmp_result->{$oid_logicalNetworkStatus}},
        hostsFound => $snmp_result->{$oid_hostsFound},
        groupsCount => $snmp_result->{$oid_groupsCount},
        hostsNotConnectedLongTime => $snmp_result->{$oid_hostsNotConnectedLongTime},
        hostsControlLost => $snmp_result->{$oid_hostsControlLost}
    };
}

1;

__END__

=head1 MODE

Check logical network status.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '%{status} =~ /Warning/i').
Can use special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status. (Default: '%{status} =~ /Critical/i').
Can use special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'new-hosts', 'groups', 'not-connected-long-time',
'not-controlled'.

=item B<--critical-*>

Threshold critical.
Can be: 'new-hosts', 'groups', 'not-connected-long-time',
'not-controlled'.

=back

=cut
