#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infraspathture and application monitoring for
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

package apps::ipfabric::mode::pathverification;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw/is_excluded/;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "source %s destination %s [protocol: %s] state: %s [expected state: %s]",
        $self->{result_values}->{src_ip} . ($self->{result_values}->{src_port} ne '' ? ':' . $self->{result_values}->{src_port} : ''),
        $self->{result_values}->{dst_ip} . ($self->{result_values}->{dst_port} ne '' ? ':' . $self->{result_values}->{dst_port} : ''),
        $self->{result_values}->{protocol},
        $self->{result_values}->{state},
        $self->{result_values}->{expected_state}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0  },
        { name => 'paths', type => 1, message_multiple => 'All paths are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'paths-detected', nlabel => 'paths.detected.count', set => {
                key_values => [ { name => 'detected' }],
                output_template => 'Number of paths detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'paths-mismatch', nlabel => 'paths.mismatch.count', set => {
                key_values => [ { name => 'total_mismatch' } ],
                output_template => 'mismatch: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
       { label => 'paths-state-all', nlabel => 'paths.state.all.count', set => {
                key_values => [ { name => 'all_path' } ],
                output_template => 'all state: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'paths-state-part', nlabel => 'paths.state.part.count', set => {
                key_values => [ { name => 'part_path' } ],
                output_template => 'part state: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'paths-state-none', nlabel => 'paths.state.none.count', set => {
                key_values => [ { name => 'none_path' } ],
                output_template => 'none state: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'paths-state-error', nlabel => 'paths.state.error.count', set => {
                key_values => [ { name => 'error_path' } ],
                output_template => 'error state: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{paths} = [ 
        {
            label => 'status',
            type => 2,
            critical_default => '%{expected_state} ne %{state}',
            set => {
                key_values => [
                    { name => 'src_ip' }, { name => 'src_port' },
                    { name => 'dst_ip' }, { name => 'dst_port' },
                    { name => 'protocol' },
                    { name => 'state' }, { name => 'expected_state' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; }, 
                closure_custom_threshold_check => \&catalog_status_threshold_ng 
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-src-ip:s'   => { name => 'filter_src_ip',   default => '' },
        'filter-src-port:s' => { name => 'filter_src_port', default => '' },
        'filter-dst-ip:s'   => { name => 'filter_dst_ip',   default => '' },
        'filter-dst-port:s' => { name => 'filter_dst_port', default => '' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($indice, $limit) = (0, 1000);

    my $path_raw_form_post = {
        columns => [
            "id",
            "src",
            "srcPorts",
            "dst",
            "dstPorts",
            "protocol",
            "expectedPassingTraffic",
            "passingTraffic"
        ],
        filters => {},
        pagination => {
            limit => $limit,
            start => $indice
        },
        reports => "/technology/routing/path-verifications"
    };  

    $self->{global} = { detected => 0, all_path => 0, error_path => 0, none_path => 0, part_path => 0, total_mismatch => 0 };
    $self->{paths} = {};
    while (1) {
        my $path_state_results = $options{custom}->request_api(
            method => 'POST',
            endpoint => '/networks/path-lookup-checks',
            query_form_post => $path_raw_form_post
        );

        foreach my $route (@{$path_state_results->{data}}) {
            my $dst_port = $route->{dstPorts} // '-';
            my $src_port = $route->{srcPorts} // '-';
            $route->{$_} //= '' foreach qw/src dst/;

            next if is_excluded($route->{src}, $self->{option_results}->{filter_src_ip});
            next if is_excluded($src_port, $self->{option_results}->{filter_src_port});
            next if is_excluded($route->{dst}, $self->{option_results}->{filter_dst_ip});
            next if is_excluded($dst_port, $self->{option_results}->{filter_dst_port});

            $self->{paths}->{ $route->{id} } = {
                dst_ip => $route->{dst},
                dst_port => $dst_port,
                expected_state => $route->{expectedPassingTraffic},
                src_ip => $route->{src},
                src_port => $src_port,
                protocol => $route->{protocol},
                state => $route->{passingTraffic}->{data}
            };

            $self->{global}->{detected}++;

            $self->{global}->{none_path}++
                if $route->{passingTraffic}->{data} eq 'none';

            $self->{global}->{all_path}++
                if $route->{passingTraffic}->{data} eq 'all';

            $self->{global}->{part_path}++
                if $route->{passingTraffic}->{data} eq 'part';

            $self->{global}->{error_path}++
                if $route->{passingTraffic}->{data} eq 'error';

            $self->{global}->{total_mismatch}++
                if $route->{expectedPassingTraffic} ne $route->{passingTraffic}->{data};
        }

        last if scalar(@{$path_state_results->{data}}) < $limit;

        $indice += $limit;
        $path_raw_form_post->{pagination}->{start} = $indice;
    }
}

1;

__END__

=head1 MODE

Check end-to-end path's result against predefined expected state in IP Fabric.

=over 8

=item B<--filter-src-ip>

Filter paths by source IP (regexp can be used).

=item B<--filter-src-port>

Filter paths by source port (regexp can be used).

=item B<--filter-dst-ip>

Filter paths by destination IP (regexp can be used).

=item B<--filter-dst-port>

Filter paths by destination port (regexp can be used).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
Can use special variables like: %{state}, %{expected_state}

For example, if you want a warning alert when the path state is in 'error' then
the option would be: 
--warning-status="%{state} eq 'all'"

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: '%{expected_state} ne %{state}').
Can use special variables like: %{state}, %{expected_state}

For example, if you want a critical alert when the path state is in 'error' then
the option would be: 
--critical-status="%{state} eq 'all'"

=item B<--warning-paths-detected>

Threshold.

=item B<--critical-paths-detected>

Threshold.

=item B<--warning-paths-mismatch>

Threshold.

=item B<--critical-paths-mismatch>

Threshold.

=item B<--warning-paths-state-all>

Threshold.

=item B<--critical-paths-state-all>

Threshold.

=item B<--warning-paths-state-error>

Threshold.

=item B<--critical-paths-state-error>

Threshold.

=item B<--warning-paths-state-none>

Threshold.

=item B<--critical-paths-state-none>

Threshold.

=item B<--warning-paths-state-part>

Threshold.

=item B<--critical-paths-state-part>

Threshold.

=back

=cut
