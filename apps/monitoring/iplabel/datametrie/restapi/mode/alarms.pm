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

package apps::monitoring::iplabel::datametrie::restapi::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_alarm_output {
    my ($self, %options) = @_;
    
    return 'current alarms ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_alarm_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'black', nlabel => 'alarms.black.count', set => {
                key_values => [ { name => 'black' } ],
                output_template => 'black: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'red', nlabel => 'alarms.red.count', set => {
                key_values => [ { name => 'red' } ],
                output_template => 'red: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'orange', nlabel => 'alarms.orange.count', set => {
                key_values => [ { name => 'orange' } ],
                output_template => 'orange: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status', ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(
        endpoint => '/Get_Current_Alarms_All_Monitors/',
        label => 'Get_Current_Alarms_All_Monitors'
    );

    $self->{global} = { orange => 0, red => 0, black => 0 };
    return if (ref($results) ne 'ARRAY');

    foreach (@$results) {
        $self->{global}->{ lc($_->{ALARM_TYPE}) }++ if (defined($self->{global}->{ lc($_->{ALARM_TYPE}) }));
    }
}

1;

__END__

=head1 MODE

Check current alarms.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='black'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'black', 'red', 'orange'.

=back

=cut
