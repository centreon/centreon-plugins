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

package storage::hp::3par::ssh::mode::nodes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub node_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking node '%s'",
        $options{instance_value}->{node_id}
    );
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return sprintf(
        "node '%s' ",
        $options{instance_value}->{node_id}
    );
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{cpu_id} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'node_long_output', indent_long_output => '    ', message_multiple => 'All nodes are ok',
            group => [
                { name => 'global', type => 0 },
                { name => 'cpu', display_long => 1, cb_prefix_output => 'prefix_cpu_output',
                  message_multiple => 'all CPUs usage are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /ok/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'node_id' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-utilization', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' } ],
                output_template => 'usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-node-id:s' => { name => 'filter_node_id' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($content) = $options{custom}->execute_command(
        commands => [
            'echo "===statcpu==="',
            'statcpu -iter 1 -d 1',
            'echo "===shownode==="',
            'shownode -s'
        ]
    );
    #===statcpu===
    #17:34:58 01/27/2022
    #node,cpu user sys idle intr/s ctxt/s
    #     0,0    1   0   99
    #     0,1    1   1   98
    #     0,2    0   1   99
    #     0,3    1   1   98
    #     0,4    0   1   99
    #     0,5    0   1   99
    #     0,6    4   1   95
    #     0,7    0   0  100
    # 0,total    1   1   98   7276   9026
    #
    #     1,0    0   0  100
    #     1,1    0   0  100
    #     1,2    0   0  100
    #     1,3    0   1   99
    #     1,4    0   0  100
    #     1,5    0   1   99
    #     1,6    0   2   98
    #     1,7    0   0  100
    # 1,total    0   1   99   5312   4799
    #===shownode===
    #Node -State- -Detailed_State-
    #   0 OK      OK
    #   1 OK      OK

    $self->{nodes} = {};
    if ($content =~ /===shownode===.*?\n(.*?)(===|\Z)/msi) {
        foreach my $line (split(/\n/, $1)) {
            next if ($line !~ /^\s*(\d+)\s+(\S+)/);
            my ($node_id, $status) = ($1, $2);

            next if (defined($self->{option_results}->{filter_node_id}) && $self->{option_results}->{filter_node_id} ne '' &&
                $node_id !~ /$self->{option_results}->{filter_node_id}/);
            $self->{nodes}->{'node' . $node_id} = {
                node_id => $node_id,
                global => { node_id => $node_id, status => $status },
                cpu => {}
            };
        }
    }

    if ($content =~ /===statcpu===.*?\n(.*?)(===|\Z)/msi) {
        foreach my $line (split(/\n/, $1)) {
            next if ($line !~ /^\s*(\d+),(\d+)\s+\d+\s+\d+\s+(\d+)/);
            my ($node_id, $cpu_id, $idle) = ($1, $2, $3);
            next if (!defined($self->{nodes}->{'node' . $node_id}));

            $self->{nodes}->{'node' . $node_id}->{cpu}->{'cpu' . $cpu_id} = {
                cpu_id => $cpu_id,
                cpu_usage => 100 - $idle
            };
        }
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Couldn't get nodes information");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check nodes.

=over 8

=item B<--filter-node-id>

Filter nodes by ID (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{node_id}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{node_id}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/i').
You can use the following variables: %{status}, %{node_id}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization'.

=back

=cut
