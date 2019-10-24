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

package cloud::google::gcp::compute::computeengine::mode::cpu;

use base qw(cloud::google::gcp::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;

    my $metrics_mapping = {
        'instance/cpu/utilization' => {
            'output_string' => 'Cpu Utilization: %.2f',
            'perfdata' => {
                'absolute' => {
                    'nlabel' => 'computeengine.cpu.utilization.percentage',
                    'min' => '0',
                    'max' => '100',
                    'unit' => '%',
                    'format' => '%.2f',
                },
            },
            'threshold' => 'utilization',
            'calc' => '* 100',
        },
        'instance/cpu/reserved_cores' => {
            'output_string' => 'Cpu Reserved Cores: %.2f',
            'perfdata' => {
                'absolute' => {
                    'nlabel' => 'computeengine.cpu.cores.reserved.count',
                    'format' => '%.2f',
                }
            },
            'threshold' => 'cores-reserved',
        },
    };

    return $metrics_mapping;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'instance:s@'       => { name => 'instance' },
        'filter-metric:s'   => { name => 'filter_metric' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{instance})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --instance <name>.");
        $self->{output}->option_exit();
    }
    
    $self->{gcp_api} = "compute.googleapis.com";
    $self->{gcp_dimension} = 'metric.labels.instance_name';
    $self->{gcp_instance} = $self->{option_results}->{instance};
    $self->{gcp_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 900;
    $self->{gcp_aggregations} = ['average'];
    if (defined($self->{option_results}->{aggregation})) {
        $self->{gcp_aggregations} = [];
        foreach my $stat (@{$self->{option_results}->{aggregation}}) {
            if ($stat ne '') {
                push @{$self->{gcp_aggregations}}, $stat;
            }
        }
    }

    foreach my $metric (keys %{$self->{metrics_mapping}}) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);

        push @{$self->{gcp_metrics}}, $metric;
    }
}

1;

__END__

=head1 MODE

Check Compute Engine instances CPU metrics.

Example:

perl centreon_plugins.pl --plugin=cloud::google::gcp::compute::computeengine::plugin
--custommode=api --mode=cpu --instance=mycomputeinstance --filter-metric='utilization'
--aggregation='average' --critical-cpu-utilization-average='10' --verbose

Default aggregation: 'average' / All aggregations are valid.

=over 8

=item B<--instance>

Set instance name (Required).

=item B<--filter-metric>

Filter metrics (Can be: 'instance/cpu/utilization',
'instance/cpu/reserved_cores') (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds critical (Can be: 'utilization',
'cores-reserved').

=back

=cut
