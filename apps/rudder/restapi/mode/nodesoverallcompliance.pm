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

package apps::rudder::restapi::mode::nodesoverallcompliance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_compliance_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => 'compliance_' . $self->{label},
                                  value => $self->{result_values}->{count},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  unit => 'nodes', min => 0, max => $self->{result_values}->{total});
}

sub custom_compliance_threshold {
    my ($self, %options) = @_;

    my $threshold_value = $self->{result_values}->{count};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_count};
    }
    my $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                                  threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                                 { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;

}

sub custom_compliance_output {
    my ($self, %options) = @_;

    my $msg = sprintf("%s: %d (%.2f%%)",
                        $self->{result_values}->{output},
                        $self->{result_values}->{count},
                        $self->{result_values}->{prct_count});
    return $msg;
}

sub custom_compliance_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{output} = $options{extra_options}->{output};
    $self->{result_values}->{count} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    
    $self->{result_values}->{prct_count} = ($self->{result_values}->{total} != 0) ? $self->{result_values}->{count} * 100 / $self->{result_values}->{total} : 0;

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_compliance_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'perfect', set => {
                key_values => [ { name => 'perfect' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_compliance_calc'),
                closure_custom_calc_extra_options => { label => 'perfect', output => 'Perfect (100%)' },
                closure_custom_output => $self->can('custom_compliance_output'),
                closure_custom_threshold_check => $self->can('custom_compliance_threshold'),
                closure_custom_perfdata => $self->can('custom_compliance_perfdata')
            }
        },
        { label => 'good', set => {
                key_values => [ { name => 'good' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_compliance_calc'),
                closure_custom_calc_extra_options => { label => 'good', output => 'Good (>75%)' },
                closure_custom_output => $self->can('custom_compliance_output'),
                closure_custom_threshold_check => $self->can('custom_compliance_threshold'),
                closure_custom_perfdata => $self->can('custom_compliance_perfdata')
            }
        },
        { label => 'average', set => {
                key_values => [ { name => 'average' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_compliance_calc'),
                closure_custom_calc_extra_options => { label => 'average', output => 'Average (>50%)' },
                closure_custom_output => $self->can('custom_compliance_output'),
                closure_custom_threshold_check => $self->can('custom_compliance_threshold'),
                closure_custom_perfdata => $self->can('custom_compliance_perfdata')
            }
        },
        { label => 'poor', set => {
                key_values => [ { name => 'poor' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_compliance_calc'),
                closure_custom_calc_extra_options => { label => 'poor', output => 'Poor (<50%)' },
                closure_custom_output => $self->can('custom_compliance_output'),
                closure_custom_threshold_check => $self->can('custom_compliance_threshold'),
                closure_custom_perfdata => $self->can('custom_compliance_perfdata')
            }
        },
    ];
}

sub prefix_compliance_output {
    my ($self, %options) = @_;

    return "Nodes Count by Overall Compliance ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "units:s"   => { name => 'units', default => '%' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { perfect => 0, good => 0, average => 0, poor => 0, total => 0 };

    my $results = $options{custom}->request_api(url_path => '/compliance/nodes?level=1');
    
    foreach my $node (@{$results->{nodes}}) {
        $self->{global}->{total}++;
        $self->{global}->{poor}++ if ($node->{compliance} < 50);
        $self->{global}->{average}++ if ($node->{compliance} >= 50 && $node->{compliance} < 75);
        $self->{global}->{good}++ if ($node->{compliance} >= 75 && $node->{compliance} < 100);
        $self->{global}->{perfect}++ if ($node->{compliance} == 100);
    }
}

1;

__END__

=head1 MODE

Check nodes count by overall compliance.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'perfect', 'good', 'average', 'poor'.

=item B<--critical-*>

Threshold critical.
Can be: 'perfect', 'good', 'average', 'poor'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'count').

=back

=cut
