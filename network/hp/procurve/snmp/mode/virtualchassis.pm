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

package network::hp::procurve::snmp::mode::virtualchassis;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'virtual chassis operational status: %s',
        $self->{result_values}->{status}
    );
    return $msg;
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
    return $msg;
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{stateLast} = $options{old_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    if (!defined($options{old_datas}->{$self->{instance} . '_state'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub custom_link_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'operational status: %s',
        $self->{result_values}->{link_status}
    );
    return $msg;
}

sub custom_memory_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("memory usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'member', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All stack members are ok',
            group => [
                { name => 'member_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'link', display_long => 1, cb_prefix_output => 'prefix_link_output',  message_multiple => 'All links are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'members-total', nlabel => 'stack.members.total.count', set => {
                key_values => [ { name => 'members'} ],
                output_template => 'total members: %s',
                perfdatas => [
                    { value => 'members', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{member_global} = [
        { label => 'member-status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'cpu-utilization', nlabel => 'member.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu'}, { name => 'display'} ],
                output_template => 'cpu usage: %.2f%%',
                perfdatas => [
                    { value => 'cpu', template => '%.2f', unit => '%', min => 0, max => 100, 
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'memory-usage', nlabel => 'member.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'member.memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'member.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'memory used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{link} = [
        { label => 'link-status',  threshold => 0, set => {
                key_values => [ { name => 'link_status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_link_status_output'),
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

sub prefix_link_output {
    my ($self, %options) = @_;

    return "link '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'         => { name => 'unknown_status', default => '' },
        'warning-status:s'         => { name => 'warning_status', default => '' },
        'critical-status:s'        => { name => 'critical_status', default => '%{status} !~ /active/i' },
        'unknown-member-status:s'  => { name => 'unknown_member_status', default => '' },
        'warning-member-status:s'  => { name => 'warning_member_status', default => '' },
        'critical-member-status:s' => { name => 'critical_member_status', default => '%{state} ne %{stateLast} || %{state} =~ /communicationFailure|incompatibleOS/i' },
        'unknown-link-status:s'    => { name => 'unknown_link_status', default => '' },
        'warning-link-status:s'    => { name => 'warning_link_status', default => '' },
        'critical-link-status:s'   => { name => 'critical_link_status', default => '%{link_status} eq "down"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'unknown_status', 'warning_status', 'critical_status',
            'unknown_member_status', 'warning_member_status', 'critical_member_status',
            'unknown_link_status', 'warning_link_status', 'critical_link_status'
        ]
    );
}

my $mapping_oper_status = {
    0 => 'unAvailable', 1 => 'disabled', 2 => 'active',
    3 => 'fragmentInactive', 4 => 'fragmentActive'
};
my $mapping_admin_status = {
    1 => 'enable', 2 => 'disabled'
};
my $mapping_member_state = {
    0 => 'unusedId', 1 => 'missing',
    2 => 'provision', 3 => 'commander',
    4 => 'standby', 5 => 'member',
    6 => 'shutdown', 7 => 'booting',
    8 => 'communicationFailure', 9 => 'incompatibleOS',
    10 => 'unknownState', 11 => 'standbyBooting',
};
my $mapping_link_status = {
    1 => 'up', 2 => 'down', 3 => 'disabled',
};

my $mapping = {
    hpicfVsfVCOperStatus  => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.1.2', map => $mapping_oper_status },
    hpicfVsfVCAdminStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.1.3', map => $mapping_admin_status },  
};
my $mapping2 = {
    hpicfVsfVCMemberState       => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.9', map => $mapping_member_state },
    hpicfVsfVCMemberSerialNum   => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.14' },  
    hpicfVsfVCMemberCpuUtil     => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.19' },
    hpicfVsfVCMemberTotalMemory => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.20' },
    hpicfVsfVCMemberFreeMemory  => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.21' },
};
my $mapping3 = {
    hpicfVsfVCLinkName       => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.4.1.3' },
    hpicfVsfVCLinkOperStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.4.1.4', map => $mapping_link_status },  
};
my $oid_hpicfVsfVCConfig = '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.1';
my $oid_hpicfVsfVCMemberEntry = '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1';
my $oid_hpicfVsfVCLinkEntry = '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.4.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_hpicfVsfVCConfig, start => $mapping->{hpicfVsfVCOperStatus}->{oid}, end => $mapping->{hpicfVsfVCAdminStatus}->{oid} },
            { oid => $oid_hpicfVsfVCMemberEntry, start => $mapping2->{hpicfVsfVCMemberState}->{oid} },
            { oid => $oid_hpicfVsfVCLinkEntry, start => $mapping3->{hpicfVsfVCLinkName}->{oid}, end => $mapping3->{hpicfVsfVCLinkOperStatus}->{oid} },
        ],
        nothing_quit => 1
    );
    
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_hpicfVsfVCConfig}, instance => '0');
    if ($result->{hpicfVsfVCAdminStatus} eq 'disable') {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'vsf virtual chassis is disabled'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $self->{global} = { status => $result->{hpicfVsfVCOperStatus} };
    $self->{member} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_hpicfVsfVCMemberEntry}}) {
        next if ($oid !~ /^$mapping2->{hpicfVsfVCMemberState}->{oid}\.(.*)$/);
        my $member_id = $1;
        $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_hpicfVsfVCMemberEntry}, instance => $member_id);

        my $member_name = $result->{hpicfVsfVCMemberSerialNum};
        $self->{member}->{$member_name} = {
            display => $member_name,
            member_global => {
                display => $member_name,
                state => $result->{hpicfVsfVCMemberState},
                cpu => $result->{hpicfVsfVCMemberCpuUtil},
                total => $result->{hpicfVsfVCMemberTotalMemory},
                free => $result->{hpicfVsfVCMemberFreeMemory},
                used => $result->{hpicfVsfVCMemberTotalMemory} - $result->{hpicfVsfVCMemberFreeMemory},
                prct_used => ($result->{hpicfVsfVCMemberTotalMemory} - $result->{hpicfVsfVCMemberFreeMemory}) * 100 / $result->{hpicfVsfVCMemberTotalMemory},
                prct_free => $result->{hpicfVsfVCMemberFreeMemory} * 100 / $result->{hpicfVsfVCMemberTotalMemory}
            },
            link => {},
        };

        foreach (keys %{$snmp_result->{$oid_hpicfVsfVCLinkEntry}}) {
            next if (!/^$mapping3->{hpicfVsfVCLinkName}->{oid}\.$member_id\.(.*)$/);
            $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_hpicfVsfVCLinkEntry}, instance => $member_id . '.' . $1);

            $self->{member}->{$member_name}->{link}->{$result->{hpicfVsfVCLinkName}} = {
                display => $result->{hpicfVsfVCLinkName},
                link_status => $result->{hpicfVsfVCLinkOperStatus},
            };
        }
    }

    $self->{global}->{members} = scalar(keys %{$self->{member}});

    $self->{cache_name} = 'hp_procurve_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check vsf virtual chassis.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /active/i').
Can used special variables like: %{status}

=item B<--unknown-member-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{state}, %{stateLast}

=item B<--warning-member-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{stateLast}

=item B<--critical-member-status>

Set critical threshold for status (Default: '%{state} ne %{stateLast} || %{state} =~ /communicationFailure|incompatibleOS/i').
Can used special variables like: %{state}, %{stateLast}

=item B<--unknown-link-status>

Set unknown threshold for status (Default: '').
Can used special variables like: %{link_status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{link_status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{link_status} eq "down"').
Can used special variables like: %{link_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-total', 'memory-usage-prct', 'memory-usage', 'memory-usage-free',
'cpu-utilization'.

=back

=cut
