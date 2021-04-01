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

package apps::video::zixi::restapi::mode::broadcastersystemusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu-load', set => {
                key_values => [ { name => 'cpu_load' } ],
                output_template => 'Cpu Load : %.2f %%',
                perfdatas => [
                    { label => 'cpu_load', value => 'cpu_load', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'memory-usage', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'Memory Used : %.2f %%',
                perfdatas => [
                    { label => 'memory_used', value => 'memory_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'disk-usage', set => {
                key_values => [ { name => 'disk_used' } ],
                output_template => 'Disk Used : %.2f %%',
                perfdatas => [
                    { label => 'disk_used', value => 'disk_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    my $result = $options{custom}->get(path => '/sys_load.json');
    $self->{global} = { disk_used => $result->{disk_space}, cpu_load => $result->{cpu_load}, memory_used => $result->{memory_use} };
}

1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^disk-usage$'

=item B<--warning-*>

Threshold warning.
Can be: 'disk-usage' (%), 'memory-usage' (%), 'cpu-load' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'disk-usage' (%), 'memory-usage' (%), 'cpu-load' (%).

=back

=cut
