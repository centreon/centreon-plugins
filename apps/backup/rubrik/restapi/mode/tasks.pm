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

package apps::backup::rubrik::restapi::mode::tasks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Tasks last 24 hours ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'succeeded', nlabel => 'tasks.succeeded.24h.count', set => {
                key_values => [ { name => 'succeeded' } ],
                output_template => 'succeeded: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
                ]
            }
        },
        { label => 'failed', nlabel => 'tasks.failed.24h.count', set => {
                key_values => [ { name => 'failed' } ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
                ]
            }
        },
        { label => 'canceled', nlabel => 'tasks.canceled.24h.count', set => {
                key_values => [ { name => 'canceled' } ],
                output_template => 'canceled: %s',
                perfdatas => [
                    { template => '%s',  min => 0 }
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

    my $reports = $options{custom}->request_api(endpoint => '/report');
    my $report_id;
    foreach (@{$reports->{data}}) {
        if ($_->{name} eq 'Protection Tasks Details') {
            $report_id = $_->{id};
            last;
        }
    }
    if (!defined($report_id)) {
        $self->{output}->add_option_msg(short_msg => "Cannot find report name 'Protection Tasks Details'");
        $self->{output}->option_exit();
    }

    my $tasks = $options{custom}->request_api(
        endpoint => '/report/' . $report_id . '/chart',
        get_param => ['timezone_offset=0', 'chart_id=chart0']
    );

    $self->{global} = {};
    foreach (@{$tasks->[0]->{dataColumns}}) {
        $self->{global}->{ lc($_->{label}) } = $_->{dataPoints}->[0]->{value};
    }

}

1;

__END__

=head1 MODE

Check tasks.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='failed'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'succeeded', 'failed', 'canceled'.

=back

=cut
