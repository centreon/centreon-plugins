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

package database::influxdb::mode::databasestatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_database_output',
          message_multiple => 'All databases statistics are ok' },
    ];

    $self->{maps_counters}->{databases} = [
        { label => 'measurements', nlabel => 'database.measurements.count', set => {
                key_values => [ { name => 'numMeasurements' }, { name => 'display' } ],
                output_template => 'Measurements: %s',
                perfdatas => [
                    { value => 'numMeasurements', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'series', nlabel => 'database.series.count', set => {
                key_values => [ { name => 'numSeries' }, { name => 'display' } ],
                output_template => 'Series: %s',
                perfdatas => [
                    { value => 'numSeries', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-database:s"   => { name => 'filter_database' },
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{custom} = $options{custom};

    $self->{databases} = {};
    
    my $results = $self->{custom}->query(queries => [ "SHOW STATS FOR 'database'" ]);
    
    foreach my $database (@{$results}) {
        next if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' 
            && $database->{tags}->{database} !~ /$self->{option_results}->{filter_database}/);
        
        $self->{databases}->{$database->{tags}->{database}}->{display} = $database->{tags}->{database};

        my $i = 0;
        foreach my $column (@{$database->{columns}}) {
            $column =~ s/influxdb_//;
            $self->{databases}->{$database->{tags}->{database}}->{$column} = $database->{values}[0][$i];
            $i++;
        }
    }

    if (scalar(keys %{$self->{databases}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No databases found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check databases statistics

=over 8

=item B<--filter-database>

Filter database name (Can use regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'measurements', 'series'.

=item B<--critical-*>

Threshold warning.
Can be: 'measurements', 'series'.

=back

=cut
