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

package hardware::server::ibm::hmc::ssh::mode::hardwareerrors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'hmc-command:s'           => { name => 'hmc_command', default => 'lssvcevents' },
        'retention:s'             => { name => 'retention' },
        'minutes'                 => { name => 'minutes' },
        'filter-status:s'         => { name => 'filter_status', default => 'open' },
        'filter-problem-nums:s'   => { name => 'filter_problem_nums' },
        'filter-system:s'         => { name => 'filter_system' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} !~ /^\d+$/) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify an integer as retention.');
        $self->{output}->option_exit();
    }
}

sub build_command {
    my ($self, %options) = @_;

    $self->{hmc_command} = $self->{option_results}->{hmc_command} . ' -t hardware -F first_time~sys_name~text '; 
    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} ne '') {
        if (defined($self->{option_results}->{minutes})) {
            $self->{hmc_command} .= ' -i ' . $self->{option_results}->{retention};
        } else {
            $self->{hmc_command} .= ' -d ' . $self->{option_results}->{retention};
        }
    }

    if ($self->{option_results}->{filter_status} ne '' && (!defined($self->{option_results}->{filter_problem_nums}) || ($self->{option_results}->{filter_problem_nums} eq ''))) {
        $self->{hmc_command} .= ' --filter "status=' . $self->{option_results}->{filter_status} . '" ';
    } elsif ($self->{option_results}->{filter_status} ne '' && defined($self->{option_results}->{filter_problem_nums}) && $self->{option_results}->{filter_problem_nums} ne '') {
        $self->{hmc_command} .= ' --filter "status=' . $self->{option_results}->{filter_status} . ',problem_nums=' . $self->{option_results}->{filter_problem_nums} . '"';
    } elsif (defined($self->{option_results}->{filter_problem_nums}) && $self->{option_results}->{filter_problem_nums} ne '') {
        $self->{hmc_command} .= ' --filter "status=' . $self->{option_results}->{filter_problem_nums} . '"';
    }

    if (defined($self->{option_results}->{filter_system}) && $self->{option_results}->{filter_system} ne '') {
        $self->{hmc_command} .= ' -m ' . $self->{option_results}->{filter_system} . ' ';
    }
}

sub run {
    my ($self, %options) = @_;

    $self->build_command();
    my ($stdout) = $options{custom}->execute_command(
        command => $self->{hmc_command}
    );

    ######
    # Command treatment
    ######
    my @long_msg = split("\n", $stdout);
    if (defined($self->{option_results}->{retention}) and defined($self->{option_results}->{minutes})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => "No problems on system since " . $self->{option_results}->{retention} . " minutes."
        );
    } elsif (defined($self->{option_results}->{retention})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => "No Problems on system since " . $self->{option_results}->{retention} . " days."
        );
    } else { 
        $self->{output}->output_add(
            severity => 'OK', 
            short_msg => "No problems on system."
        );
    }

    foreach my $line (@long_msg){
        if ($line =~ /^(.*)~(.*)~(.*)$/) {
            $self->{output}->output_add(
                severity => 'CRITICAL', 
                short_msg => "[$1][$2] $3"
            );
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Hardware for system managed by HMC.

=over 8

=item B<--command-hmc>

Hmc command to list events (default: lssvcevents).

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--retention>

Retention of errors. If option --minutes is not specified, retention is in days.

=item B<--minutes>

Retention in minutes. Use with option --retention.

=item B<--filter-status>

Filter by status ("open" or "closed") (Default : open).

=item B<--filter-problem-nums>

Filter by problem number (several number can be specified, separated by coma).

=item B<--filter-system>

Filter by system. The name may either be the user-defined name for the managed system, or be in the form tttt-mmm*ssssssss, where tttt is the machine type, mmm is the model, and ssssssss is the serial number of the managed system

=back

=cut
