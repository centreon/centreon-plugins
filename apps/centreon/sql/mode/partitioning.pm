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

package apps::centreon::sql::mode::partitioning;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                  "tablename:s@"        => { name => 'tablename' },
                                  "timezone:s"          => { name => 'timezone' },
                                  "warning:s"           => { name => 'warning' },
                                  "critical:s"          => { name => 'critical' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warn1} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{tablename}) || scalar(@{$self->{option_results}->{tablename}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Please set tablename option.");
        $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $ENV{TZ} = $self->{option_results}->{timezone};
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All table partitions are up to date"));
    foreach my $value (@{$self->{option_results}->{tablename}}) {
        next if ($value eq '');
        if ($value !~ /(\S+)\.(\S+)/) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Wrong table name '%s'", $value));
            next;
        }
        my ($database, $table) = ($1, $2);
        $self->{sql}->query(query => "SELECT MAX(CONVERT(PARTITION_DESCRIPTION, SIGNED INTEGER)) as lastPart FROM INFORMATION_SCHEMA.PARTITIONS WHERE TABLE_NAME='" . $table . "' AND TABLE_SCHEMA='" . $database . "' GROUP BY TABLE_NAME;");
        my ($last_time) = $self->{sql}->fetchrow_array();
        if (!defined($last_time)) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Couldn't get partition infos for table '%s'", $value));
            next;
        }
        
        my $retention_forward_current = 0;
        my ($day,$month,$year) = (localtime(time))[3,4,5];
        my $current_time = mktime(0, 0, 0, $day, $month, $year);
        while ($current_time < $last_time) {
            $retention_forward_current++;
            $current_time = mktime(0, 0, 0, ++$day, $month, $year);
        }
         
        $self->{output}->output_add(long_msg => sprintf("Table '%s' last partition date is %s (current retention forward in days: %s)", $value, scalar(localtime($last_time)), $retention_forward_current));
        my $exit = $self->{perfdata}->threshold_check(value => $retention_forward_current, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Partitions for table '%s' are not up to date (current retention forward in days: %s)", $value, $retention_forward_current));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check that partitions for MySQL/MariaDB tables are correctly created.
The mode should be used with mysql plugin and dyn-mode option.

=over 8

=item B<--tablename>

This option is mandatory (can be multiple).
Example: centreon_storage.data_bin

=item B<--warning>

Threshold warning (number of retention forward days)

=item B<--critical>

Threshold critical (number of retention forward days)

=item B<--timezone>

Timezone use for partitioning (If not set, we use current server execution timezone)

=back

=cut
