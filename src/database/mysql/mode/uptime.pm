#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package database::mysql::mode::uptime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    # Adding options specific to this mode
    $options{options}->add_options(arguments => {
        "warning:s"  => { name => 'warning' },
        "critical:s" => { name => 'critical' },
        "seconds"    => { name => 'seconds' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    # Validating warning threshold
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }

    # Validating critical threshold
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $options{sql}->connect();

    # Checking if MySQL version is supported
    if (!($options{sql}->is_version_minimum(version => '5'))) {
        $self->{output}->add_option_msg(short_msg => "MySQL version '" . $self->{sql}->{version} . "' is not supported (need version >= '5.x').");
        $self->{output}->option_exit();
    }

    # Querying MySQL for Uptime status
    $options{sql}->query(query => q{SHOW /*!50000 global */ STATUS LIKE 'Uptime'});
    my ($name, $value) = $options{sql}->fetchrow_array();

    # Handling case where uptime value is not available
    if (!defined($value)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get uptime.");
        $self->{output}->option_exit();
    }

    # Checking the threshold and determining exit code
    my $exit_code = $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    # Calculating uptime in days or seconds based on user preference
    my $uptime_days = floor($value / 86400);
    my $msg = sprintf("database is up since %d days", $uptime_days);
    if (defined($self->{option_results}->{seconds})) {
        $msg = sprintf("database is up since %d seconds", $value);
    }

    # Adding start time information to the message
    $msg .= sprintf(" (Start time = %s)", strftime("%Y/%m/%d %H:%M:%S", localtime(time - $value)));

    # Adding output message and performance data
    $self->{output}->output_add(
        severity => $exit_code,
        short_msg => $msg
    );

    $self->{output}->perfdata_add(
        label => 'uptime',
        nlabel => 'database.uptime.seconds',
        unit => 's',
        value => $value,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    # Displaying the output and exiting
    $self->{output}->display();

    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check MySQL uptime.

=over 8

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=item B<--seconds>

Display uptime in seconds.

=back

=cut
