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

package network::sonicwall::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory_usage', type => 0 },
    ];
    
    $self->{maps_counters}->{memory_usage} = [
        { label => 'usage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Memory Usage %.2f %%',
                perfdatas => [
                    { label => 'memory', value => 'prct_used', template => '%.2f',
                      unit => '%', min => 0, max => 100 },
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

    my $oid_sonicCurrentRAMUtil = '.1.3.6.1.4.1.8741.1.3.1.4.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_sonicCurrentRAMUtil], nothing_quit => 1);

    $self->{memory_usage} = { prct_used => $snmp_result->{$oid_sonicCurrentRAMUtil} };
}

1;

__END__

=head1 MODE

Check Memory usage. 

=over 8

=item B<--warning-usage>

Threshold warning. (percent)

=item B<--critical-usage>

Threshold critical. (percent)

=back

=cut
