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

package apps::monitoring::quanta::restapi::mode::webscenariosavailability;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-response-time', nlabel => 'total.response.time.seconds', set => {
                key_values => [ { name => 'response_time' }, { name => 'display' } ],
                output_template => 'Total Response Time: %.3fs',
                perfdatas => [
                    { value => 'response_time', template => '%.3f',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'availability', nlabel => 'availability.percentage', set => {
                key_values => [ { name => 'availability' }, { name => 'display' } ],
                output_template => 'Availability: %.2f%%',
                perfdatas => [
                    { value => 'availability', template => '%s',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'step-response-time', nlabel => 'step.response.time.seconds', set => {
                key_values => [ { name => 'avg_step_response_time' }, { name => 'display' } ],
                output_template => 'Step Average Response Time: %.3fs',
                perfdatas => [
                    { value => 'avg_step_response_time', template => '%.3f',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Scenario '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "scenario-id:s" => { name => 'scenario_id' },
        "timeframe:s"   => { name => 'timeframe', default => 900 },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{scenario_id}) || $self->{option_results}->{scenario_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --scenario-id option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $from = DateTime->now->subtract(seconds => $self->{option_results}->{timeframe});
    my $to = DateTime->now;
    my $from_epoch = $from->epoch;
    my $to_epoch = $to->epoch;
    my $url = '/partners/report/' . $options{custom}->get_api_token .
        '?scenario=' . $self->{option_results}->{scenario_id} .
        '&from=' . $from_epoch . '&to=' . $to_epoch;

    my $results = $options{custom}->request_api(url_path => $url);

    $self->{global}->{$results->{site}->{id}}->{display} = $results->{site}->{scenario};
    $self->{global}->{$results->{site}->{id}}->{availability} = $results->{site}->{availability} * 100;
    $self->{global}->{$results->{site}->{id}}->{avg_step_response_time} = $results->{site}->{avg_step_response_time};
    foreach my $response (@{$results->{site}->{scenario_response_times}}) {
        $self->{global}->{$results->{site}->{id}}->{response_time} += $response->{value};        
    }
    $self->{global}->{$results->{site}->{id}}->{response_time} /= scalar(@{$results->{site}->{scenario_response_times}})
        if (scalar(@{$results->{site}->{scenario_response_times}}) > 0);
}

1;

__END__

=head1 MODE

Check web scenario availability metrics.

(Data are delayed by a minimum of 3 hours)

=over 8

=item B<--scenario-id>

Set ID of the scenario.

=item B<--timeframe>

Set timeframe in seconds (Default: 14400).

=item B<--warning-*> B<--critical-*>

Can be: 'total-response-time', 'availability',
'step-response-time'.

=back

=cut
