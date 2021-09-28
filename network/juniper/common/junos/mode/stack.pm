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

package network::juniper::common::junos::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_member_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'role: %s',
        $self->{result_values}->{role}
    );
    return $msg;
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
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
        { name => 'member', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All stack members are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'port', display_long => 1, cb_prefix_output => 'prefix_port_output',  message_multiple => 'All ports are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'member-status', threshold => 0, set => {
                key_values => [ { name => 'role' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];

    $self->{maps_counters}->{port} = [
        { label => 'port-status',  threshold => 0, set => {
                key_values => [ { name => 'oper_status' }, { name => 'admin_status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_port_status_output'),
                closure_custom_perfdata => sub { return 0; },
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
        'critical-port-status:s'   => { name => 'critical_port_status', default => '%{admin_status} eq "up"  and %{oper_status} ne "up"' },
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

my $map_role = { 1 => 'master', 2 => 'backup', 3 => 'linecard' };
my $map_status = { 1 => 'up', 2 => 'down', 3 => 'unknown' };

my $mapping = {
    jnxVirtualChassisMemberSerialnumber => { oid => '.1.3.6.1.4.1.2636.3.40.1.4.1.1.1.2' },
    jnxVirtualChassisMemberRole         => { oid => '.1.3.6.1.4.1.2636.3.40.1.4.1.1.1.3', map => $map_role },
};
my $mapping2 = {
    jnxVirtualChassisPortAdminStatus => { oid => '.1.3.6.1.4.1.2636.3.40.1.4.1.2.1.3', map => $map_status },
    jnxVirtualChassisPortOperStatus  => { oid => '.1.3.6.1.4.1.2636.3.40.1.4.1.2.1.4', map => $map_status },
};
my $oid_jnxVirtualChassisMemberEntry = '.1.3.6.1.4.1.2636.3.40.1.4.1.1.1';
my $oid_jnxVirtualChassisPortEntry = '.1.3.6.1.4.1.2636.3.40.1.4.1.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{member} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_jnxVirtualChassisMemberEntry, start => $mapping->{jnxVirtualChassisMemberSerialnumber}->{oid}, end => $mapping->{jnxVirtualChassisMemberRole}->{oid} },
            { oid => $oid_jnxVirtualChassisPortEntry, start => $mapping2->{jnxVirtualChassisPortAdminStatus}->{oid}, end => $mapping2->{jnxVirtualChassisPortOperStatus}->{oid} },
        ],
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result->{$oid_jnxVirtualChassisMemberEntry}}) {
        next if ($oid !~ /^$mapping->{jnxVirtualChassisMemberRole}->{oid}\.(.*)$/);
        my $chassis_id = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_jnxVirtualChassisMemberEntry}, instance => $chassis_id);

        $self->{member}->{$result->{jnxVirtualChassisMemberSerialnumber}} = {
            display => $result->{jnxVirtualChassisMemberSerialnumber}, 
            global => {
                display => $result->{jnxVirtualChassisMemberSerialnumber},
                role => $result->{jnxVirtualChassisMemberRole},
            },
            port => {},
        };

         foreach (keys %{$snmp_result->{$oid_jnxVirtualChassisPortEntry}}) {
            next if (!/^$mapping2->{jnxVirtualChassisPortAdminStatus}->{oid}\.$chassis_id\.(.*?)\.(.*)$/);
            my $port_name = $2;
            my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_jnxVirtualChassisPortEntry}, instance => $chassis_id . '.' . $1 . '.' . $port_name);

            $port_name = $self->{output}->decode(join('', map(chr($_), split(/\./, $port_name))));
            $self->{member}->{$result->{jnxVirtualChassisMemberSerialnumber}}->{port}->{$port_name} = {
                display => $port_name,
                admin_status => $result2->{jnxVirtualChassisPortAdminStatus},
                oper_status => $result2->{jnxVirtualChassisPortOperStatus},
            };
        }
    }

    $self->{cache_name} = "juniper_junos_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check stack members.

=over 8

=item B<--unknown-member-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{role}, %{roleLast}

=item B<--warning-member-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{role}, %{roleLast}

=item B<--critical-member-status>

Set critical threshold for status (Default: '%{role} ne %{roleLast}').
Can used special variables like: %{role}, %{roleLast}

=item B<--unknown-port-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{admin_status}, %{oper_status}, %{display}

=item B<--warning-port-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{admin_status}, %{oper_status}, %{display}

=item B<--critical-port-status>

Set critical threshold for status (Default: '%{admin_status} eq "up"  and %{oper_status} ne "up"').
Can used special variables like: %{admin_status}, %{oper_status}, %{display}

=back

=cut
