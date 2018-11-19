#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
            eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("State is '%s', Role is '%s'", $self->{result_values}->{state}, $self->{result_values}->{role});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{id} = $options{new_datas}->{$self->{instance} . '_id'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
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
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'members', type => 1, cb_prefix_output => 'prefix_status_output', message_multiple => 'All stack members status are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'waiting', set => {
                key_values => [ { name => 'waiting' } ],
                output_template => 'Waiting: %d',
                perfdatas => [
                    { label => 'waiting', value => 'waiting_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'progressing', set => {
                key_values => [ { name => 'progressing' } ],
                output_template => 'Progressing: %d',
                perfdatas => [
                    { label => 'progressing', value => 'progressing_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'added', set => {
                key_values => [ { name => 'added' } ],
                output_template => 'Added: %d',
                perfdatas => [
                    { label => 'added', value => 'added_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'ready', set => {
                key_values => [ { name => 'ready' } ],
                output_template => 'Ready: %d',
                perfdatas => [
                    { label => 'ready', value => 'ready_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'sdm-mismatch', set => {
                key_values => [ { name => 'sdmMismatch' } ],
                output_template => 'SDM Mismatch: %d',
                perfdatas => [
                    { label => 'sdm_mismatch', value => 'sdmMismatch_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'version-mismatch', set => {
                key_values => [ { name => 'verMismatch' } ],
                output_template => 'Version Mismatch: %d',
                perfdatas => [
                    { label => 'version_mismatch', value => 'verMismatch_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'feature-mismatch', set => {
                key_values => [ { name => 'featureMismatch' } ],
                output_template => 'Feature Mismatch: %d',
                perfdatas => [
                    { label => 'feature_mismatch', value => 'featureMismatch_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'new-master-init', set => {
                key_values => [ { name => 'newMasterInit' } ],
                output_template => 'New Master Init: %d',
                perfdatas => [
                    { label => 'new_master_init', value => 'newMasterInit_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'provisioned', set => {
                key_values => [ { name => 'provisioned' } ],
                output_template => 'Provisioned: %d',
                perfdatas => [
                    { label => 'provisioned', value => 'provisioned_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'invalid', set => {
                key_values => [ { name => 'invalid' } ],
                output_template => 'Invalid: %d',
                perfdatas => [
                    { label => 'invalid', value => 'invalid_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'removed', set => {
                key_values => [ { name => 'removed' } ],
                output_template => 'Removed: %d',
                perfdatas => [
                    { label => 'removed', value => 'removed_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{members} = [
        { label => 'member', threshold => 0, set => {
                key_values => [ { name => 'id' }, { name => 'role' }, { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning-status:s"  => { name => 'warning_status', default => '' },
                                  "critical-status:s" => { name => 'critical_status', default => '%{state} !~ /ready/ && %{state} !~ /provisioned/' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
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
    $self->{snmp} = $options{snmp};

    $self->{global} = { waiting => 0, progressing => 0, added => 0, ready => 0, sdmMismatch => 0, 
        verMismatch => 0, featureMismatch => 0, newMasterInit => 0, provisioned => 0, 
        invalid => 0, removed => 0 };
    $self->{members} = {};

    my $redundant = $self->{snmp}->get_leef(oids => [ $oid_cswRingRedundant ], nothing_quit => 1);

    if ($redundant->{$oid_cswRingRedundant} != 1) {
        $self->{output}->add_option_msg(short_msg => "Stack ring is not redundant");
        $self->{output}->option_exit();
    }

    $self->{results} = $options{snmp}->get_table(oid => $oid_cswSwitchInfoEntry,
                                                 nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}}) {
        next if($oid !~ /^$mapping->{cswSwitchRole}->{oid}\.(.*)$/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);

        # .1001, .2001 the instance.
        my $id = int(($instance - 1) / 1000);
        $self->{members}->{$id} = {
            id => $id,
            role => $result->{cswSwitchRole},
            state => $result->{cswSwitchState},
        };
        $self->{global}->{$result->{cswSwitchState}}++;
    }

    if (scalar(keys %{$self->{members}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No stack members found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Cisco Stack (CISCO-STACKWISE-MIB).

=over 8

=item B<--warning-*>

Set warning threshold on members count for each states.
(Can be: 'waiting', 'progressing', 'added', 'ready', 'sdm-mismatch', 'version-mismatch',
'feature-mismatch', 'new-master-init', 'provisioned', 'invalid', 'removed')

=item B<--critical-*>

Set warning threshold on members count for each states.
(Can be: 'waiting', 'progressing', 'added', 'ready', 'sdm-mismatch', 'version-mismatch',
'feature-mismatch', 'new-master-init', 'provisioned', 'invalid', 'removed')

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{id}, %{role}, %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /ready/ && %{state} !~ /provisioned/').
Can used special variables like: %{id}, %{role}, %{state}

Role can be: 'master', 'member', 'notMember', 'standby'.

State can be: 'waiting', 'progressing', 'added',
'ready', 'sdmMismatch', 'verMismatch', 'featureMismatch',
'newMasterInit', 'provisioned', 'invalid', 'removed'.

=back

=cut
    