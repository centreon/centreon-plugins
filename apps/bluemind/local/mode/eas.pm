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

package apps::bluemind::local::mode::eas;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use bigint;

sub prefix_eas_output {
    my ($self, %options) = @_;
    
    return 'Mobile connection service ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_eas', type => 0, cb_prefix_output => 'prefix_eas_output' }
    ];
    
    $self->{maps_counters}->{bm_eas} = [
        { label => 'responses-size-total', nlabel => 'eas.responses.size.total.bytes', display_ok => 0, set => {
                key_values => [ { name => 'response_size', diff => 1 } ],
                output_template => 'total responses size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'response_size', template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'execution-total', nlabel => 'eas.execution.total.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'execution_total', diff => 1 } ],
                output_template => 'total execution: %s ms',
                perfdatas => [
                    { value => 'execution_total', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        },
        { label => 'execution-mean', nlabel => 'eas.execution.mean.milliseconds', set => {
                key_values => [ { name => 'execution_mean' } ],
                output_template => 'mean execution: %s ms',
                perfdatas => [
                    { value => 'execution_mean', template => '%s', min => 0, unit => 'ms' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # bm-eas.executionTime,meterType=Timer count=23865528,totalTime=48394780739993049,mean=2027811022
    # bm-eas.responseSize,meterType=DistSum count=31508001,totalAmount=736453775233,mean=23373
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-eas.sock http://127.0.0.1/metrics',
        filter => 'executionTime|responseSize'
    );

    $self->{bm_eas} = {};
    foreach (keys %$result) {
        $self->{bm_eas}->{response_size} = $result->{$_}->{totalAmount} if (/bm-eas.responseSize/);
        if (/bm-eas\.executionTime/) {
            $self->{bm_eas}->{execution_total} = $result->{$_}->{totalTime} / 100000;
            $self->{bm_eas}->{execution_mean} = $result->{$_}->{mean} / 100000;
        }
    }

    $self->{cache_name} = 'bluemind_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check mobile connection service.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^execution'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'responses-size-total', 'execution-total', 'execution-mean'.

=back

=cut
