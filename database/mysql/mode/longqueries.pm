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

package database::mysql::mode::longqueries;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'warning:s'        => { name => 'warning', },
        'critical:s'       => { name => 'critical', },
        'seconds:s'        => { name => 'seconds', default => 60 },
        'filter-user:s'    => { name => 'filter_user' },
        'filter-command:s' => { name => 'filter_command', default => '^(?!(sleep)$)' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{seconds}) || $self->{option_results}->{seconds} !~ /^[0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "Please set the option --seconds.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    $self->{sql}->query(query => q{SELECT USER, COMMAND, TIME, INFO FROM information_schema.processlist ORDER BY TIME DESC});
    my $long_queries = 0;
    my @queries = ();
    
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        next if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
                 $row->{USER} !~ /$self->{option_results}->{filter_user}/i);
        next if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne '' &&
                 $row->{COMMAND} !~ /$self->{option_results}->{filter_command}/i);
        if (defined($self->{option_results}->{seconds}) && $self->{option_results}->{seconds} ne '' && $row->{TIME} >= $self->{option_results}->{seconds}) {
            push @queries, { time => $row->{TIME}, query => $row->{INFO} };
            $long_queries++;
        }
    }
    
    my $exit_code = $self->{perfdata}->threshold_check(value => $long_queries, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    
    $self->{output}->output_add(
        severity => $exit_code,
        short_msg => sprintf(
            "%s queries over %s seconds",
            $long_queries, $self->{option_results}->{seconds}
        )
    );
    $self->{output}->perfdata_add(
        label => 'longqueries',
        value => $long_queries,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );
    
    for (my $i = 0; $i < 10 && $i < scalar(@queries); $i++) {
        $queries[$i]->{query} =~ s/\|/-/mg if (defined($queries[$i]->{query}));
        $self->{output}->output_add(long_msg =>
            sprintf(
                "[time: %s] [query: %s]",
                $queries[$i]->{time}, 
                defined($queries[$i]->{query}) ? substr($queries[$i]->{query}, 0, 1024) : '-'
            )
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check current number of long queries.

=over 8

=item B<--warning>

Threshold warning (number of long queries).

=item B<--critical>

Threshold critical (number of long queries).

=item B<--seconds>

The minimum execution time in seconds for a long query (Default: 60).

=item B<--filter-user>

Filter by user (can be a regexp).

=item B<--filter-command>

Filter by command (can be a regexp. Default: '^(?!(sleep)$)').

=back

=cut
