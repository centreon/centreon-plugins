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

package network::stormshield::snmp::mode::hanodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_node_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => 'dead_nodes',
                                  value => sprintf("%d", $self->{result_values}->{dead_nodes}),
                                  min => 0, max => $self->{result_values}->{total_nodes});
}

sub custom_node_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = defined($self->{instance_mode}->{option_results}->{percent}) ? $self->{result_values}->{prct_dead} : $self->{result_values}->{dead_nodes} ;
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-dead-nodes', exit_litteral => 'critical' }, { label => 'warning-dead-nodes', exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_node_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Dead nodes: %d/%d (%.2f%%)", 
                    $self->{result_values}->{dead_nodes}, $self->{result_values}->{total_nodes}, $self->{result_values}->{prct_dead});
    return $msg;
}

sub custom_node_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{dead_nodes} = $options{new_datas}->{$self->{instance} . '_dead_nodes'};
    $self->{result_values}->{total_nodes} = $options{new_datas}->{$self->{instance} . '_total_nodes'};
    $self->{result_values}->{prct_dead} = $options{new_datas}->{$self->{instance} . '_prct_dead'};

    return 0;
}

sub custom_state_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s' [role: %s]", $self->{result_values}->{state}, $self->{result_values}->{role});
    return $msg;
}

sub custom_state_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_ntqOnline'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_ntqHALicence'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All HA nodes are OK' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'dead-nodes', set => {
                key_values => [ { name => 'dead_nodes' }, { name => 'prct_dead' }, { name => 'total_nodes' } ],
                closure_custom_calc => $self->can('custom_node_calc'),
                closure_custom_output => $self->can('custom_node_output'),
                closure_custom_threshold_check => $self->can('custom_node_threshold'),
                closure_custom_perfdata => $self->can('custom_node_perfdata'),
            }
        }
    ];
    $self->{maps_counters}->{nodes} = [
        { label => 'state', threshold => 0,  set => {
                key_values => [ { name => 'ntqOnline' }, { name => 'ntqHALicence' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_state_calc'),
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'health', set => {
                key_values => [ { name => 'ntqHAQuality' }, { name => 'display' } ],
                output_template => 'health: %s%%',
                perfdatas => [
                    { label => 'health', value => 'ntqHAQuality', template => '%d', min => 0, max => 100,
                       unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                "filter-node:s"         => { name => 'filter_node' },
                                "percent"               => { name => 'percent' },
                                "warning-state:s"       => { name => 'warning_state', default => '' },
                                "critical-state:s"      => { name => 'critical_state', default => '%{state} =~ /offline/i' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_state', 'critical_state']);
}

my %map_status = (
    1 => 'online',
    2 => 'offline',
);

my $oid_ntqFwSerial = '.1.3.6.1.4.1.11256.1.11.7.1.2';
my $mapping = {
    ntqOnline    => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.3', map => \%map_status },
    ntqHALicence => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.6' },
    ntqHAQuality => { oid => '.1.3.6.1.4.1.11256.1.11.7.1.7' },
};

my $oid_ntqNbNode = '.1.3.6.1.4.1.11256.1.11.1.0';
my $oid_ntqNbDeadNode = '.1.3.6.1.4.1.11256.1.11.2.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_ntqNbNode, $oid_ntqNbDeadNode ], nothing_quit => 1);
    
    my $prct_dead = $snmp_result->{$oid_ntqNbDeadNode} * 100 / $snmp_result->{$oid_ntqNbNode};

    $self->{global} = { dead_nodes => $snmp_result->{$oid_ntqNbDeadNode},
                        total_nodes => $snmp_result->{$oid_ntqNbNode},
                        prct_dead => $prct_dead };

    $snmp_result = $options{snmp}->get_table(oid => $oid_ntqFwSerial, nothing_quit => 1);
    $self->{nodes} = {};
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_ntqFwSerial\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping node '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }

        $self->{nodes}->{$instance} = { display => $snmp_result->{$oid} };
    }


    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(oids => [ $mapping->{ntqOnline}->{oid}, $mapping->{ntqHALicence}->{oid}, $mapping->{ntqHAQuality}->{oid} ],
        instances => [keys %{$self->{nodes}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{nodes}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        
        foreach my $name (keys %$mapping) {
            $self->{nodes}->{$_}->{$name} = $result->{$name};
        }
    }
}

1;

__END__

=head1 MODE

Check Stormshield nodes status (state, role and health) and dead nodes.

=over 8

=item B<--filter-node>

Filter name with regexp (based on serial)

=item B<--warning-health>

Warning on health level. (e.g --warning 90:)

=item B<--critical-health>

Critical on health level. (e.g --critical 80:)

=item B<--warning-dead-nodes>

Warning on deadnode (absolute unless --percent is used)

=item B<--critical-dead-nodes>

Critical on deadnode (absolute unless --percent is used)

=item B<--warning-state>

Set warning threshold for state.
Can used special variables like: %{state}, %{role}

=item B<--critical-state>

Set critical threshold for state. (Default: '%{state} =~ /offline/i').
Can used special variables like: %{state}, %{role}

=item B<--percent>

Set this option if you want to warn on percent 

=back

=cut
