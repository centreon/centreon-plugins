#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', default => ''},
                                  "critical:s"              => { name => 'critical', default => ''},
                                  "exclude:s"               => { name => 'exclude', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    my @warns = split /,/, $self->{option_results}->{warning};
    my @crits = split /,/, $self->{option_results}->{critical};
    
    foreach my $val (@warns) {
        next if (!defined($val));
        my ($label, $value) = split /=/, $val;
        next if (!defined($label) || !defined($value));
        
        if (($self->{perfdata}->threshold_validate(label => 'warn-' . $label, value => $value)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning ('$label' locks) threshold '" . $value . "'.");
            $self->{output}->option_exit();
        }
    }
    
    foreach my $val (@crits) {
        next if (!defined($val));
        my ($label, $value) = split /=/, $val;
        next if (!defined($label) || !defined($value));
        
        if (($self->{perfdata}->threshold_validate(label => 'crit-' . $label, value => $value)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Critical warning ('$label' locks) threshold '" . $value . "'.");
            $self->{output}->option_exit();
        }
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    $self->{sql}->query(query => q{
SELECT granted, mode, datname FROM pg_database d LEFT JOIN pg_locks l ON (d.oid=l.database) WHERE d.datallowconn
});

    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All databases locks are ok.");

    my $result = $self->{sql}->fetchall_arrayref();
    my $dblocks = {};
    foreach my $row (@{$result}) {        
        my ($granted, $mode, $dbname) = ($$row[0], $$row[1], $$row[2]);
        if (defined($self->{option_results}->{exclude}) && $dbname !~ /$self->{option_results}->{exclude}/) {
            next;
        }
        
        if (!defined($dblocks->{$dbname})) {
            $dblocks->{$dbname} = {total => 0, waiting => 0};
            # Empty. no lock (left join)
            next if (!defined($mode) || $mode eq '');
        }
        $dblocks->{$dbname}->{total}++;
        $mode =~ s{lock$}{};
        $dblocks->{$dbname}->{lc($mode)}++;
        $dblocks->{$dbname}->{waiting}++ if (!$granted);
    }

    foreach my $dbname (keys %$dblocks) {
        foreach my $locktype (keys %{$dblocks->{$dbname}}) {
            $self->{output}->output_add(long_msg => sprintf("Database '%s' lock '%s': %d",
                                                            $dbname, $locktype, $dblocks->{$dbname}->{$locktype}));
            my $exit_code = $self->{perfdata}->threshold_check(value => $dblocks->{$dbname}->{$locktype}, threshold => [ { label => 'crit-' . $locktype, 'exit_litteral' => 'critical' }, { label => 'warn-' . $locktype, exit_litteral => 'warning' } ]);
        
            if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit_code,
                                            short_msg => sprintf("Database '%s' lock '%s': %d",
                                                            $dbname, $locktype, $dblocks->{$dbname}->{$locktype}));
            }
            
            $self->{output}->perfdata_add(label => $dbname . '_' . $locktype,
                                          value => $dblocks->{$dbname}->{$locktype},
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn-' . $locktype),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit-' . $locktype),
                                          min => 0);
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check locks for one or more databases

=over 8

=item B<--warning>

Threshold warning. (example: "total=250,waiting=5,exclusive=20")
'total', 'waiting', or the name of a lock type used by Postgres.

=item B<--critical>

Threshold critical. (example: "total=250,waiting=5,exclusive=20")
'total', 'waiting', or the name of a lock type used by Postgres.

=item B<--exclude>

Filter databases.

=back

=cut
