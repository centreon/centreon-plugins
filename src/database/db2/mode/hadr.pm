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

package database::db2::mode::hadr;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_role_output {
    my ($self, %options) = @_;

    return sprintf(
        'role: %s [primary member: %s] [standby member: %s]',
        $self->{result_values}->{role},
        $self->{result_values}->{primaryMember},
        $self->{result_values}->{standbyMember}
    );
}

sub custom_role_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{primaryMember} = $options{new_datas}->{$self->{instance} . '_primaryMember'};
    $self->{result_values}->{primaryMemberLast} = $options{old_datas}->{$self->{instance} . '_primaryMember'};
    $self->{result_values}->{standbyMember} = $options{new_datas}->{$self->{instance} . '_standbyMember'};
    $self->{result_values}->{standbyMemberLast} = $options{old_datas}->{$self->{instance} . '_standbyMember'};
    if (!defined($options{old_datas}->{ $self->{instance} . '_role' })) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub server_long_output {
    my ($self, %options) = @_;

    return "checking database instance '" . $options{instance} . "'";
}

sub prefix_server_output {
    my ($self, %options) = @_;

    return "database instance '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'servers', type => 3, cb_prefix_output => 'prefix_server_output', cb_long_output => 'server_long_output', indent_long_output => '    ', message_multiple => 'All database instances are ok',
          group => [
                { name => 'role', type => 0, skipped_code => { -10 => 1 } },
                { name => 'connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'state', type => 0, skipped_code => { -10 => 1 } },
                { name => 'position', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'standby-running', nlabel => 'hadr.instances.standby.count', display_ok => 0, set => {
                key_values => [ { name => 'standby_running' } ],
                output_template => 'number of standby instances running: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{role} = [
        {
            label => 'role',
            type => 2,
            set => {
                key_values => [ { name => 'role' }, { name => 'primaryMember' }, { name => 'standbyMember' }, { name => 'standbyId' } ],
                closure_custom_calc => $self->can('custom_role_calc'),
                closure_custom_output => $self->can('custom_role_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{connection} = [
        {
            label => 'connection-status',
            type => 2,
            warning_default => '%{status} eq "congested"',
            critical_default => '%{status} eq "disconnected"',
            set => {
                key_values => [ { name => 'status' }, { name => 'primaryMember' }, { name => 'standbyMember' }, { name => 'standbyId' } ],
                output_template => 'connection status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{state} = [
        {
            label => 'state',
            type => 2,
            critical_default => '%{state} ne "peer"',
            set => {
                key_values => [ { name => 'state' }, { name => 'primaryMember' }, { name => 'standbyMember' }, { name => 'standbyId' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{position} = [
         { label => 'log-gap', nlabel => 'hadr.instance.log.gap.bytes', set => {
                key_values => [ { name => 'logGap' } ],
                output_template => 'log gap: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT 
            STANDBY_ID, HADR_ROLE, HADR_STATE, HADR_CONNECT_STATUS, PRIMARY_MEMBER_HOST, STANDBY_MEMBER_HOST, HADR_LOG_GAP
        FROM TABLE(MON_GET_HADR(-2)) AS t
    });

    $self->{global} = { standby_running  => 0 };
    $self->{servers} = {};
    while (my $row = $options{sql}->fetchrow_arrayref()) {
        $self->{servers}->{ $row->[0] } = {
            role => {
                standbyId => $row->[0],
                role => lc($row->[1]),
                primaryMember => $row->[4],
                standbyMember => $row->[5]
            },
            connection => {
                standbyId => $row->[0],
                status => lc($row->[3]),
                primaryMember => $row->[4],
                standbyMember => $row->[5]
            },
            state => {
                standbyId => $row->[0],
                state => lc($row->[2]),
                primaryMember => $row->[4],
                standbyMember => $row->[5]
            },
            position => {
                logGap => $row->[6]
            }
        };
        $self->{global}->{standby_running}++;
    }

    $self->{cache_name} = 'db2_' . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check high availability disaster recovery.

=over 8

=item B<--unknown-connection-status>

Set unknown threshold for connection status.
You can use the following variables:  %{status}, %{primaryMember}, %{standbyMember}, %{standbyId}

=item B<--warning-connection-status>

Set warning threshold for connection status (default: '%{status} eq "congested"').
You can use the following variables:  %{status}, %{primaryMember}, %{standbyMember}, %{standbyId}

=item B<--critical-connection-status>

Set critical threshold for connection status (default: '%{status} eq "disconnected"').
You can use the following variables: %{status}, %{primaryMember}, %{standbyMember}, %{standbyId}

=item B<--unknown-state>

Set unknown threshold for state.
You can use the following variables: %{state}, %{primaryMember}, %{standbyMember}, %{standbyId}

=item B<--warning-state>

Set warning threshold for state.
You can use the following variables: %{state}, %{primaryMember}, %{standbyMember}, %{standbyId}

=item B<--critical-state>

Set critical threshold for state (default: '%{state} ne "peer"').
You can use the following variables: %{state}, %{primaryMember}, %{standbyMember}, %{standbyId}

=item B<--unknown-role>

Set unknown threshold for role status.
You can use the following variables: %{role}, %{roleLast}, %{primaryMember}, %{primaryMemberLast}, %{standbyMember}, %{standbyMemberLast}, %{standbyId}

=item B<--warning-role>

Set warning threshold for role status.
You can use the following variables: %{role}, %{roleLast}, %{primaryMember}, %{primaryMemberLast}, %{standbyMember}, %{standbyMemberLast}, %{standbyId}

=item B<--critical-role>

Set critical threshold for role status.
You can use the following variables: %{role}, %{roleLast}, %{primaryMember}, %{primaryMemberLast}, %{standbyMember}, %{standbyMemberLast}, %{standbyId}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'standby-running', 'log-gap'.

=back

=cut
