#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package network::vectra::restapi::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub prefix_dimm_output {
    my ($self, %options) = @_;

    return "Dimm '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'dimm', type => 1, cb_prefix_output => 'prefix_dimm_output', message_multiple => 'All dimm are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

     $self->{maps_counters}->{dimm} = [
        { label => 'dimm-status', type => 2, critical_default => '%{status} !~ /ok/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => 'status: %s',
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

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/health/memory');

    $self->{global} = {
        total => $result->{memory}->{total_bytes},
        used => $result->{memory}->{used_bytes},
        free  => $result->{memory}->{free_bytes},
        prct_used => $result->{memory}->{used_bytes} * 100 / $result->{memory}->{total_bytes},
        prct_free => $result->{memory}->{free_bytes} * 100 / $result->{memory}->{total_bytes}
    };

    $self->{dimm} = {};
    foreach (@{$result->{memory}->{dimm_status}}) {
        $self->{dimm}->{ $_->{dimm} } = {
            name => $_->{dimm},
            status => lc($_->{status})
        };
    }
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--unknown-dimm-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--warning-dimm-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-dimm-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /ok/i').
You can use the following variables: %{status}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds. Can be:
'memory-usage', 'memory-usage-free', 'memory-usage-prct'

=back

=cut
