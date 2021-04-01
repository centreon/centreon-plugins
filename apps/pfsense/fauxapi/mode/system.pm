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

package apps::pfsense::fauxapi::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_tcp_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        'tcp connections total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{tcp_conn_total},
        $self->{result_values}->{tcp_conn_used}, $self->{result_values}->{tcp_conn_used_prct},
        $self->{result_values}->{tcp_conn_free}, $self->{result_values}->{tcp_conn_free_prct}
    );
    return $msg;
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'System ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'connections-tcp-usage', nlabel => 'system.connections.tcp.usage.count', set => {
                key_values => [
                    { name => 'tcp_conn_used' }, { name => 'tcp_conn_total' },
                    { name => 'tcp_conn_free' }, { name => 'tcp_conn_used_prct' },
                    { name => 'tcp_conn_free_prct' }
                ],
                closure_custom_output => $self->can('custom_tcp_usage_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'tcp_conn_total' }
                ]
            }
        },
        { label => 'connections-tcp-usage-prct', nlabel => 'system.connections.tcp.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'tcp_conn_used_prct' } ],
                output_template => 'tcp connections used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'temperature', nlabel => 'system.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C' }
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
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(action => 'system_stats');

    $self->{global} = {};
    if (defined($results->{data}->{stats})) {
        if ($results->{data}->{stats}->{pfstate} =~ /^(\d+)\/(\d+)/) {
            $self->{global}->{tcp_conn_used} = $1;
            $self->{global}->{tcp_conn_total} = $2;
            $self->{global}->{tcp_conn_free} = $2 - $1;
            $self->{global}->{tcp_conn_used_prct} = $1 * 100 / $2;
            $self->{global}->{tcp_conn_free_prct} = 100 - $self->{global}->{tcp_conn_used_prct};
        }
        $self->{global}->{temperature} = $results->{data}->{stats}->{temp};
    }
}

1;

__END__

=head1 MODE

Check system.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='temperature'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'temperature' (C), 'connections-tcp-usage', 'connections-tcp-usage-prct' (%).

=back

=cut
