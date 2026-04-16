#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package database::postgres::mode::locks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::constants qw(:values);
use centreon::plugins::misc qw/is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'           => { name => 'warning', default => '' },
        'critical:s'          => { name => 'critical', default => '' },
        'include-database:s'  => { name => 'include_database', default => '' },
        'exclude-database:s'  => { name => 'exclude_database', default => '' },
        'include:s'           => { name => 'include_database' },
        'exclude:s'           => { name => 'exclude_database' }
    });

    return $self;
}

sub custom_locks_prefix_output {
    my ($self, %options) = @_;
    sprintf("Database '%s' ", $options{instance});
}

sub custom_locks_perfdata {
    my ($self, %options) = @_;

    my $locktype = $options{locktype};
    $self->{output}->perfdata_add(
                nlabel => "database.locks.$locktype.count",
                instances => $self->{result_values}->{database},
                value => $self->{result_values}->{$locktype},
                warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn-' . $locktype),
                critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit-' . $locktype),
                min => 0
            );

}

sub custom_threshold_check {
    my ($self, %options) = @_;

    my $locktype = $options{locktype};

    $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{$locktype},
        threshold => [
           { label => 'crit-' . $locktype, exit_litteral => 'critical' },
           { label => 'warn-' . $locktype, exit_litteral => 'warning' }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'locks', type => 1, cb_prefix_output => 'custom_locks_prefix_output', message_multiple => 'All databases locks are ok',  skipped_code => { NO_VALUE() => 1 }  },
    ];

    $self->{items} = { 'total', 'warning' };

    $self->{maps_counters}->{locks} = [
        { label => 'total', nlabel => 'database.locks.total.count', set => {
                key_values => [ { name => 'total' }, { name => 'database' } ],
                threshold_use => 'total',
                closure_custom_threshold_check => sub { custom_threshold_check(@_, locktype => 'total') },
                output_template => "lock 'total':%s",
                perfdatas => [
                    { template => '%s', min => 0, unit => '', label_extra_instance => 1  },
                ],
            }
        },
        { label => 'waiting', nlabel => 'database.locks.waiting.count', set => {
                key_values => [ { name => 'waiting' }, { name => 'database' } ],
                threshold_use => 'waiting',
                closure_custom_threshold_check => sub { custom_threshold_check(@_, locktype => 'waiting') },
                output_template => "lock 'waiting':%s", output_error_templete => '',
                perfdatas => [
                    { template => '%s', min => 0, unit => '', label_extra_instance => 1 },
                ],
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    my @warns = split /,/, $self->{option_results}->{warning};
    my @crits = split /,/, $self->{option_results}->{critical};

    foreach my $val (@warns) {
        next unless $val;
        my ($label, $value) = split /=/, $val;
        next if (!defined($label) || !defined($value));
        
        $self->{output}->option_exit(short_msg => "Wrong warning ('$label' locks) threshold '" . $value . "'.")
            unless $self->{perfdata}->threshold_validate(label => 'warn-' . $label, value => $value);
    }
    
    foreach my $val (@crits) {
        next unless $val;
        my ($label, $value) = split /=/, $val;
        next if (!defined($label) || !defined($value));
        
        $self->{output}->option_exit(short_msg => "Critical warning ('$label' locks) threshold '" . $value . "'.")
            unless $self->{perfdata}->threshold_validate(label => 'crit-' . $label, value => $value);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();

    $options{sql}->query(query => q{
        SELECT granted, mode, datname FROM pg_database d LEFT JOIN pg_locks l ON (d.oid=l.database) WHERE d.datallowconn
    });

    my $result = $options{sql}->fetchall_arrayref();
    my $dblocks = {};
    foreach my $row (@{$result}) {        
        my ($granted, $mode, $dbname) = ($$row[0], $$row[1], $$row[2]);
        next if is_excluded($dbname, $self->{option_results}->{include_database}, $self->{option_results}->{exclude_database});
        if (!defined($dblocks->{$dbname})) {
            $dblocks->{$dbname} = {total => 0, waiting => 0, database => $dbname };
            # Empty. no lock (left join)
            next unless $mode;
        }
        $dblocks->{$dbname}->{total}++;
        $mode = lc $mode =~ s/lock$//ir;
        $dblocks->{$dbname}->{$mode}++;
        $dblocks->{$dbname}->{waiting}++ if (!$granted);

        unless ($self->{items}->{$mode}) {
            $self->{items}->{$mode} = 1;
            my $new_counter = {  label => $mode, nlabel => "database.locks.$mode.count",
                                 set => {
                                    key_values => [ { name => $mode }, { name => 'database' } ],
                                    output_template => "lock '$mode':%s",
                                    closure_custom_threshold_check => sub { custom_threshold_check(@_, locktype => $mode) },
                                    closure_custom_perfdata        => sub { custom_locks_perfdata(@_, locktype => $mode) },
                                 }
                              };
            $new_counter->{obj} = centreon::plugins::values->new( output => $self->{output},
                                                                  perfdata => $self->{perfdata},
                                                                  label => $new_counter->{label},
                                                                  nlabel => $new_counter->{nlabel},
                                                                  thlabel => $new_counter->{label} );
            $new_counter->{obj}->set( %{$new_counter->{set}} );

            push @{$self->{maps_counters}->{locks}}, $new_counter;
        }
    }

    $self->{locks} = $dblocks;
}

1;

__END__

=head1 MODE

Check locks for one or more databases

=over 8

=item B<--warning>

Warning threshold. (example: "total=250,waiting=5,exclusive=20")
'total', 'waiting', or the name of a lock type used by PostgreSQL.

=item B<--critical>

Critical threshold. (example: "total=250,waiting=5,exclusive=20")
'total', 'waiting', or the name of a lock type used by PostgreSQL.

=item B<--include-database>

Filter databases using a regular expression.

=item B<--exclude-database>

Exclude databases using a regular expression.

=back

=cut
