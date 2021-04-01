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

package database::postgres::mode::databasesize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_database_output', message_multiple => 'All databases are ok' },
    ];

    $self->{maps_counters}->{databases} = [
        { label => 'size', set => {
                key_values => [ { name => 'size' }, { name => 'display' } ],
                output_template => 'size : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'size', value => 'size', template => '%s',
                      min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' },
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
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
    
    $self->{sql} = $options{sql};
    $self->{sql}->connect();
    $self->{sql}->query(query => "SELECT pg_database.datname, pg_database_size(pg_database.datname) FROM pg_database;");

    my $result = $self->{sql}->fetchall_arrayref();

    $self->{databases} = {};

    foreach my $row (@$result) {
        next if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' 
            && $$row[0] !~ /$self->{option_results}->{filter_database}/);
        
        $self->{databases}->{$$row[0]}->{display} = $$row[0];
        $self->{databases}->{$$row[0]}->{size} = $$row[1];
    }

    if (scalar(keys %{$self->{databases}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No databases found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check databases size

=over 8

=item B<--filter-database>

Filter database to checks (Can use regexp).

=item B<--warning-size>

Threshold warning in bytes, maximum size allowed.

=item B<--critical-size>

Threshold critical in bytes, maximum size allowed.

=back

=cut
