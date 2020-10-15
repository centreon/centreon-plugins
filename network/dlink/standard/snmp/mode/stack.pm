#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::dlink::standard::snmp::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

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
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub custom_link_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
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
                { name => 'link', display_long => 1, cb_prefix_output => 'prefix_link_output',  message_multiple => 'All links are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'members-total', nlabel => 'stack.members.total.count', set => {
                key_values => [ { name => 'members'} ],
                output_template => 'Total members: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{member_global} = [
        {
            label => 'member-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /codeUpdate/i',
            critical_default => '%{role} ne %{roleLast} || %{status} =~ /unsupported|codeMismatch/i',
            set => {
                key_values => [ { name => 'role' }, { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_member_status_calc'),
                closure_custom_output => $self->can('custom_member_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{link} = [
        { label => 'link-status', type => 2, critical_default => '%{status} eq "down"', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
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
    });

    return $self;
}

my $mapping_role = {
    1 => 'unknown', 3 => 'standAlone',
    4 => 'master', 5 => 'slave', 6 => 'backupmaster'
};
my $mapping_unit_status = {
    0 => 'unknown', 1 => 'ok', 2 => 'unsupported',
    3 => 'codeMismatch', 4 => 'notPresent', 5 => 'codeUpdate'
};
my $mapping_link_status = {
    1 => 'up', 2 => 'down'
};

my $mapping_industrial = {
    role    => { oid => '.1.3.6.1.4.1.171.14.9.1.1.8.1.3', map => $mapping_role }, # dStackInfoRole
    macaddr => { oid => '.1.3.6.1.4.1.171.14.9.1.1.8.1.7' } # dStackInfoMacAddr
};
my $mapping_common = {
    role    => { oid => '.1.3.6.1.4.1.171.17.9.1.1.13.1.3', map => $mapping_role }, # esStackInfoRole
    macaddr => { oid => '.1.3.6.1.4.1.171.17.9.1.1.13.1.7' }, # esStackInfoMacAddr
    status  => { oid => '.1.3.6.1.4.1.171.17.9.1.1.13.1.14', map => $mapping_unit_status } # esStackInfoUnitStatus
};
my $mapping_link = {
    box_id  => { oid => '.1.3.6.1.4.1.171.17.9.1.1.14.1.2' }, # esStackStackPortBoxId
    tag     => { oid => '.1.3.6.1.4.1.171.17.9.1.1.14.1.3' }, # esStackStackPortTag
    status  => { oid => '.1.3.6.1.4.1.171.17.9.1.1.14.1.4', map => $mapping_link_status } # esStackStackPortLinkStatus
};
my $oid_dStackUnitInfoEntry = '.1.3.6.1.4.1.171.14.9.1.1.8.1';
my $oid_esStackUnitInfoEntry = '.1.3.6.1.4.1.171.17.9.1.1.13.1';
my $oid_esStackUnitStackPortEntry = '.1.3.6.1.4.1.171.17.9.1.1.14.1';

sub manage_stack {
    my ($self, %options) = @_;

    foreach my $oid (keys %{$options{snmp_result}}) {
        next if ($oid !~ /^$options{mapping}->{role}->{oid}\.(.*)$/);
        my $box_id = $1;
        my $result = $options{snmp}->map_instance(mapping => $options{mapping}, results => $options{snmp_result}, instance => $box_id);

        my $status = defined($result->{status}) ? $result->{status} : '-';
        $self->{global}->{members}++ if ($status ne 'notPresent');
        $self->{member}->{$box_id} = {
            display => $box_id,
            member_global => {
                display => $box_id,
                role => $result->{role},
                macaddr => $result->{macaddr},
                status => $status
            },
            link => {}
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_dStackUnitInfoEntry, start => $mapping_industrial->{role}->{oid}, end => $mapping_industrial->{macaddr}->{oid} },
            { oid => $oid_esStackUnitInfoEntry, start => $mapping_common->{role}->{oid}, end => $mapping_common->{status}->{oid} },
            { oid => $oid_esStackUnitStackPortEntry, start => $mapping_link->{box_id}->{oid}, end => $mapping_link->{status}->{oid} }
        ],
        nothing_quit => 1
    );

    $self->{global} = { members => 0 };
    $self->{members} = {};
    $self->manage_stack(snmp => $options{snmp}, snmp_result => $snmp_result->{$oid_dStackUnitInfoEntry}, mapping => $mapping_industrial);
    $self->manage_stack(snmp => $options{snmp}, snmp_result => $snmp_result->{$oid_esStackUnitInfoEntry}, mapping => $mapping_common);

    foreach (keys %{$snmp_result->{$oid_esStackUnitStackPortEntry}}) {
        next if (! /^$mapping_link->{box_id}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_link, results => $snmp_result->{$oid_esStackUnitStackPortEntry}, instance => $instance);

        next if (!defined($self->{member}->{ $result->{box_id} }));

        my $name = defined($result->{tag}) && $result->{tag} ne '' ? $result->{tag} : $instance;
        $self->{member}->{ $result->{box_id} }->{link}->{$name} = {
            display => $name,
            status => $result->{status}
        };
    }

    $self->{cache_name} = 'dlink_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check stack.

=over 8

=item B<--unknown-member-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{role}, %{roleLast}, %{status}, %{display}

=item B<--warning-member-status>

Set warning threshold for status (Default: '%{status} =~ /codeUpdate/i').
Can used special variables like: %{role}, %{roleLast}, %{status}, %{display}

=item B<--critical-member-status>

Set critical threshold for status (Default: '%{role} ne %{roleLast} || %{status} =~ /unsupported|codeMismatch/i').
Can used special variables like: %{role}, %{roleLast}, %{status}, %{display}

=item B<--unknown-link-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-link-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-link-status>

Set critical threshold for status (Default: '%{status} eq "down"').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'members-total'.

=back

=cut
