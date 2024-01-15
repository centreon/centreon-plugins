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

package network::watchguard::snmp::mode::cluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_member_output {
    my ($self, %options) = @_;

    return "member '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'members', display_long => 1, cb_prefix_output => 'prefix_member_output',  message_multiple => 'All members are ok', type => 1, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cluster-status', type => 2, set => {
                key_values => [ { name => 'state' } ],
                output_template => 'cluster is %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'members-detected', nlabel => 'members.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'num_members' } ],
                output_template => 'detected members: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        { label => 'member-status', type => 2, set => {
                key_values => [ { name => 'role' }, { name => 'serial' } ],
                output_template => 'role: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'member-health-hardware', nlabel => 'member.health.hardware.percentage', display_ok => 0, set => {
                key_values => [ { name => 'hwHealth' } ],
                output_template => 'hardware health: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'member-health-system', nlabel => 'member.health.system.percentage', display_ok => 0, set => {
                key_values => [ { name => 'sysHealth' } ],
                output_template => 'system health: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    return $self;
}

my $map_enable = {
    0 => 'disabled', 1 => 'enabled'
};
my $map_role = {
    0 => 'disabled', 1 => 'worker',
    2 => 'backup', 3 => 'master',
    4 => 'idle', 5 => 'standby'
};

my $mapping = {
    enabled         => { oid => '.1.3.6.1.4.1.3097.6.6.1', map => $map_enable }, # wgClusterEnabled
    firstSerial     => { oid => '.1.3.6.1.4.1.3097.6.6.2' }, # wgFirstMemberId
    firstRole       => { oid => '.1.3.6.1.4.1.3097.6.6.3', map => $map_role }, # wgFirstMemberRole
    firstSysHealth  => { oid => '.1.3.6.1.4.1.3097.6.6.4' }, # wgFirstMemberSystemHealth
    firstHwHealth   => { oid => '.1.3.6.1.4.1.3097.6.6.5' }, # wgFirstMemberHardwareHealth
    secondSerial    => { oid => '.1.3.6.1.4.1.3097.6.6.8' }, # wgSecondMemberId
    secondRole      => { oid => '.1.3.6.1.4.1.3097.6.6.9', map => $map_role }, # wgSecondMemberRole
    secondSysHealth => { oid => '.1.3.6.1.4.1.3097.6.6.10' }, # wgSecondMemberSystemHealth
    secondHwHealth  => { oid => '.1.3.6.1.4.1.3097.6.6.11' }  # wgSecondMemberHardwareHealth
};

sub add_member {
    my ($self, %options) = @_;

    return if ($options{role} eq 'disabled');

    $self->{global}->{num_members}++;
    $self->{members}->{ $options{serial} } = \%options;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    $self->{global} = { state => $result->{enabled}, num_members => 0 };

    $self->{members} = {};
    $self->add_member(
        serial => $result->{firstSerial},
        role => $result->{firstRole},
        sysHealth => $result->{firstSysHealth},
        hwHealth => $result->{firstHwHealth}
    );
    $self->add_member(
        serial => $result->{secondSerial},
        role => $result->{secondRole},
        sysHealth => $result->{secondSysHealth},
        hwHealth => $result->{secondHwHealth}
    );
}

1;

__END__

=head1 MODE

Check cluster.

=over 8

=item B<--unknown-cluster-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}

=item B<--warning-cluster-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}

=item B<--critical-cluster-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}

=item B<--unknown-member-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{role}, %{serial}

=item B<--warning-member-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{role}, %{serial}

=item B<--critical-member-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{role}, %{serial}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-detected', 'member-health-hardware', 'member-health-system'.

=back

=cut
