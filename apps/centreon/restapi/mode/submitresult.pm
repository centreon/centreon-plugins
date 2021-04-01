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

package apps::centreon::restapi::mode::submitresult;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'results-202', nlabel => 'results.202.count', set => {
                key_values => [ { name => '202' } ],
                output_template => '202: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'results-400', nlabel => 'results.400.count', set => {
                key_values => [ { name => '400' } ],
                output_template => '400: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'results-404', nlabel => 'results.404.count', set => {
                key_values => [ { name => '404' } ],
                output_template => '404: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Results ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'host:s@'     => { name => 'host' },
        'service:s@'  => { name => 'service' },
        'status:s@'   => { name => 'status' },
        'output:s@'   => { name => 'output' },
        'perfdata:s@' => { name => 'perfdata' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $post_data;
    my $i = 0;
    foreach (@{$self->{option_results}->{host}}) {
        my %result;
        $result{updatetime} = time();
        $result{host} = $_;
        $result{service} = ${$self->{option_results}->{service}}[$i] if (defined(${$self->{option_results}->{service}}[$i]));
        $result{status} = ${$self->{option_results}->{status}}[$i];
        $result{output} = ${$self->{option_results}->{output}}[$i];
        $result{perfdata} = ${$self->{option_results}->{perfdata}}[$i] if (defined(${$self->{option_results}->{perfdata}}[$i]));
        push @{$post_data->{results}}, \%result;
        $i++;
    }

    my ($response, $raw) = $options{custom}->submit_result(post_data => $post_data);

    $self->{global} = { 202 => 0, 400 => 0, 404 => 0 };
    foreach my $result (@{$response->{results}}) {
        $self->{global}->{$result->{code}}++;
    }

    $self->{output}->output_add(long_msg => $raw);
}

1;

__END__

=head1 MODE

Submit one or several results to the API.

Examples:
perl centreon_plugins --plugin=apps::centreon::restapi::plugin --mode=submit-result --hostname=10.30.2.245
--api-username=admin --api-password=centreon --host='MyHost' --service='TheService' --status=2 --output='Hi!'
--perfdata='france=3,brazil=0' --verbose

=over 8

=item B<--host>

Hostname (Mandatory).

=item B<--service>

Service description (If result's for a service).

=item B<--status>

Status in 0, 1, 2, 3 or ok, warning, critical, unknown for services,
or in 0, 1 or up, down for hosts (Mandatory).

=item B<--output>

Short output (Mandatory).

=item B<--perfdata>

Comma separated list of perfdata (Optionnal).

=back

=cut
    
