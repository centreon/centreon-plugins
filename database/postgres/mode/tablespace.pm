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

package database::postgres::mode::tablespace;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_tablespace_output {
    my ($self, %options) = @_;

    return "Tablespace '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tablespaces', type => 1, cb_prefix_output => 'prefix_tablespace_output', message_multiple => 'All tablespaces are ok' }
    ];

    $self->{maps_counters}->{tablespaces} = [
        { label => 'space-usage', nlabel => 'tablespace.space.usage.bytes', set => {
                key_values => [ { name => 'space_used' } ],
                output_template => 'space used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B', label_extra_instance => 1 }
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
        'filter-sql-name:s' => { name => 'filter_sql_name' },
        'filter-name:s'     => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    my $query = 'SELECT spcname, pg_tablespace_size(spcname) FROM pg_tablespace';
    if (defined($self->{option_results}->{filter_sql_name}) && $self->{option_results}->{filter_sql_name} ne '') {
        $query .= ' WHERE spcname LIKE ' . $options{sql}->quote($self->{option_results}->{filter_sql_name});
    }
    $options{sql}->query(query => $query);

    $self->{tablespaces} = {};
    while (my @row = $options{sql}->fetchrow_array()) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $row[0] !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping tablespace '" . $row[0] . "': no matching filter.", debug => 1);
            next;
        }

        $self->{tablespaces}->{ $row[0] } = {
            display => $row[0],
            space_used => $row[1]
        };
    }
}

1;

__END__

=head1 MODE

Check a tablespaces.

=over 8

=item B<--filter-sql-name>

Filter tablespace name directly in sql query (LIKE sql syntax used).

=item B<--filter-name>

Filter tablespace name after getting all tablespaces (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B).

=back

=cut
