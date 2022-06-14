#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "%s:%s_%s:%s [State: %s], [Expected State: %s]",
        $self->{result_values}->{src_ip},
        $self->{result_values}->{src_port},
        $self->{result_values}->{dest_ip},
        $self->{result_values}->{dest_port},
        $self->{result_values}->{state},
        $self->{result_values}->{expected_state}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0,cb_prefix_output => undef, cb_init => undef },
        { name => 'status', type => 1, cb_prefix_output => 'prefix_status_output', message_multiple => 'All paths are OK. ' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-path', nlabel => 'total.path.count', set => {
                key_values => [ { name => 'total_path' }],
                output_template => 'Total number of paths: %s',
                perfdatas => [
                    { label => 'total_path', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-mismatch', nlabel => 'total.path.mismatch.count', set => {
                key_values => [ { name => 'total_mismatch' } ],
                output_template => 'Total mismatch: %s',
                perfdatas => [
                    { label => 'total_mismatch', template => '%s', min => 0 }
                ]
            }
        },
       { label => 'all-path', nlabel => 'total.path.all.count', set => {
                key_values => [ { name => 'all_path' } ],
                output_template => 'Number of paths in All state: %s',
                perfdatas => [
                    { label => 'all_path', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'part-path', nlabel => 'total.path.part.count', set => {
                key_values => [ { name => 'part_path' } ],
                output_template => 'Number of paths in Part state: %s',
                perfdatas => [
                    { label => 'part_path', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'none-path', nlabel => 'total.path.none.count', set => {
                key_values => [ { name => 'none_path' } ],
                output_template => 'Number of paths in None state: %s',
                perfdatas => [
                    { label => 'none_path', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'error-path', nlabel => 'total.path.error.count', set => {
                key_values => [ { name => 'error_path' } ],
                output_template => 'Number of paths in Error state: %s',
                perfdatas => [
                    { label => 'error_path', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [ 
        {
            label => 'status',
            type => 2,
            critical_default => '%{expected_state} ne %{state}',
            set => {
                key_values => [
                    { name => 'src_ip' },
                    { name => 'src_port' }, { name => 'dest_ip' },
                    { name => 'dest_port' }, { name => 'state' },
                    { name => 'expected_state' }
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
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $path_state;

    $self->{global}->{all_path} = 0;
    $self->{global}->{error_path} = 0;
    $self->{global}->{none_path} = 0;
    $self->{global}->{part_path} = 0;
    $self->{global}->{total_mismatch} = 0;

    my $path_raw_form_post = {
        "columns" => [
            "id",
            "src",
            "srcPorts",
            "dst",
            "dstPorts",
            "expectedPassingTraffic",
            "passingTraffic"
        ],
        "filters" => {},
        "pagination" => {
            "limit" => undef,
            "start" => 0
        },
        "reports" => "/technology/routing/path-verifications"
    };  

    my $path_state_results = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/networks/path-lookup-checks',
        query_form_post => $path_raw_form_post
    );

    foreach my $route (@{$path_state_results->{data}}) {
        $path_state->{$route->{id}} = {
            id => $route->{id},
            dest_ip => $route->{dst},
            dest_port => $route->{dstPorts},
            expected_state => $route->{expectedPassingTraffic},
            src_ip => $route->{src},
            src_port => $route->{srcPorts},
            state => $route->{passingTraffic}->{data}
        };
        if ($path_state->{$route->{id}}->{expected_state} ne $path_state->{$route->{id}}->{state}){
            $self->{global}->{total_mismatch}++;
        }
    }

    if (scalar(keys %$path_state) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No path found.");
        $self->{output}->option_exit();
    }
    
    foreach my $id (keys %$path_state) {

        my $dest_port = (defined($path_state->{$id}->{dest_port})) ? $path_state->{$id}->{dest_port} : 'empty';
        my $src_port = (defined($path_state->{$id}->{src_port})) ? $path_state->{$id}->{src_port} : 'empty';

        my $instance = $path_state->{$id}->{src_ip} . ":" . $src_port . "_" . $path_state->{$id}->{dest_ip} . ":" . $dest_port;

        $self->{status}->{$instance} = {
            dest_ip => $path_state->{$id}->{dest_ip},
            dest_port => $dest_port,
            expected_state => $path_state->{$id}->{expected_state},
            src_ip => $path_state->{$id}->{src_ip},
            src_port => $src_port,
            state => $path_state->{$id}->{state}
        };
        $self->{global}->{total_path}++;
        if ($path_state->{$id}->{state} eq "none"){
            $self->{global}->{none_path}++;
        }
        if ($path_state->{$id}->{state} eq "all"){
            $self->{global}->{all_path}++;
        }
        if ($path_state->{$id}->{state} eq "part"){
            $self->{global}->{part_path}++;
        }
        if ($path_state->{$id}->{state} eq "error"){
            $self->{global}->{error_path}++;
        }       
    }

}

1;

__END__

=head1 MODE

Check end-to-end path's result against predefined expected state in IP Fabric.

=over 8

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{state}, %{expected_state}

For example, if you want a warning alert when the path state is in 'error' then
the option would be: 
--warning-status="%{state} eq 'all'"

=item B<--critical-status>

Set critical threshold for status. (Default: '%{expected_state} ne %{state}').
Can use special variables like: %{state}, %{expected_state}

For example, if you want a critical alert when the path state is in 'error' then
the option would be: 
--critical-status="%{state} eq 'all'"

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-path', 'total-mismatch',
'error-path', 'none-path', 'part-path',
'all-path'

=back

=cut
