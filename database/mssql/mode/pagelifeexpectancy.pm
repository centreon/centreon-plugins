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

package database::mssql::mode::pagelifeexpectancy;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'page-life-expectancy', nlabel => 'page.life.expectancy.seconds', set => {
            key_values => [ { name => 'page_life_expectancy'}],
            output_template => 'Page life expectancy : %d second(s)',
            perfdatas => [
                { value => 'page_life_expectancy', template => '%d', unit => 's', min => 0 },
            ]
        }}
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
        SELECT
            cntr_value
        FROM
            sys.dm_os_performance_counters
        WHERE
            counter_name = 'Page life expectancy'
        AND
            object_name LIKE '%Manager%'
    });

    $self->{global}->{page_life_expectancy} = $options{sql}->fetchrow_array();
}

1;

__END__

=head1 MODE

Check MSSQL page life expectancy.

=over 8

=item B<--warning-page-life-expectancy>

Threshold warning.

=item B<--critical-page-life-expectancy>

Threshold critical.

=back

=cut
