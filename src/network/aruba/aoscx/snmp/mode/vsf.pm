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

package network::aruba::aoscx::snmp::mode::vsf;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'vsf operational status: %s',
        $self->{result_values}->{status}
    );
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'role: %s [status: %s]',
        $self->{result_values}->{role},
        $self->{result_values}->{status}
    );
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{id} = $options{new_datas}->{$self->{instance} . '_id'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub member_long_output {
    my ($self, %options) = @_;

    return "checking stack member '" . $options{instance_value}->{id} . "'";
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "stack member '" . $options{instance_value}->{id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'members', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All stack members are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /no_split/i', set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'members-total', nlabel => 'stack.members.total.count', display_ok => '0', set => {
                key_values => [ { name => 'members'} ],
                output_template => 'total members: %s',
                perfdatas => [
                    { value => 'members', template => '%s', min => 0 },
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        { label => 'member-status', type => 2, critical_default => '%{role} ne %{roleLast} || %{status} !~ /ready|booting/i', set => {
                key_values => [ { name => 'role' }, { name => 'status' }, { name => 'id' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-utilization', nlabel => 'member.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_util' } ],
                output_template => 'cpu usage: %.2f%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage-prct', nlabel => 'member.memory.usage.percentage', set => {
                key_values => [ { name => 'mem_used' } ],
                output_template => 'memory used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $mapping_member = {
    vsf => {
        status   => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.10.0.3.1.3' }, # arubaWiredVsfMemberStatus
        cpu_util => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.10.0.3.1.9' }, # arubaWiredVsfMemberCpuUtil
        mem_used => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.10.0.3.1.10' } # arubaWiredVsfMemberMemoryUtil
    },
    vsfv2 => {
        status   => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.15.1.2.1.3' }, # arubaWiredVsfv2MemberStatus
        cpu_util => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.15.1.2.1.9' }, # arubaWiredVsfv2MemberCpuUtil
        mem_used => { oid => '.1.3.6.1.4.1.47196.4.1.1.3.15.1.2.1.10' } # arubaWiredVsfv2MemberMemoryUtil
    }
};
my $branches = {
    vsf => {
        stack_status => '.1.3.6.1.4.1.47196.4.1.1.3.10.0.2.1', # arubaWiredVsfOperStatus
        member_role => '.1.3.6.1.4.1.47196.4.1.1.3.10.0.3.1.2' # arubaWiredVsfMemberRole 
    },
    vsfv2 => {
        stack_status => '.1.3.6.1.4.1.47196.4.1.1.3.15.1.1.1', # arubaWiredVsfv2OperStatus
        member_role => '.1.3.6.1.4.1.47196.4.1.1.3.15.1.2.1.2' # arubaWiredVsfv2MemberRole 
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'aruba_aoscx_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $branches->{vsf}->{stack_status} },
            { oid => $branches->{vsf}->{member_role} },
            { oid => $branches->{vsfv2}->{stack_status} },
            { oid => $branches->{vsfv2}->{member_role} }
        ],
        nothing_quit => 1
    );

    my $branch = 'vsf';
    if (defined($snmp_result->{ $branches->{vsfv2}->{stack_status} }) && scalar(keys %{$snmp_result->{ $branches->{vsfv2}->{stack_status} }}) > 0) {
        $branch = 'vsfv2';
    }

    $self->{global} = { status => $snmp_result->{ $branches->{$branch}->{stack_status} }->{ $branches->{$branch}->{stack_status} . '.0' } };
    $self->{members} = {};
    foreach (keys %{$snmp_result->{ $branches->{$branch}->{member_role} }}) {
        /\.(\d+)$/;
        my $number = $1;
        $self->{members}->{$number} = {
            id => $number,
            status => { id => $number, role => $snmp_result->{ $branches->{$branch}->{member_role} }->{$_} },
        };
    }

    return if (scalar(keys %{$self->{members}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%{$mapping_member->{$branch}})) ],
        instances => [ keys %{$self->{members}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{members}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping_member->{$branch}, results => $snmp_result, instance => $_);

        $self->{members}->{$_}->{status}->{status} = $result->{status};
        $self->{members}->{$_}->{cpu}->{cpu_util} = $result->{cpu_util};
        $self->{members}->{$_}->{memory}->{mem_used} = $result->{mem_used};
    }

}

1;

__END__

=head1 MODE

Check vsf virtual chassis.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /no_split/i').
You can use the following variables: %{status}

=item B<--unknown-member-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{role}, %{roleLast}, %{id}

=item B<--warning-member-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{role}, %{roleLast}, %{id}

=item B<--critical-member-status>

Define the conditions to match for the status to be CRITICAL (default: '%{role} ne %{roleLast} || %{status} !~ /ready|booting/i').
You can use the following variables: %{status}, %{role}, %{roleLast}, %{id}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-total', 'memory-usage-prct', 'cpu-utilization'.

=back

=cut
