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

package network::juniper::common::screenos::snmp::mode::nsrp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("status: %s",
        $self->{result_values}->{status});
    return $msg;
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

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nsrp', type => 3, cb_prefix_output => 'prefix_nsrp_output', cb_long_output => 'nsrp_long_output', indent_long_output => '    ', message_multiple => 'All nsrp groups are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'member', cb_prefix_output => 'prefix_member_output', message_multiple => 'All members are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'group-transition-change', nlabel => 'nsrp.group.transition.change.count', set => {
                key_values => [ { name => 'nsrpVsdGroupCntStateChange', diff => 1 } ],
                output_template => 'number of state transition events: %s',
                perfdatas => [
                    { value => 'nsrpVsdGroupCntStateChange', template => '%s',
                      min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{member} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'      => { name => 'unknown_status', default => '%{status} =~ /undefined/i' },
        'warning-status:s'      => { name => 'warning_status', default => '' },
        'critical-status:s'     => { name => 'critical_status', default => '%{status} =~ /ineligible|inoperable/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my %map_status = (
    0 => 'undefined',
    1 => 'init',
    2 => 'master',
    3 => 'primary-backup',
    4 => 'backup',
    5 => 'ineligible',
    6 => 'inoperable',
);

my $mapping = {
    nsrpVsdMemberStatus => { oid => '.1.3.6.1.4.1.3224.6.2.2.1.3', map => \%map_status },
};
my $mapping2 = {
    nsrpVsdGroupCntStateChange  => { oid => '.1.3.6.1.4.1.3224.6.2.1.1.6' },
    nsrpVsdGroupCntToInit       => { oid => '.1.3.6.1.4.1.3224.6.2.1.1.7' },
    nsrpVsdGroupCntToMaster     => { oid => '.1.3.6.1.4.1.3224.6.2.1.1.8' },
};
my $oid_nsrpVsdGroupEntry = '.1.3.6.1.4.1.3224.6.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nsrp} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{nsrpVsdMemberStatus}->{oid} },
            { oid => $oid_nsrpVsdGroupEntry, start => $mapping2->{nsrpVsdGroupCntStateChange}->{oid}, end => $mapping2->{nsrpVsdGroupCntToMaster}->{oid} },
        ],
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result->{ $mapping->{nsrpVsdMemberStatus}->{oid} }}) {
        $oid =~ /^$mapping->{nsrpVsdMemberStatus}->{oid}\.(\d+)\.(\d+)$/;
        my ($group_id, $member_id) = ($1, $2);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{ $mapping->{nsrpVsdMemberStatus}->{oid} }, instance => $group_id . '.' . $member_id);
        
        if (!defined($self->{nsrp}->{$group_id})) {
            my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_nsrpVsdGroupEntry}, instance => $group_id);
            $self->{nsrp}->{$group_id} = {
                display => $group_id, 
                global => {
                    %$result2
                },
                member => {},
            };
        }

        $self->{nsrp}->{$group_id}->{member}->{$member_id} = {
            display => $member_id, 
            status => $result->{nsrpVsdMemberStatus},
        };
    }

    $self->{cache_name} = "juniper_screenos_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check nsrp groups.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /undefined/i').
Can used special variables like: %{status}, %{statusLast}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{statusLast}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /ineligible|inoperable/i').
Can used special variables like: %{status}, %{statusLast}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'group-transition-change'.

=back

=cut
