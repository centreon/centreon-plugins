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

package database::mysql::mode::queries;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
   
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' },
    ];
   
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'queries.total.persecond', set => {
                key_values => [ { name => 'Queries', per_second => 1 } ],
                output_template => 'Total : %d',
                perfdatas => [
                    { label => 'total_requests', template => '%d', unit => '/s', min => 0 },
                ],
            }
        },
    ];
    
    foreach ('update', 'delete', 'insert', 'truncate', 'select', 'commit', 'begin') {
        push @{$self->{maps_counters}->{global}}, {
            label => $_, nlabel => 'queries.' . $_ . '.persecond',  display_ok => 0, set => {
                key_values => [ { name => 'Com_' . $_, per_second => 1 } ],
                output_template => $_ . ' : %d',
                perfdatas => [
                    { label => $_ . '_requests', template => '%d', unit => '/s', min => 0 }
                ]
            }
        };
        push @{$self->{maps_counters}->{global}}, {
            label => $_ . '-count', , nlabel => 'queries.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => 'Com_' . $_, diff => 1 } ],
                output_template => $_ . ' count : %d',
                perfdatas => [
                    { label => $_ . '_count', template => '%d', min => 0 }
                ]
            }
        };
    }
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Requests ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    if (!($options{sql}->is_version_minimum(version => '5.0.76'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported (need version >= '5.0.76').");
        $self->{output}->option_exit();
    }
    
    $options{sql}->query(query => q{
        SHOW /*!50000 global */ STATUS WHERE Variable_name IN ('Queries', 'Com_update', 'Com_delete', 'Com_insert', 'Com_truncate', 'Com_select', 'Com_commit', 'Com_begin')
    });

    $self->{global} = {};
    my $result = $options{sql}->fetchall_arrayref();
    foreach my $row (@{$result}) {
        $self->{global}->{$$row[0]} = $$row[1];
    }

    $self->{cache_name} = "mysql_" . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check average number of queries executed.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'update', 'insert', 'delete', 'truncate',
'select', 'begin', 'commit'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'update', 'insert', 'delete', 'truncate',
'select', 'begin', 'commit'.

=back

=cut
