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

package network::sonicwall::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'connections', type => 0 },
    ];
    $self->{maps_counters}->{connections} = [
        { label => 'usage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'total' }, { name => 'used' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'connections', value => 'used', template => '%s', 
                      min => 0, max => 'total', threshold_total => 'total', cast_int => 1 },
                ],
            }
        },
    ];
}

sub custom_usage_output {
    my ($self, %options) = @_;
 
    my $msg = sprintf("%.2f%% of the connections cached are used (%d of max. %d)", 
                      $self->{result_values}->{prct_used}, 
                      $self->{result_values}->{used}, 
                      $self->{result_values}->{total});
    return $msg;
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

    my $oid_sonicMaxConnCacheEntries = '.1.3.6.1.4.1.8741.1.3.1.1.0';
    my $oid_sonicCurrentConnCacheEntries = '.1.3.6.1.4.1.8741.1.3.1.2.0';
    
    my $result = $options{snmp}->get_leef(oids => [$oid_sonicMaxConnCacheEntries, $oid_sonicCurrentConnCacheEntries], nothing_quit => 1);

    $self->{connections} = { total => $result->{$oid_sonicMaxConnCacheEntries}, 
                             used => $result->{$oid_sonicCurrentConnCacheEntries}, 
                             prct_used => $result->{$oid_sonicCurrentConnCacheEntries} * 100 / $result->{$oid_sonicMaxConnCacheEntries},
                           };
                      
}

1;

__END__

=head1 MODE

Check Sonicwall connections usage 

=over 8

=item B<--warning-usage>

Threshold warning. Usage (%)

=item B<--critical-usage>

Threshold critical. Usage (%)

=back

=cut
