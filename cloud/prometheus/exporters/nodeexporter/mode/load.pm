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

package cloud::prometheus::exporters::nodeexporter::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_nodes_output', message_multiple => 'All nodes load are ok' },
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'load1', set => {
                key_values => [ { name => 'load1' }, { name => 'display' } ],
                output_template => 'Load 1 minute: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'load1', value => 'load1_absolute', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'load5', set => {
                key_values => [ { name => 'load5' }, { name => 'display' } ],
                output_template => 'Load 5 minutes: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'load5', value => 'load5_absolute', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'load15', set => {
                key_values => [ { name => 'load15' }, { name => 'display' } ],
                output_template => 'Load 15 minutes: %.2f',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'load15', value => 'load15_absolute', template => '%.2f',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_nodes_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "instance:s"              => { name => 'instance', default => 'instance=~".*"' },
                                  "extra-filter:s@"         => { name => 'extra_filter' },
                                  "metric-overload:s@"      => { name => 'metric_overload' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->{metrics} = {
        'load1'     => '^node_load1$',
        'load5'     => '^node_load5$',
        'load15'    => '^node_load15$',
    };
    foreach my $metric (@{$self->{option_results}->{metric_overload}}) {
        next if ($metric !~ /(.*),(.*)/);
        $self->{metrics}->{$1} = $2 if (defined($self->{metrics}->{$1}));
    }

    $self->{labels} = {};
    foreach my $label (('instance')) {
        if ($self->{option_results}->{$label} !~ /^(\w+)[!~=]+\".*\"$/) {
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label . " option as a PromQL filter.");
            $self->{output}->option_exit();
        }
        $self->{labels}->{$label} = $1;
    }

    $self->{extra_filter} = '';
    foreach my $filter (@{$self->{option_results}->{extra_filter}}) {
        $self->{extra_filter} .= ',' . $filter;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $results = $options{custom}->query(queries => [ 'label_replace({__name__=~"' . $self->{metrics}->{load1} . '",' .
                                                            $self->{option_results}->{instance} .
                                                            $self->{extra_filter} . '}, "__name__", "load1", "", "")',
                                                        'label_replace({__name__=~"' . $self->{metrics}->{load5} . '",' .
                                                            $self->{option_results}->{instance} .
                                                            $self->{extra_filter} . '}, "__name__", "load5", "", "")',
                                                        'label_replace({__name__=~"' . $self->{metrics}->{load15} . '",' .
                                                            $self->{option_results}->{instance} .
                                                            $self->{extra_filter} . '}, "__name__", "load15", "", "")' ]);

    foreach my $result (@{$results}) {
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{display} = $result->{metric}->{$self->{labels}->{instance}};
        $self->{nodes}->{$result->{metric}->{$self->{labels}->{instance}}}->{$result->{metric}->{__name__}} = ${$result->{value}}[1];
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check nodes load.

=over 8

=item B<--instance>

Filter on a specific instance (Must be a PromQL filter, Default: 'instance=~".*"')

=item B<--warning-*>

Threshold warning.
Can be: 'load1', 'load5', 'load15'.

=item B<--critical-*>

Threshold critical.
Can be: 'load1', 'load5', 'load15'.

=item B<--extra-filter>

Add a PromQL filter (Can be multiple)

Example : --extra-filter='name=~".*pretty.*"'

=item B<--metric-overload>

Overload default metrics name (Can be multiple, metric can be 'load1', 'load5', 'load15')

Example : --metric-overload='metric,^my_metric_name$'

=back

=cut
