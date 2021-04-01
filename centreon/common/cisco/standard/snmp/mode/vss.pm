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

package centreon::common::cisco::standard::snmp::mode::vss;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'virtual switching system mode: %s',
        $self->{result_values}->{mode}
    );
}

sub custom_member_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'role: %s',
        $self->{result_values}->{role}
    );
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{role_last} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
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

sub member_long_output {
    my ($self, %options) = @_;

    return "checking member '" . $options{instance_value}->{switch_id} . "'";
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "Member '" . $options{instance_value}->{switch_id} . "' ";
}

sub prefix_vsl_output {
    my ($self, %options) = @_;

    return "virtual switch link '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'member', type => 3, cb_prefix_output => 'prefix_member_output', cb_long_output => 'member_long_output', indent_long_output => '    ', message_multiple => 'All members are ok',
            group => [
                { name => 'member_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'vsl', display_long => 1, cb_prefix_output => 'prefix_vsl_output',  message_multiple => 'All virtual switch links are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'mode' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'members-total', nlabel => 'vss.members.total.count', display_ok => 0, set => {
                key_values => [ { name => 'members'} ],
                output_template => 'total members: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{member_global} = [
        { label => 'member-status', threshold => 0, set => {
                key_values => [ { name => 'role' }, { name => 'switch_id' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        }
    ];

    $self->{maps_counters}->{vsl} = [
        { label => 'link-status',  threshold => 0, set => {
                key_values => [ { name => 'link_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_link_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'vsl-ports-operational', nlabel => 'vsl.ports.operational.count', display_ok => 0, set => {
                key_values => [ { name => 'operational_ports'}, { name => 'display' } ],
                output_template => 'operational ports: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
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
        'unknown-status:s'         => { name => 'unknown_status', default => '' },
        'warning-status:s'         => { name => 'warning_status', default => '' },
        'critical-status:s'        => { name => 'critical_status', default => '' },
        'unknown-member-status:s'  => { name => 'unknown_member_status', default => '' },
        'warning-member-status:s'  => { name => 'warning_member_status', default => '' },
        'critical-member-status:s' => { name => 'critical_member_status', default => '%{role} ne %{role_last}' },
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

my $mapping_vss_role = {
    1 => 'standalone', 2 => 'active', 3 => 'standby'
};
my $mapping_vss_mode = {
    1 => 'standalone', 2 => 'multiNode'
};
my $mapping_vsl_connect_status = {
    1 => 'up', 2 => 'down'
};

my $mapping = {
    cvsSwitchMode => { oid => '.1.3.6.1.4.1.9.9.388.1.1.4', map => $mapping_vss_mode }
};
my $mapping2 = {
    cvsChassisSwitchID => { oid => '.1.3.6.1.4.1.9.9.388.1.2.2.1.1' },
    cvsChassisRole     => { oid => '.1.3.6.1.4.1.9.9.388.1.2.2.1.2', map => $mapping_vss_role }
};
my $mapping3 = {
    cvsVSLCoreSwitchID         => { oid => '.1.3.6.1.4.1.9.9.388.1.3.1.1.2' },
    cvsVSLConnectOperStatus    => { oid => '.1.3.6.1.4.1.9.9.388.1.3.1.1.3', map => $mapping_vsl_connect_status },
    cvsVSLOperationalPortCount => { oid => '.1.3.6.1.4.1.9.9.388.1.3.1.1.6' }
};
my $oid_cvsGlobalObjects = '.1.3.6.1.4.1.9.9.388.1.1';
my $oid_cvsChassisEntry = '.1.3.6.1.4.1.9.9.388.1.2.2.1';
my $oid_cvsVSLConnectionEntry = '.1.3.6.1.4.1.9.9.388.1.3.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_cvsGlobalObjects, start => $mapping->{cvsSwitchMode}->{oid} },
            { oid => $oid_cvsChassisEntry, end => $mapping2->{cvsChassisRole}->{oid} },
            { oid => $oid_cvsVSLConnectionEntry, start => $mapping3->{cvsVSLCoreSwitchID}->{oid}, end => $mapping3->{cvsVSLOperationalPortCount}->{oid} }
        ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_cvsGlobalObjects}, instance => '0');
    $self->{global} = { mode => $result->{cvsSwitchMode} };

    $self->{member} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_cvsChassisEntry}}) {
        next if ($oid !~ /^$mapping2->{cvsChassisSwitchID}->{oid}\.(.*)$/);
        $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_cvsChassisEntry}, instance => $1);
        my $switch_id = $result->{cvsChassisSwitchID};

        $self->{member}->{$switch_id} = {
            switch_id => $switch_id,
            member_global => {
                switch_id => $switch_id,
                role => $result->{cvsChassisRole}
            },
            vsl => {},
        };

        foreach (keys %{$snmp_result->{$oid_cvsVSLConnectionEntry}}) {
            next if (!/^$mapping3->{cvsVSLCoreSwitchID}->{oid}\.(.*)/);
            my $if_index = $1;
            $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_cvsVSLConnectionEntry}, instance => $if_index);
            next if ($result->{cvsVSLCoreSwitchID} != $switch_id);

            $self->{member}->{$switch_id}->{vsl}->{$if_index} = {
                display => $if_index,
                link_status => $result->{cvsVSLConnectOperStatus},
                operational_ports => $result->{cvsVSLOperationalPortCount}
            };
        }
    }

    $self->{global}->{members} = scalar(keys %{$self->{member}});

    $self->{cache_name} = 'cisco_standard_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual switching system.

=over 8

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{mode}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{mode}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{mode}

=item B<--unknown-member-status>

Set unknown threshold for status.
Can used special variables like: %{role}, %{role_last}, %{switch_id}

=item B<--warning-member-status>

Set warning threshold for status.
Can used special variables like: %{role}, %{role_last}, %{switch_id}

=item B<--critical-member-status>

Set critical threshold for status (Default: '%{role} ne %{role_last}').
Can used special variables like: %{role}, %{role_last}, %{switch_id}

=item B<--unknown-link-status>

Set unknown threshold for status.
Can used special variables like: %{link_status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status.
Can used special variables like: %{link_status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{link_status} eq "down"').
Can used special variables like: %{link_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-total', 'vsl-ports-operational'.
=back

=cut
