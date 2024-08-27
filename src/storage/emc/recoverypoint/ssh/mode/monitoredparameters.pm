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

package storage::emc::recoverypoint::ssh::mode::monitoredparameters;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'min-severity:s' => { name => 'min_severity', default => 'minor' },
        'warning:s'      => { name => 'warning' },
        'critical:s'     => { name => 'critical' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname.");
        $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if ($self->{option_results}->{min_severity} !~ /^(minor|major|critical)$/) {
        $self->{output}->add_option_msg(short_msg => 'Min-severity must be minor, major or critical.');
        $self->{output}->option_exit();
    } 
}

sub run {
    my ($self, %options) = @_;

    my $min_severity = 'min_severity=' . $self->{option_results}->{min_severity};

    my ($stdout) = $options{custom}->execute_command(
        command => 'get_monitored_parameters',
        command_options => $min_severity
    );

    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;

    my $count = 0;
    foreach (split(/\n/, $stdout)) {
        if (/^\s*Type:/im) {
            $count++;
        }
    }    

    my $exit_code = $self->{perfdata}->threshold_check(value => $count, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(long_msg => $long_msg);
    $self->{output}->output_add(
        severity => $exit_code, 
        short_msg => sprintf(
            "%i problems found.",
            $count
        )
    );

    $self->{output}->perfdata_add(
        label => "problems",
        value => $count,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check monitored parameters by RecoveryPoint Appliance.

Command used: 'get_monitored_parameters min_severity=%(min_severity)'

=over 8

=item B<--min-severity>

Minimum severity level you want to count (default: minor).
Can be 'minor', 'major' or 'critical'.

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=back

=cut
