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

package network::extreme::snmp::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_member_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'status: %s [role: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{role}
    );
    return $msg;
}

sub custom_member_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
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
        'operational status: %s',
        $self->{result_values}->{link_status}
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
                key_values => [ { name => 'role' }, { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];

    $self->{maps_counters}->{port} = [
        { label => 'port-status',  threshold => 0, set => {
                key_values => [ { name => 'link_status' }, { name => 'display' } ],
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
        'warning-member-status:s'  => { name => 'warning_member_status', default => '%{status} eq "mismatch"' },
        'critical-member-status:s' => { name => 'critical_member_status', default => '%{role} ne %{roleLast} || %{status} eq "down"' },
        'unknown-port-status:s'    => { name => 'unknown_port_status', default => '' },
        'warning-port-status:s'    => { name => 'warning_port_status', default => '' },
        'critical-port-status:s'   => { name => 'critical_port_status', default => '%{link_status} ne "up"' },
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

my $mapping_truth = {
    0 => 'disabled', 1 => 'enable', 2 => 'disable',
};
my $mapping_stack_status = {
    1 => 'up', 2 => 'down', 3 => 'mismatch',
};
my $mapping_stack_role = {
    1 => 'master', 2 => 'slave', 3 => 'backup',
};
my $mapping_link_status = {
    1 => 'up', 2 => 'down',
};

my $mapping = {
    extremeStackDetection => { oid => '.1.3.6.1.4.1.1916.1.33.1', map => $mapping_truth },  
};
my $mapping2 = {
    extremeStackMemberOperStatus => { oid => '.1.3.6.1.4.1.1916.1.33.2.1.3', map => $mapping_stack_status },
    extremeStackMemberRole       => { oid => '.1.3.6.1.4.1.1916.1.33.2.1.4', map => $mapping_stack_role },  
    extremeStackMemberMACAddress => { oid => '.1.3.6.1.4.1.1916.1.33.2.1.6' },
};
my $mapping3 = {
    extremeStackingPortRemoteMac  => { oid => '.1.3.6.1.4.1.1916.1.33.3.1.2' },
    extremeStackingPortLinkStatus => { oid => '.1.3.6.1.4.1.1916.1.33.3.1.4', map => $mapping_link_status },  
};
my $oid_extremeStackMemberEntry = '.1.3.6.1.4.1.1916.1.33.2.1';
my $oid_extremeStackingPortEntry = '.1.3.6.1.4.1.1916.1.33.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{extremeStackDetection}->{oid} },
            { oid => $oid_extremeStackMemberEntry, start => $mapping2->{extremeStackMemberOperStatus}->{oid}, end => $mapping2->{extremeStackMemberMACAddress}->{oid} },
            { oid => $oid_extremeStackingPortEntry, start => $mapping3->{extremeStackingPortRemoteMac}->{oid} },
        ],
        nothing_quit => 1
    );
    
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$mapping->{extremeStackDetection}->{oid}}, instance => '0');
    # disable is voluntary
    if ($result->{extremeStackDetection} eq 'disable') {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'Stacking is disable'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    foreach my $oid (keys %{$snmp_result->{$oid_extremeStackMemberEntry}}) {
        next if ($oid !~ /^$mapping2->{extremeStackMemberOperStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_extremeStackMemberEntry}, instance => $instance);

        my $member_name = defined($result->{extremeStackMemberMACAddress}) && $result->{extremeStackMemberMACAddress} ne '' ? 
            join(":", unpack("(H2)*", $result->{extremeStackMemberMACAddress})) : 
            $instance;
        $self->{member}->{$member_name} = {
            display => $member_name,
            global => {
                display => $member_name,
                role => $result->{extremeStackMemberRole},
                status => $result->{extremeStackMemberOperStatus},
            },
            port => {},
        };

        foreach (keys %{$snmp_result->{$oid_extremeStackingPortEntry}}) {
            next if (!/^$mapping3->{extremeStackingPortRemoteMac}->{oid}\.(.*)$/);
            $instance = $1;
            $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_extremeStackingPortEntry}, instance => $instance);
            my $member_mac = join(":", unpack("(H2)*", $result->{extremeStackingPortRemoteMac}));
            next if (!defined($self->{member}->{$member_mac}));

            $self->{member}->{$member_mac}->{port}->{$instance} = {
                display => $instance,
                link_status => $result->{extremeStackingPortLinkStatus},
            };
        }
    }

    $self->{cache_name} = 'extreme_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check stack status.

=over 8

=item B<--unknown-member-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{role}, %{roleLast}

=item B<--warning-member-status>

Set warning threshold for status (Default: '%{status} eq "mismatch"').
Can used special variables like: %{role}, %{roleLast}

=item B<--critical-member-status>

Set critical threshold for status (Default: '%{role} ne %{roleLast} || %{status} eq "down"').
Can used special variables like: %{role}, %{roleLast}

=item B<--unknown-port-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{link_status}, %{display}

=item B<--warning-port-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{link_status}, %{display}

=item B<--critical-port-status>

Set critical threshold for status (Default: '%{link_status} ne "up"').
Can used special variables like: %{link_status}, %{display}

=back

=cut
    
