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

package cloud::kubernetes::mode::nodeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_cpu_output {
    my ($self, %options) = @_;

    return sprintf(
        'CPU %s: %.2f%% (%s/%s)',
        $self->{result_values}->{flavor},
        $self->{result_values}->{'cpu_' . $self->{result_values}->{flavor} . '_prct'},
        $self->{result_values}->{'cpu_' . $self->{result_values}->{flavor}},
        $self->{result_values}->{cpu_allocatable}
    );
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{flavor} = $options{extra_options}->{flavor};
    $self->{result_values}->{cpu_allocatable} = $options{new_datas}->{$self->{instance} . '_cpu_allocatable'};    
    $self->{result_values}->{'cpu_' . $self->{result_values}->{flavor}} = $options{new_datas}->{$self->{instance} . '_cpu_' . $self->{result_values}->{flavor}};
    $self->{result_values}->{'cpu_' . $self->{result_values}->{flavor} . '_prct'} = ($self->{result_values}->{cpu_allocatable} > 0) ?
        $self->{result_values}->{'cpu_' . $self->{result_values}->{flavor}} * 100 / $self->{result_values}->{cpu_allocatable} : 0;

    return 0;
}

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        'Memory %s: %.2f%% (%s%s/%s%s)',
        $self->{result_values}->{flavor},
        $self->{result_values}->{'memory_' . $self->{result_values}->{flavor} . '_prct'},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{'memory_' . $self->{result_values}->{flavor}}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{memory_allocatable})
    );
}

sub custom_memory_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{flavor} = $options{extra_options}->{flavor};
    $self->{result_values}->{memory_allocatable} = $options{new_datas}->{$self->{instance} . '_memory_allocatable'};    
    $self->{result_values}->{'memory_' . $self->{result_values}->{flavor}} = $options{new_datas}->{$self->{instance} . '_memory_' . $self->{result_values}->{flavor}};
    $self->{result_values}->{'memory_' . $self->{result_values}->{flavor} . '_prct'} = ($self->{result_values}->{memory_allocatable} > 0) ?
        $self->{result_values}->{'memory_' . $self->{result_values}->{flavor}} * 100 / $self->{result_values}->{memory_allocatable} : 0;

    return 0;
}

sub custom_pods_output {
    my ($self, %options) = @_;

    return sprintf(
        'Pods allocation: %.2f%% (%s/%s)',
        $self->{result_values}->{pods_allocated_prct},
        $self->{result_values}->{pods_allocated},
        $self->{result_values}->{pods_allocatable}
    );
}

