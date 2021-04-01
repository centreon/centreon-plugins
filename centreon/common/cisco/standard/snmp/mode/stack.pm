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

package centreon::common::cisco::standard::snmp::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_stack_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Stack status is '%s'", $self->{result_values}->{stack_status});
    return $msg;
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("State is '%s', Role is '%s'", $self->{result_values}->{state}, $self->{result_values}->{role});
    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Number of members ";
}

sub prefix_status_output {
    my ($self, %options) = @_;
    
    return "Member '" . $options{instance_value}->{id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'stack', type => 0 },
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'members', type => 1, cb_prefix_output => 'prefix_status_output', message_multiple => 'All stack members status are ok' },
    ];

    $self->{maps_counters}->{stack} = [
        { label => 'stack-status', threshold => 0, set => {
                key_values => [ { name => 'stack_status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_stack_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'waiting', set => {
                key_values => [ { name => 'waiting' } ],
                output_template => 'Waiting: %d',
                perfdatas => [
                    { label => 'waiting', value => 'waiting', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'progressing', set => {
                key_values => [ { name => 'progressing' } ],
                output_template => 'Progressing: %d',
                perfdatas => [
                    { label => 'progressing', value => 'progressing', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'added', set => {
                key_values => [ { name => 'added' } ],
                output_template => 'Added: %d',
                perfdatas => [
                    { label => 'added', value => 'added', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'ready', set => {
                key_values => [ { name => 'ready' } ],
                output_template => 'Ready: %d',
                perfdatas => [
                    { label => 'ready', value => 'ready', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'sdm-mismatch', set => {
                key_values => [ { name => 'sdmMismatch' } ],
                output_template => 'SDM Mismatch: %d',
                perfdatas => [
                    { label => 'sdm_mismatch', value => 'sdmMismatch', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'version-mismatch', set => {
                key_values => [ { name => 'verMismatch' } ],
                output_template => 'Version Mismatch: %d',
                perfdatas => [
                    { label => 'version_mismatch', value => 'verMismatch', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'feature-mismatch', set => {
                key_values => [ { name => 'featureMismatch' } ],
                output_template => 'Feature Mismatch: %d',
                perfdatas => [
                    { label => 'feature_mismatch', value => 'featureMismatch', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'new-master-init', set => {
                key_values => [ { name => 'newMasterInit' } ],
                output_template => 'New Master Init: %d',
                perfdatas => [
                    { label => 'new_master_init', value => 'newMasterInit', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'provisioned', set => {
                key_values => [ { name => 'provisioned' } ],
                output_template => 'Provisioned: %d',
                perfdatas => [
                    { label => 'provisioned', value => 'provisioned', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'invalid', set => {
                key_values => [ { name => 'invalid' } ],
                output_template => 'Invalid: %d',
                perfdatas => [
                    { label => 'invalid', value => 'invalid', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'removed', set => {
                key_values => [ { name => 'removed' } ],
                output_template => 'Removed: %d',
                perfdatas => [
                    { label => 'removed', value => 'removed', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{members} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'id' }, { name => 'role' }, { name => 'state' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-stack-status:s'    => { name => 'warning_stack_status', default => '' },
        'critical-stack-status:s'   => { name => 'critical_stack_status', default => '%{stack_status} =~ /notredundant/' },
        'warning-status:s'          => { name => 'warning_status', default => '' },
        'critical-status:s'         => { name => 'critical_status', default => '%{state} !~ /ready/ && %{state} !~ /provisioned/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_stack_status', 'critical_stack_status', 'warning_status', 'critical_status']);
}

my %map_role = (
    1 => 'master',
    2 => 'member',
    3 => 'notMember',
    4 => 'standby'
);
my %map_state = (
    1 => 'waiting',
    2 => 'progressing',
    3 => 'added',
    4 => 'ready',
    5 => 'sdmMismatch',
    6 => 'verMismatch',
    7 => 'featureMismatch',
    8 => 'newMasterInit',
    9 => 'provisioned',
    10 => 'invalid',
    11 => 'removed',
);

my $mapping = {
    cswSwitchRole => { oid => '.1.3.6.1.4.1.9.9.500.1.2.1.1.3', map => \%map_role },
    cswSwitchState => { oid => '.1.3.6.1.4.1.9.9.500.1.2.1.1.6', map => \%map_state },
};
my $oid_cswSwitchInfoEntry = '.1.3.6.1.4.1.9.9.500.1.2.1.1';

my $oid_cswRingRedundant = '.1.3.6.1.4.1.9.9.500.1.1.3.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        waiting => 0, progressing => 0, added => 0, ready => 0, sdmMismatch => 0, 
        verMismatch => 0, featureMismatch => 0, newMasterInit => 0, provisioned => 0, 
        invalid => 0, removed => 0
    };
    $self->{members} = {};

    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_cswRingRedundant ], nothing_quit => 1);
    $self->{stack} = {
        stack_status => ($snmp_result->{$oid_cswRingRedundant} != 1) ? 'notredundant' : 'redundant',
    };

    $snmp_result = $options{snmp}->get_table(
        oid => $oid_cswSwitchInfoEntry,
        start => $mapping->{cswSwitchRole}->{oid},
        end => $mapping->{cswSwitchState}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if($oid !~ /^$mapping->{cswSwitchRole}->{oid}\.(.*)$/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        # .1001, .2001 the instance.
        my $id = int(($instance - 1) / 1000);
        $self->{members}->{$id} = {
            id => $id,
            role => $result->{cswSwitchRole},
            state => $result->{cswSwitchState},
        };
        $self->{global}->{$result->{cswSwitchState}}++;
    }
}

1;

__END__

=head1 MODE

Check Cisco Stack (CISCO-STACKWISE-MIB).

=over 8

=item B<--warning-*> B<--critical-*>

Set thresholds on members count for each states.
(Can be: 'waiting', 'progressing', 'added', 'ready', 'sdm-mismatch', 'version-mismatch',
'feature-mismatch', 'new-master-init', 'provisioned', 'invalid', 'removed')

=item B<--warning-stack-status>

Set warning threshold for stack status (Default: '').
Can used special variables like: %{stack_status}

=item B<--critical-stack-status>

Set critical threshold for stack status (Default: '%{stack_status} =~ /notredundant/').
Can used special variables like: %{stack_status}

=item B<--warning-status>

Set warning threshold for members status (Default: '').
Can used special variables like: %{id}, %{role}, %{state}

=item B<--critical-status>

Set critical threshold for member status (Default: '%{state} !~ /ready/ && %{state} !~ /provisioned/').
Can used special variables like: %{id}, %{role}, %{state}

Role can be: 'master', 'member', 'notMember', 'standby'.

State can be: 'waiting', 'progressing', 'added',
'ready', 'sdmMismatch', 'verMismatch', 'featureMismatch',
'newMasterInit', 'provisioned', 'invalid', 'removed'.

=back

=cut
    
