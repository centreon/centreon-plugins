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

package network::hp::procurve::snmp::mode::virtualchassis;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'virtual chassis operational status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'state: %s',
        $self->{result_values}->{state}
    );
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

    return sprintf(
        'operational status: %s',
        $self->{result_values}->{link_status}
    );
}

sub custom_memory_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "memory usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
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

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'member', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All stack members are ok',
            group => [
                { name => 'member_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'link', display_long => 1, cb_prefix_output => 'prefix_link_output',  message_multiple => 'All links are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /active/i', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'members-total', nlabel => 'stack.members.total.count', set => {
                key_values => [ { name => 'members' } ],
                output_template => 'total members: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{member_global} = [
        { label => 'member-status', type => 2, critical_default => '%{state} ne %{stateLast} || %{state} =~ /communicationFailure|incompatibleOS/i', set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu-utilization', nlabel => 'member.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display'} ],
                output_template => 'cpu usage: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, 
                      label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage', nlabel => 'member.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'member.memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'member.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'memory used : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{link} = [
        { label => 'link-status', type => 2, critical_default => '%{link_status} eq "down"', set => {
                key_values => [ { name => 'link_status' }, { name => 'display' }, { name => 'member_serial' } ],
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-member-serial:s" => { name => 'filter_member_serial' }
    });

    return $self;
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
    hpicfVsfVCAdminStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.1.3', map => $mapping_admin_status }
};
my $mapping2 = {
    hpicfVsfVCMemberState       => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.9', map => $mapping_member_state },
    hpicfVsfVCMemberSerialNum   => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.14' },  
    hpicfVsfVCMemberCpuUtil     => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.19' },
    hpicfVsfVCMemberTotalMemory => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.20' },
    hpicfVsfVCMemberFreeMemory  => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.3.1.21' }
};
my $mapping3 = {
    hpicfVsfVCLinkName       => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.4.1.3' },
    hpicfVsfVCLinkOperStatus => { oid => '.1.3.6.1.4.1.11.2.14.11.5.1.116.1.4.1.4', map => $mapping_link_status }
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
            { oid => $oid_hpicfVsfVCLinkEntry, start => $mapping3->{hpicfVsfVCLinkName}->{oid}, end => $mapping3->{hpicfVsfVCLinkOperStatus}->{oid} }
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
        next if (defined($self->{option_results}->{filter_member_serial}) && $self->{option_results}->{filter_member_serial} ne '' &&
            $member_name !~ /$self->{option_results}->{filter_member_serial}/);

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
            link => {}
        };

        foreach (keys %{$snmp_result->{$oid_hpicfVsfVCLinkEntry}}) {
            next if (!/^$mapping3->{hpicfVsfVCLinkName}->{oid}\.$member_id\.(.*)$/);
            $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_hpicfVsfVCLinkEntry}, instance => $member_id . '.' . $1);

            $self->{member}->{$member_name}->{link}->{$result->{hpicfVsfVCLinkName}} = {
                member_serial => $member_name,
                display => $result->{hpicfVsfVCLinkName},
                link_status => $result->{hpicfVsfVCLinkOperStatus}
            };
        }
    }

    $self->{global}->{members} = scalar(keys %{$self->{member}});

    $self->{cache_name} = 'hp_procurve_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        md5_hex(
            (defined($self->{option_results}->{filter_counters}) ? $self->{option_results}->{filter_counters} : 'all') . '_' .
            (defined($self->{option_results}->{filter_member_serial}) ? $self->{option_results}->{filter_member_serial} : 'all')
        );
}

1;

__END__

=head1 MODE

Check vsf virtual chassis.

=over 8

=item B<--filter-member-serial>

Filter members by serial (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /active/i').
You can use the following variables: %{status}

=item B<--unknown-member-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{stateLast}

=item B<--warning-member-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{stateLast}

=item B<--critical-member-status>

Define the conditions to match for the status to be CRITICAL (default: '%{state} ne %{stateLast} || %{state} =~ /communicationFailure|incompatibleOS/i').
You can use the following variables: %{state}, %{stateLast}

=item B<--unknown-link-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{link_status}, %{display}

=item B<--warning-link-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{link_status}, %{display}

=item B<--critical-link-status>

Define the conditions to match for the status to be CRITICAL (default: '%{link_status} eq "down"').
You can use the following variables: %{link_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-total', 'memory-usage-prct', 'memory-usage', 'memory-usage-free',
'cpu-utilization'.

=back

=cut
