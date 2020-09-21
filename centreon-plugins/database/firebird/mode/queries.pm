#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package database::firebird::mode::queries;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'queries.total.persecond', set => {
                key_values => [ { name => 'total', per_second => 1 } ],
                output_template => 'Total : %d',
                perfdatas => [
                    { label => 'total', template => '%d', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'seq-reads', nlabel => 'queries.sequentialreads.persecond', set => {
                key_values => [ { name => 'seq_reads', per_second => 1 } ],
                output_template => 'Seq Reads : %d',
                perfdatas => [
                    { label => 'seq_reads', template => '%d', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'inserts', nlabel => 'queries.insert.persecond', set => {
                key_values => [ { name => 'inserts', per_second => 1 } ],
                output_template => 'Inserts : %d',
                perfdatas => [
                    { label => 'inserts', template => '%d', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'updates', nlabel => 'queries.updates.persecond', set => {
                key_values => [ { name => 'updates', per_second => 1 } ],
                output_template => 'Updates : %d',
                perfdatas => [
                    { label => 'updates', template => '%d', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'deletes', nlabel => 'queries.deletes.persecond', set => {
               key_values => [ { name => 'deletes', per_second => 1 } ],
                output_template => 'Deletes : %d',
                perfdatas => [
                    { label => 'deletes', template => '%d', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'backouts', nlabel => 'queries.backout.persecond', set => {
                key_values => [ { name => 'backouts', per_second => 1 } ],
                output_template => 'Backouts : %d',
                perfdatas => [
                    { label => 'backouts', template => '%d', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'purges', nlabel => 'queries.purges.persecond', set => {
                key_values => [ { name => 'purges', per_second => 1 } ],
                output_template => 'Purges : %d',
                perfdatas => [
                    { label => 'purges', template => '%d', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'expunges', nlabel => 'queries.expunges.persecond', set => {
                key_values => [ { name => 'expunges', per_second => 1 } ],
                output_template => 'Expunges : %d',
                perfdatas => [
                    { label => 'expunges', template => '%d', unit => '/s', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Records ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{SELECT MON$RECORD_SEQ_READS as MYREADS,MON$RECORD_INSERTS as MYINSERTS,
        MON$RECORD_UPDATES as MYUPDATES, MON$RECORD_DELETES as MYDELETES, MON$RECORD_BACKOUTS as MYBACKOUTS,
        MON$RECORD_PURGES as MYPURGES, MON$RECORD_EXPUNGES as MYEXPUNGES
        FROM MON$RECORD_STATS mr WHERE mr.MON$STAT_GROUP = '0'}
    );    
    my $row = $options{sql}->fetchrow_hashref();
    if (!defined($row)) {
        $self->{output}->add_option_msg(short_msg => 'Cannot get query informations');
        $self->{output}->option_exit();
    }
    
    $self->{global} = {
        seq_reads => $row->{MYREADS}, inserts => $row->{MYINSERTS}, 
        updates => $row->{MYUPDATES}, deletes => $row->{MYDELETES},
        backouts => $row->{MYBACKOUTS}, purges => $row->{MYPURGES}, expunges => $row->{MYEXPUNGES}
    };
    $self->{global}->{total} = $row->{MYREADS} + $row->{MYINSERTS} + $row->{MYUPDATES} +
        $row->{MYDELETES} + $row->{MYBACKOUTS} + $row->{MYPURGES} + $row->{MYEXPUNGES};

    $self->{cache_name} = 'firebird_' . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check queries statistics on current database. 

=over 8)

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'seq-reads', 'inserts', 'updates',
'deletes', 'backouts', 'purges', 'expunges'. 

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'seq-reads', 'inserts', 'updates',
'deletes', 'backouts', 'purges', 'expunges'.

=back

=cut