sub custom_pods_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{pods_allocatable} = $options{new_datas}->{$self->{instance} . '_pods_allocatable'};
    $self->{result_values}->{pods_allocated} = $options{new_datas}->{$self->{instance} . '_pods_allocated'};
    $self->{result_values}->{pods_allocated_prct} = ($self->{result_values}->{pods_allocatable} > 0) ?
        $self->{result_values}->{pods_allocated} * 100 / $self->{result_values}->{pods_allocatable} : 0;
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output',
            message_multiple => 'All Nodes usage are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'cpu-requests', nlabel => 'cpu.requests.percentage', set => {
                key_values => [ { name => 'cpu_allocatable' }, { name => 'cpu_requests' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => { flavor => 'requests' },
                closure_custom_output => $self->can('custom_cpu_output'),
                perfdatas => [
                    { label => 'cpu_requests', value => 'cpu_requests_prct',
                      template => '%.2f', min => 0, max => '100', unit => '%',
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cpu-limits', nlabel => 'cpu.limits.percentage', set => {
                key_values => [ { name => 'cpu_allocatable' }, { name => 'cpu_limits' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                closure_custom_calc_extra_options => { flavor => 'limits' },
                closure_custom_output => $self->can('custom_cpu_output'),
                perfdatas => [
                    { label => 'cpu_limits', value => 'cpu_limits_prct',
                      template => '%.2f', min => 0, max => '100', unit => '%',
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'memory-requests', nlabel => 'memory.requests.percentage', set => {
                key_values => [ { name => 'memory_allocatable' }, { name => 'memory_requests' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_memory_calc'),
                closure_custom_calc_extra_options => { flavor => 'requests' },
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { label => 'memory_requests', value => 'memory_requests_prct',
                      template => '%.2f', min => 0, max => '100', unit => '%',
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'memory-limits', nlabel => 'memory.limits.percentage', set => {
                key_values => [ { name => 'memory_allocatable' }, { name => 'memory_limits' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_memory_calc'),
                closure_custom_calc_extra_options => { flavor => 'limits' },
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { label => 'memory_limits', value => 'memory_limits_prct',
                      template => '%.2f', min => 0, max => '100', unit => '%',
                      label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'allocated-pods', nlabel => 'pods.allocation.percentage', set => {
                key_values => [ { name => 'pods_allocatable' }, { name => 'pods_allocated' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_pods_calc'),
                closure_custom_output => $self->can('custom_pods_output'),
                perfdatas => [
                    { label => 'allocated_pods', value => 'pods_allocated_prct',
                      template => '%.2f', min => 0, max => '100', unit => '%',
                      label_extra_instance => 1, instance_use => 'display' }
                ]
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
        "units:s"       => { name => 'units', default => '%' }, # Keep compat
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $nodes = $options{custom}->kubernetes_list_nodes();
    
    foreach my $node (@{$nodes}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $node->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{nodes}->{$node->{metadata}->{name}} = {
            display => $node->{metadata}->{name},
            pods_allocatable => $node->{status}->{allocatable}->{pods},
            cpu_allocatable => $self->to_bytes(value => $node->{status}->{allocatable}->{cpu}),
            memory_allocatable => $self->to_bytes(value => $node->{status}->{capacity}->{memory}),
        }            
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Nodes found.");
        $self->{output}->option_exit();
    }
    
    my $pods = $options{custom}->kubernetes_list_pods();

    foreach my $pod (@{$pods}) {
        next if (defined($pod->{spec}->{nodeName}) && !defined($self->{nodes}->{$pod->{spec}->{nodeName}}));
        $self->{nodes}->{$pod->{spec}->{nodeName}}->{pods_allocated}++;
        foreach my $container (@{$pod->{spec}->{containers}}) {
            $self->{nodes}->{$pod->{spec}->{nodeName}}->{cpu_requests} += $self->to_core(value => $container->{resources}->{requests}->{cpu}) if (defined($container->{resources}->{requests}->{cpu}));
            $self->{nodes}->{$pod->{spec}->{nodeName}}->{cpu_limits} += $self->to_core(value => $container->{resources}->{limits}->{cpu}) if (defined($container->{resources}->{limits}->{cpu}));            
            $self->{nodes}->{$pod->{spec}->{nodeName}}->{memory_requests} += $self->to_bytes(value => $container->{resources}->{requests}->{memory}) if (defined($container->{resources}->{requests}->{memory}));
            $self->{nodes}->{$pod->{spec}->{nodeName}}->{memory_limits} += $self->to_bytes(value => $container->{resources}->{limits}->{memory}) if (defined($container->{resources}->{limits}->{memory}));
        }
    }
}

sub to_bytes {
    my ($self, %options) = @_;

    my $value = $options{value};
    
    if ($value =~ /(\d+)Ki$/) {
        $value = $1 * 1024;
    } elsif ($value =~ /(\d+)Mi$/) {
        $value = $1 * 1024 * 1024;
    } elsif ($value =~ /(\d+)Gi$/) {
        $value = $1 * 1024 * 1024 * 1024;
    } elsif ($value =~ /(\d+)Ti$/) {
        $value = $1 * 1024 * 1024 * 1024 * 1024;
    }

    return $value;
}

sub to_core {
    my ($self, %options) = @_;

    my $value = $options{value};
    
    if ($value =~ /(\d+)m$/) {
        $value = $1 / 1000;
    }

    return $value;
}

1;

__END__

=head1 MODE

Check node usage.

=over 8

=item B<--filter-name>

Filter node name (can be a regexp).

=item B<--warning-*> B<--critical-*> 

Thresholds (in percentage).
Can be: 'cpu-requests', 'cpu-limits', 'memory-requests', 'memory-limits',
'allocated-pods'.

=back

=cut
