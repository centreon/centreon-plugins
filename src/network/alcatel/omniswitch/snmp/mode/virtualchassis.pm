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

package network::alcatel::omniswitch::snmp::mode::virtualchassis;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [role: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{role}
    );
}

sub prefix_chassis_output {
    my ($self, %options) = @_;

    return "virtual chassis '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'chassis', display_long => 1, cb_prefix_output => 'prefix_chassis_output',  message_multiple => 'All virtual chassis are ok', type => 1, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'chassis-detected', nlabel => 'chassis.detected.count', display_ok => 0, set => {
                key_values => [ { name => 'num_chassis' } ],
                output_template => 'detected chassis: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{chassis} = [
        { label => 'chassis-status', type => 2, critical_default => '%{status} !~ /init|running/', set => {
                key_values => [ { name => 'status' }, { name => 'role' }, { name => 'mac' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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

my $map_role = {
    0 => 'unassigned', 1 => 'master', 2 => 'slave', 3 => 'inconsistent', 4 => 'startuperror'
};
my $map_status = {
    0 => 'init', 1 => 'running', 2 => 'invalidChassisId', 3 => 'helloDown',
    4 => 'duplicateChassisId', 5 => 'mismatchImage', 6 => 'mismatchChassisType',
    7 => 'mismatchHelloInterval', 8 => 'mismatchControlVlan',
    9 => 'mismatchGroup', 10 => 'mismatchLicenseConfig', 11 => 'invalidLicense',
    12 => 'splitTopology', 13 => 'commandShutdown', 14 => 'failureShutdown'
};

my $mapping = {
    role   => { oid => '.1.3.6.1.4.1.6486.801.1.2.1.69.1.1.2.1.3', map => $map_role }, # virtualChassisRole
    status => { oid => '.1.3.6.1.4.1.6486.801.1.2.1.69.1.1.2.1.5', map => $map_status }, # virtualChassisStatus
    mac    => { oid => '.1.3.6.1.4.1.6486.801.1.2.1.69.1.1.2.1.9' } # virtualChassisMac
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_table = '.1.3.6.1.4.1.6486.801.1.2.1.69.1.1.2';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_table,
        start => $mapping->{role}->{oid},
        end => $mapping->{mac}->{oid},
        nothing_quit => 1
    );

    $self->{global} = { num_chassis => 0 };
    $self->{chassis} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{role}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);

        $self->{global}->{num_chassis}++;
        $result->{mac} = join(':', unpack('(H2)*', $result->{mac}));
        $self->{chassis}->{ $result->{mac} } = $result;
    }
}

1;

__END__

=head1 MODE

Check virtual chassis.

=over 8

=item B<--unknown-chassis-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{role}, %{status}, %{mac}

=item B<--warning-chassis-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{role}, %{status}, %{mac}

=item B<--critical-chassis-status>

Define the conditions to match for the status to be CRITICAL (default: %{status} !~ /init|running/)
You can use the following variables: %{role}, %{status}, %{mac}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'chassis-detected'.

=back

=cut
