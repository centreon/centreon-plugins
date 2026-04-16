#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package network::aruba::aoscx::snmp::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_member_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'role: %s [state: %s]',
        $self->{result_values}->{role},
        $self->{result_values}->{state},
    );
    return $msg;
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};

    $self->{result_values}->{stateLast} = $options{old_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub custom_port_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'operational status: %s [admin status: %s]',
        $self->{result_values}->{oper_status},
        $self->{result_values}->{admin_status}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name                 => 'member',
            type               => 3,
            cb_prefix_output   => 'prefix_member_output',
            cb_long_output     => 'member_long_output',
            indent_long_output => '    ',
            message_multiple   => 'All stack members are ok',
            group              =>
                [
                    { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                    { name               => 'port',
                        display_long     => 1,
                        cb_prefix_output => 'prefix_port_output',
                        message_multiple => 'All ports are ok',
                        type             => 1,
                        skipped_code     => { -10 => 1 } },
                ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'member-status', threshold => 0, set => {
            key_values                     => [ { name => 'role' }, { name => 'display' }, { name => 'state'} ],
            closure_custom_calc            => $self->can('custom_member_status_calc'),
            closure_custom_output          => $self->can('custom_member_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold,
        }
        },
    ];

    $self->{maps_counters}->{port} = [
        { label => 'port-status', threshold => 0, set => {
            key_values                     =>
                [ { name => 'oper_status' }, { name => 'admin_status' }, { name => 'display' } ],
            closure_custom_calc            => \&catalog_status_calc,
            closure_custom_output          => $self->can('custom_port_status_output'),
            closure_custom_perfdata        => sub {return 0;},
            closure_custom_threshold_check => \&catalog_status_threshold,
        }
        },
    ];
}

sub member_long_output {
    my ($self, %options) = @_;

    return "checking stack member '" . $options{instance_value}->{display} . "'";
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Stack member '" . $options{instance_value}->{display} . "' ";
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return "port '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-member-status:s'  => { name => 'unknown_member_status', default => '' },
        'warning-member-status:s'  => { name => 'warning_member_status', default => '' },
        'critical-member-status:s' => { name => 'critical_member_status', default => '%{role} ne %{roleLast}' },
        'unknown-port-status:s'    => { name => 'unknown_port_status', default => '' },
        'warning-port-status:s'    => { name => 'warning_port_status', default => '' },
        'critical-port-status:s'   => {
            name    => 'critical_port_status',
            default => '%{admin_status} eq "up"  and %{oper_status} ne "up"'
        },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'unknown_member_status', 'warning_member_status', 'critical_member_status',
            'unknown_port_status', 'warning_port_status', 'critical_port_status'
        ]
    );
}

my $map_member_state = {
    0  => 'unusedId',
    1  => 'missing',
    2  => 'provision',
    3  => 'commander',
    4  => 'standby',
    5  => 'member',
    6  => 'shutdown',
    7  => 'booting',
    8  => 'communicationFailure',
    9  => 'incompatibleOs',
    10 => 'unknownState',
    11 => 'standbyBooting'
};
my $map_member_role_status = {
    1 => 'active',
    2 => 'notInService',
    3 => 'notReady',
    4 => 'createAndGo',
    5 => 'createAndWait',
    6 => 'destroy'
};
my $map_port_admin_status = {
    1 => 'enabled',
    2 => 'disabled'
};
my $map_port_operation_status = {
    1 => 'up',
    2 => 'down',
    3 => 'disabled',
    4 => 'blocked'
};

my $mapping_member_table = {
    stackMemberSerialNum  => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.14' },
    stackMemberRoleStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.7', map => $map_member_role_status },
    stackMemberState      => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.9', map => $map_member_state },
};
my $mapping_port_table = {
    stackPortAdminStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.5.1.8', map => $map_port_admin_status },
    stackPortOperStatus  => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.5.1.3', map => $map_port_operation_status }
};

my $oid_memberTableEntry = '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1';
my $oid_portTableEntry = '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.5.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{member} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $oid_memberTableEntry },
            { oid => $mapping_member_table->{stackMemberSerialNum}->{oid} },
            { oid => $mapping_member_table->{stackMemberRoleStatus}->{oid} },
            { oid => $mapping_member_table->{stackMemberState}->{oid} }
            ,
            { oid => $oid_portTableEntry },
            { oid => $mapping_port_table->{stackPortAdminStatus}->{oid} },
            { oid => $mapping_port_table->{stackPortOperStatus}->{oid} },
            ,
        ],
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result->{$oid_memberTableEntry}}) {
        next if ($oid !~ /^$mapping_member_table->{stackMemberRoleStatus}->{oid}\.(.*)$/);
        my $instance_id = $1;
        my $result = $options{snmp}->map_instance(
            mapping  => $mapping_member_table,
            results  => $snmp_result->{$oid_memberTableEntry},
            instance => $instance_id);

        $self->{member}->{$result->{stackMemberSerialNum}} = {
            display => $result->{stackMemberSerialNum},
            global  => {
                display => $result->{stackMemberSerialNum},
                role    => $result->{stackMemberRoleStatus},
                state   => $result->{stackMemberState},
            },
            port    => {},
        };

        foreach (keys %{$snmp_result->{$oid_portTableEntry}}) {
            next if (!/^$mapping_port_table->{stackPortOperStatus}->{oid}\.$instance_id\.(.*?)\.(.*)$/);
            my $port_name = $1;
            my $result2 = $options{snmp}->map_instance(
                mapping  => $mapping_port_table,
                results  => $snmp_result->{$oid_portTableEntry},
                instance => $instance_id . '.' . $port_name . '.1');

            $self->{member}->{$result->{stackMemberSerialNum}}->{port}->{$port_name} = {
                display      => $port_name,
                admin_status => $result2->{stackPortAdminStatus},
                oper_status  => $result2->{stackPortOperStatus},
            };
        }
    }

    $self->{cache_name} = "aruba_aoscx_" . $self->{mode} . '_' . $options{snmp}->get_hostname() . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ?
            md5_hex($self->{option_results}->{filter_counters}) :
            md5_hex('all'));
}

1;

__END__

=head1 MODE

Check stack members.

=over 8

=item B<--unknown-member-status>

Define the conditions to match for the status to be UNKNOWN (Default: '').
You can use the following variables: %{role}, %{roleLast}, %{state}, %{stateLast}

=item B<--warning-member-status>

Define the conditions to match for the status to be WARNING (Default: '').
You can use the following variables: %{role}, %{roleLast}, %{state}, %{stateLast}

=item B<--critical-member-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{role} ne %{roleLast}').
You can use the following variables: %{role}, %{roleLast}, %{state}, %{stateLast}

=item B<--unknown-port-status>

Define the conditions to match for the status to be UNKNOWN (Default: '').
You can use the following variables: %{admin_status}, %{oper_status}, %{display}

=item B<--warning-port-status>

Define the conditions to match for the status to be WARNING (Default: '').
You can use the following variables: %{admin_status}, %{oper_status}, %{display}

=item B<--critical-port-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{admin_status} eq "up"  and %{oper_status} ne "up"').
You can use the following variables: %{admin_status}, %{oper_status}, %{display}

=back

=cut
