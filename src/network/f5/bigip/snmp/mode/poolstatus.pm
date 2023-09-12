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

package network::f5::bigip::snmp::mode::poolstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [state: %s] [reason: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{state},
        $self->{result_values}->{reason}
    );
}

sub pool_long_output {
    my ($self, %options) = @_;

    return "checking pool '" . $options{instance_value}->{display} . "'";
}

sub prefix_pool_output {
    my ($self, %options) = @_;

    return "Pool '" . $options{instance_value}->{display} . "' ";
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return sprintf(
        "member node '%s' [port: %s] ",
        $options{instance_value}->{nodeName},
        $options{instance_value}->{port}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pools', type => 3, cb_prefix_output => 'prefix_pool_output', cb_long_output => 'pool_long_output', indent_long_output => '    ', message_multiple => 'All pools are ok',
            group => [
                { name => 'pool_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'pool_connections', type => 0, skipped_code => { -10 => 1 } },
                { name => 'members', display_long => 1, cb_prefix_output => 'prefix_member_output', message_multiple => 'members are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{pool_status} = [
        {
            label => 'status',
            type => 2,
            warning_default => '%{membersAllDisabled} eq "no" and %{state} eq "enabled" and %{status} eq "yellow"',
            critical_default => '%{membersAllDisabled} eq "no" and %{state} eq "enabled" and %{status} eq "red"',  
            set => {
                key_values => [
                    { name => 'state' }, { name => 'status' }, { name => 'membersAllDisabled' },
                    { name => 'reason' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{pool_connections} = [
        { label => 'current-server-connections', nlabel => 'pool.connections.server.count', set => {
                key_values => [ { name => 'ltmPoolStatServerCurConns' }, { name => 'display' } ],
                output_template => 'current server connections: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'current-active-members', nlabel => 'pool.members.active.count', set => {
                key_values => [ { name => 'ltmPoolActiveMemberCnt' }, { name => 'display' } ],
                output_template => 'current active members: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'current-total-members', display_ok => 0, nlabel => 'pool.members.total.count', set => {
                key_values => [ { name => 'ltmPoolMemberCnt' }, { name => 'display' } ],
                output_template => 'current total members: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{members} = [
        {
            label => 'member-status',
            type => 2, 
            set => {
                key_values => [
                    { name => 'state' }, { name => 'status' }, { name => 'reason' },
                    { name => 'poolName' }, { name => 'nodeName' }
                ],
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
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

my $map_pool_status = {
    0 => 'none', 1 => 'green',
    2 => 'yellow', 3 => 'red',
    4 => 'blue', 5 => 'gray',
};
my $map_pool_enabled = {
    0 => 'none', 1 => 'enabled', 2 => 'disabled', 3 => 'disabledbyparent',
};

# New OIDS
my $mapping = {
    new => {
        status => { oid => '.1.3.6.1.4.1.3375.2.2.5.5.2.1.2', map => $map_pool_status }, # AvailState
        state => { oid => '.1.3.6.1.4.1.3375.2.2.5.5.2.1.3', map => $map_pool_enabled }, # EnabledState
        reason => { oid => '.1.3.6.1.4.1.3375.2.2.5.5.2.1.5' } # StatusReason
    },
    old => {
        status => { oid => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.18', map => $map_pool_status }, # AvailState
        state => { oid => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.19', map => $map_pool_enabled }, # EnabledState
        reason => { oid => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.21' } # StatusReason
    }
};
my $mapping_members = {
    new => {
        state => { oid => '.1.3.6.1.4.1.3375.2.2.5.6.2.1.6', map => $map_pool_enabled }, # ltmPoolMbrStatusEnabledState
        reason => { oid => '.1.3.6.1.4.1.3375.2.2.5.6.2.1.8' } # ltmPoolMbrStatusDetailReason
    },
    old => {
        state => { oid => '.1.3.6.1.4.1.3375.2.2.5.3.2.1.16', map => $map_pool_enabled }, # ltmPoolMemberEnabledState
        reason => { oid => '.1.3.6.1.4.1.3375.2.2.5.3.2.1.18' } # ltmPoolMemberStatusReason
    }
};
my $mapping2 = {
    ltmPoolStatServerCurConns => { oid => '.1.3.6.1.4.1.3375.2.2.5.2.3.1.8' },
    ltmPoolActiveMemberCnt    => { oid => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.8' },
    ltmPoolMemberCnt          => { oid => '.1.3.6.1.4.1.3375.2.2.5.1.2.1.23' }
};

sub add_members {
    my ($self, %options) = @_;

    my $oid_status = $options{map} eq 'new' ? '.1.3.6.1.4.1.3375.2.2.5.6.2.1.5' : '.1.3.6.1.4.1.3375.2.2.5.3.2.1.15';
    my $snmp_result = $options{snmp}->get_table(oid => $oid_status);

    my $loaded = 0;
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_status\.(.*)$/;
        my $instance = $1;
        my @indexes = split(/\./, $1);

        my $num = shift(@indexes);
        my $poolInstance = $num . '.' . join('.', splice(@indexes, 0, $num));
        my $nodeName = $self->{output}->decode(join('', map(chr($_), splice(@indexes, 0, shift(@indexes)) )));
        my $port = $indexes[0];

        next if (!defined($self->{pools}->{$poolInstance}));

        $loaded = 1;
        $options{snmp}->load(
            oids => [ map($_->{oid}, values(%{$mapping_members->{ $options{map} }})) ], 
            instances => [$instance], 
            instance_regexp => '^(.*)$'
        );

        $self->{pools}->{$poolInstance}->{members}->{$instance} = {
            poolName => $self->{pools}->{$poolInstance}->{display},
            nodeName => $nodeName,
            port => $port,
            status => $map_pool_status->{ $snmp_result->{$oid} }
        };
    }

    return if ($loaded == 0);

    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %$snmp_result) {
        next if (! /^$mapping_members->{ $options{map} }->{state}->{oid}\.(.*)$/);
        my $instance = $1;
        my @indexes = split(/\./, $1);

        my $num = shift(@indexes);
        my $poolInstance = $num . '.' . join('.', splice(@indexes, 0, $num));

        my $result = $options{snmp}->map_instance(mapping => $mapping_members->{ $options{map} }, results => $snmp_result, instance => $instance);
        $result->{reason} = '-' if (!defined($result->{reason}) || $result->{reason} eq '');

        if ($result->{state} !~ /disabled/) {
            $self->{pools}->{$poolInstance}->{pool_status}->{membersAllDisabled} = 'no';
        }

        $self->{pools}->{$poolInstance}->{members}->{$instance}->{state} = $result->{state};
        $self->{pools}->{$poolInstance}->{members}->{$instance}->{reason} = $result->{reason};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($branch_name, $map) = ($mapping->{new}->{status}->{oid}, 'new');
    my $snmp_result = $options{snmp}->get_table(oid => $mapping->{new}->{status}->{oid} );

    if (scalar(keys %$snmp_result) == 0)  {
        ($branch_name, $map) = ($mapping->{old}->{status}->{oid}, 'old');
        $snmp_result = $options{snmp}->get_table(
            oid => $mapping->{old}->{status}->{oid},
            nothing_quit => 1
        );
    }

    $self->{pools} = {};
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$branch_name\.(.*?)\.(.*)$/;
        my ($num, $index) = ($1, $2);

        my $result = $options{snmp}->map_instance(mapping => $mapping->{$map}, results => $snmp_result, instance => $num . '.' . $index);
        my $name = $self->{output}->decode(join('', map(chr($_), split(/\./, $index))));

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping pool '" . $name . "'.", debug => 1);
            next;
        }

        $self->{pools}->{$num . '.' . $index} = {
            display => $name,
            pool_status => {
                display => $name,
                status => $result->{status},
                membersAllDisabled => 'yes'
            },
            members => {}
        };
    }

    if (scalar(keys %{$self->{pools}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No pool found');
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [
            $mapping->{$map}->{state}->{oid},
            $mapping->{$map}->{reason}->{oid},
            $mapping2->{ltmPoolStatServerCurConns}->{oid},
            $mapping2->{ltmPoolActiveMemberCnt}->{oid},
            $mapping2->{ltmPoolMemberCnt}->{oid},
        ], 
        instances => [keys %{$self->{pools}}], 
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{pools}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$map}, results => $snmp_result, instance => $_);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);

        $result->{reason} = '-' if (!defined($result->{reason}) || $result->{reason} eq '');
        $self->{pools}->{$_}->{pool_status}->{reason} = $result->{reason};
        $self->{pools}->{$_}->{pool_status}->{state} = $result->{state};
        $self->{pools}->{$_}->{pool_connections} = {
            display => $self->{pools}->{$_}->{display},
            ltmPoolStatServerCurConns => $result2->{ltmPoolStatServerCurConns},
            ltmPoolActiveMemberCnt => $result2->{ltmPoolActiveMemberCnt},
            ltmPoolMemberCnt => $result2->{ltmPoolMemberCnt}
        };
    }

    $self->add_members(snmp => $options{snmp}, map => $map);
}

1;

__END__

=head1 MODE

Check pools.

=over 8

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{status}, %{membersAllDisabled}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (Default: '%{membersAllDisabled} eq "no" and %{state} eq "enabled" and %{status} eq "yellow"').
You can use the following variables: %{state}, %{status}, %{membersAllDisabled}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{membersAllDisabled} eq "no" and %{state} eq "enabled" and %{status} eq "red"').
You can use the following variables: %{state}, %{status}, %{membersAllDisabled}, %{display}

=item B<--unknown-member-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{status}, %{poolName}, %{nodeName}

=item B<--warning-member-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{status}, %{poolName}, %{nodeName}

=item B<--critical-member-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{status}, %{poolName}, %{nodeName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'current-server-connections', 'current-active-members', 'current-total-members'.

=back

=cut
