#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package database::mssql::mode::cachehitratio;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'hit_ratio', type => 0 },
    ];

    $self->{maps_counters}->{hit_ratio} = [
        { label => 'hit-ratio', nlabel => 'mssql.cache.hitratio.percentage', set => {
                key_values => [ { name => 'value' } ],
                output_template => 'Buffer cache hit ratio is %.2f%%',
                perfdatas => [
                    { template => '%s', unit => '%', min => 0, max => 100 },
                ],
            }
        },
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

    $options{sql}->connect();
    $options{sql}->query(query => q{
        SELECT CAST(
            (
                SELECT CAST (cntr_value AS BIGINT)
                FROM sys.dm_os_performance_counters  
                WHERE counter_name = 'Buffer cache hit ratio'
            )* 100.00
            /
            (
                SELECT CAST (cntr_value AS BIGINT)
                FROM sys.dm_os_performance_counters  
                WHERE counter_name = 'Buffer cache hit ratio base'
            ) AS NUMERIC(6,3)
        )
    });

    my $hitratio = $options{sql}->fetchrow_array();
    $self->{hit_ratio}->{value} = $hitratio;

}

1;

__END__

=head1 MODE

Check MSSQL buffer cache hit ratio.

=over 8

=item B<--warning-hit-ratio>

Warning threshold.

=item B<--critical-hit-ratio>

Critical threshold.

=back

=cut
