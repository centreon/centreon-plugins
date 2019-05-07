#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::mode::clusterstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{instance_mode}->{option_results}->{critical_status}) && $self->{instance_mode}->{option_results}->{critical_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($self->{instance_mode}->{option_results}->{warning_status}) && $self->{instance_mode}->{option_results}->{warning_status} ne '' &&
            eval "$self->{instance_mode}->{option_results}->{warning_status}") {
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
    
    my $msg = sprintf("status is '%s' [Hostname: %s] [Role: %s]",
        $self->{result_values}->{sync_status},
        $self->{result_values}->{hostname},
        $self->{result_values}->{role});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{serial} = $options{new_datas}->{$self->{instance} . '_serial'};
    $self->{result_values}->{hostname} = $options{new_datas}->{$self->{instance} . '_hostname'};
    $self->{result_values}->{sync_status} = $options{new_datas}->{$self->{instance} . '_sync_status'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    return 0;
}

sub prefix_status_output {
    my ($self, %options) = @_;
    
    return "Node '" . $options{instance_value}->{serial} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Nodes ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_status_output', message_multiple => 'All cluster nodes status are ok' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-nodes', display_ok => 0, set => {
                key_values => [ { name => 'total_nodes' } ],
                output_template => 'Total nodes: %d',
                perfdatas => [
                    { label => 'total_nodes', value => 'total_nodes_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'synchronized', set => {
                key_values => [ { name => 'synchronized' } ],
                output_template => 'Synchronized: %d',
                perfdatas => [
                    { label => 'synchronized_nodes', value => 'synchronized_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'not-synchronized', set => {
                key_values => [ { name => 'not_synchronized' } ],
                output_template => 'Not Synchronized: %d',
                perfdatas => [
                    { label => 'not_synchronized_nodes', value => 'not_synchronized_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];        
    $self->{maps_counters}->{nodes} = [
        { label => 'node', threshold => 0, set => {
                key_values => [ { name => 'serial' }, { name => 'hostname' }, { name => 'sync_status' }, { name => 'role' } ],
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
                                    "critical-status:s" => { name => 'critical_status', default => '%{sync_status} =~ /not synchronized/' },
                                    "one-node-status:s" => { name => 'one_node_status' }, # not used, use --opt-exit instead
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_ha_mode = (
    1 => 'standalone',
    2 => 'activeActive',
    3 => 'activePassive',
);
my %map_sync_status = (
    0 => 'not synchronized',
    1 => 'synchronized',
);

my $mapping = {
    fgHaStatsSerial => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.2' },
    fgHaStatsHostname => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.11' },
    fgHaStatsSyncStatus => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.12', map => \%map_sync_status },
    fgHaStatsMasterSerial => { oid => '.1.3.6.1.4.1.12356.101.13.2.1.1.16' },
};
my $oid_fgHaStatsEntry = '.1.3.6.1.4.1.12356.101.13.2.1.1';

my $oid_fgHaSystemMode = '.1.3.6.1.4.1.12356.101.13.1.1.0';

sub manage_selection {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->{nodes} = {};

    my $mode = $self->{snmp}->get_leef(oids => [ $oid_fgHaSystemMode ], nothing_quit => 1);
    
    if ($map_ha_mode{$mode->{$oid_fgHaSystemMode}} =~ /standalone/) {
        $self->{output}->add_option_msg(short_msg => "No cluster configuration (standalone mode)");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(short_msg => "HA mode: " . $map_ha_mode{$mode->{$oid_fgHaSystemMode}});

    $self->{results} = $options{snmp}->get_table(oid => $oid_fgHaStatsEntry,
                                                 nothing_quit => 1);

    $self->{global} = { synchronized => 0, not_synchronized => 0, total_nodes => 0 };

    foreach my $oid (keys %{$self->{results}}) {
        next if ($oid !~ /^$mapping->{fgHaStatsSerial}->{oid}\.(.*)$/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);

        $self->{nodes}->{$instance} = {
            serial => $result->{fgHaStatsSerial},
            hostname => $result->{fgHaStatsHostname},
            sync_status => $result->{fgHaStatsSyncStatus},
            role => ($result->{fgHaStatsMasterSerial} eq '' || $result->{fgHaStatsMasterSerial} =~ /$result->{fgHaStatsSerial}/) ? "master" : "slave",
        };
        $result->{fgHaStatsSyncStatus} =~ s/ /_/;
        $self->{global}->{$result->{fgHaStatsSyncStatus}}++;
        $self->{global}->{total_nodes}++;
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No cluster nodes found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check cluster status (FORTINET-FORTIGATE-MIB).

=over 8

=item B<--warning-*>

Set warning thresholds.
Can be: 'total-nodes', 'synchronized', 'not-synchronized'.

=item B<--critical-*>

Set critical thresholds.
Can be: 'total-nodes', 'synchronized', 'not-synchronized'.

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{serial}, %{hostname}, %{sync_status}, %{role}

=item B<--critical-status>

Set critical threshold for status (Default: '%{sync_status} !~ /synchronized/').
Can used special variables like: %{serial}, %{hostname}, %{sync_status}, %{role}

=back

=cut
    
