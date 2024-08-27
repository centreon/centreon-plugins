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

package network::juniper::common::screenos::snmp::mode::nsrp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s",
        $self->{result_values}->{status}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{statusLast} = $options{old_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    if (!defined($options{old_datas}->{$self->{instance} . '_status'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub prefix_nsrp_output {
    my ($self, %options) = @_;

    return "Nsrp group '" . $options{instance_value}->{display} . "' ";
}

sub nsrp_long_output {
    my ($self, %options) = @_;

    return "checking nsrp group '" . $options{instance_value}->{display} . "'";
}

sub prefix_member_output {
    my ($self, %options) = @_;

    return "member '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nsrp', type => 3, cb_prefix_output => 'prefix_nsrp_output', cb_long_output => 'nsrp_long_output', indent_long_output => '    ', message_multiple => 'All nsrp groups are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'member', cb_prefix_output => 'prefix_member_output', message_multiple => 'All members are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'group-transition-change', nlabel => 'nsrp.group.transition.change.count', set => {
                key_values => [ { name => 'cnt_state_change', diff => 1 } ],
                output_template => 'number of state transition events: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{member} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /undefined/i',
            critical_default => '%{status} =~ /ineligible|inoperable/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
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

my $map_status = {
    0 => 'undefined',
    1 => 'init',
    2 => 'master',
    3 => 'primary-backup',
    4 => 'backup',
    5 => 'ineligible',
    6 => 'inoperable'
};

my $mapping = {
    group_id  => { oid => '.1.3.6.1.4.1.3224.6.2.2.1.1' }, # nsrpVsdMemberGroupId
    member_id => { oid => '.1.3.6.1.4.1.3224.6.2.2.1.2' }, # nsrpVsdMemberUnitId
    member_status => { oid => '.1.3.6.1.4.1.3224.6.2.2.1.3', map => $map_status } # nsrpVsdMemberStatus
};
my $mapping2 = {
    cnt_state_change  => { oid => '.1.3.6.1.4.1.3224.6.2.1.1.6' } # nsrpVsdGroupCntStateChange
};
my $oid_member_entry = '.1.3.6.1.4.1.3224.6.2.2.1'; # nsrpVsdMemberEntry

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping2->{cnt_state_change}->{oid} },
            { oid => $oid_member_entry, end => $mapping->{member_status}->{oid} }
        ],
        nothing_quit => 1
    );

    $self->{nsrp} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_member_entry}}) {
        next if ($oid !~ /^$mapping->{member_status}->{oid}\.(.*?)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_member_entry}, instance => $1);

        if (!defined($self->{nsrp}->{ $result->{group_id} })) {
            my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{ $mapping2->{cnt_state_change}->{oid} }, instance => $result->{group_id});
            $self->{nsrp}->{ $result->{group_id} } = {
                display => $result->{group_id}, 
                global => $result2,
                member => {},
            };
        }

        $self->{nsrp}->{ $result->{group_id} }->{member}->{ $result->{member_id} } = {
            display => $result->{member_id},
            status => $result->{member_status}
        };
    }

    $self->{cache_name} = 'juniper_screenos_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check nsrp groups.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{status} =~ /undefined/i').
You can use the following variables: %{status}, %{statusLast}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{statusLast}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /ineligible|inoperable/i').
You can use the following variables: %{status}, %{statusLast}

=item B<--warning-*> B<--critical-*>

Warning threshold.
Can be: 'group-transition-change'.

=back

=cut
