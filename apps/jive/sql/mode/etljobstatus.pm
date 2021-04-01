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

package apps::jive::sql::mode::etljobstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $thresholds = {
    status => [
        ['^1$', 'OK'],
        ['^3$', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "retention:s"             => { name => 'retention', default => 1 },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('status', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    my $retention = $self->{option_results}->{retention};
    # CURRENT_TIMESTAMP should be compatible with the jive databases: Oracle, MS SQL, MySQL, Postgres.
    # INTERVAL also.
    my $query = q{SELECT etl_job_id, state, start_ts, end_ts FROM jivedw_etl_job WHERE start_ts > CURRENT_TIMESTAMP -  INTERVAL '} . $retention . q{' DAY};
    $self->{sql}->query(query => $query);
    my $job_etl_problems = {};
    my $total_problems = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $exit = $self->get_severity(section => 'status', value => $row->{state});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(long_msg => sprintf("%s: job '%i' state is %s [start_time: %s]", $exit, $row->{etl_job_id}, $row->{state}, $row->{start_ts}));
            $job_etl_problems->{$exit} = 0 if (!defined($job_etl_problems->{$exit}));
            $job_etl_problems->{$exit}++;
            $total_problems++;
         }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'no job etl problems');
    foreach (keys %{$job_etl_problems}) {
        $self->{output}->output_add(severity => $_,
                                    short_msg => sprintf("job etl had %i problems during the last %i days", $job_etl_problems->{$_}, $self->{option_results}->{retention}));
    }
    
    $self->{output}->perfdata_add(label => 'job_etl_problems',
                                  value => $total_problems,
                                  min => 0);

    $self->{output}->display();
    $self->{output}->exit();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check jive ETL job status.
Please use with dyn-mode option.

=over 8

=item B<--retention>

Retention in days (default : 1).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(1)$)'

=back

=cut
