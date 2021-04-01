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

package hardware::telephony::avaya::cm::snmp::mode::licenses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_station_output {
    my ($self, %options) = @_;

    my $msg = sprintf("station capacity total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'station', type => 0, skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{station} = [
        { label => 'stations-usage', nlabel => 'stations.capacity.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_station_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total', cast_int => 1 },
                ],
            }
        },
        { label => 'stations-usage-free', display_ok => 0, nlabel => 'stations.capacity.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_station_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total', cast_int => 1 },
                ],
            }
        },
        { label => 'stations-usage-prct', display_ok => 0, nlabel => 'stations.capacity.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'station capacity used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
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

my $mapping = {
    avCmCapacityLicStatCapUsed     => { oid => '.1.3.6.1.4.1.6889.2.73.8.1.20.4' },
    avCmCapacityLicStatCapLicLimit => { oid => '.1.3.6.1.4.1.6889.2.73.8.1.20.6' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => 0);

    $self->{station} = {
        total => $result->{avCmCapacityLicStatCapLicLimit},
        used => $result->{avCmCapacityLicStatCapUsed},
        free => $result->{avCmCapacityLicStatCapLicLimit} - $result->{avCmCapacityLicStatCapUsed},
        prct_used => $result->{avCmCapacityLicStatCapUsed} * 100 / $result->{avCmCapacityLicStatCapLicLimit},
        prct_free => ($result->{avCmCapacityLicStatCapLicLimit} - $result->{avCmCapacityLicStatCapUsed}) * 100 / $result->{avCmCapacityLicStatCapLicLimit},
    };
}

1;

__END__

=head1 MODE

Check licenses usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'stations-usage', 'stations-usage-free', 'stations-usage-prct' (%).

=back

=cut
