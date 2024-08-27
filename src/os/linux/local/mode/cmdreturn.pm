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

package os::linux::local::mode::cmdreturn;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'exec-command:s'         => { name => 'exec_command' },
        'exec-command-path:s'    => { name => 'exec_command_path' },
        'exec-command-options:s' => { name => 'exec_command_options' },
        'manage-returns:s'       => { name => 'manage_returns', default => '' },
        'separator:s'            => { name => 'separator', default => '#' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{exec_command})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify exec-command option.");
        $self->{output}->option_exit();
    }

    $self->{expressions} = [];
    foreach my $entry (split(/$self->{option_results}->{separator}/, $self->{option_results}->{manage_returns})) {
        next if (!($entry =~ /(.*?),(.*?),(.*)/));
        next if (!$self->{output}->is_litteral_status(status => $2));
        my ($expr, $rv, $msg) = ($1, $2, $3);

        if ($expr ne '') {
            if ($expr =~ /^\s*([0-9]+)\s*$/) {
                push @{$self->{expressions}}, { test => "%(code) == $1", rv => $rv, msg => $msg };
            } else {
                push @{$self->{expressions}}, { test => $expr, rv => $rv, msg => $msg };
            }
        } else {
            $self->{expression_default} = { rv => $rv, msg => $msg };
        }
    }

    if ($self->{option_results}->{manage_returns} eq '' ||
        (scalar(@{$self->{expressions}}) == 0 && !defined($self->{expression_default}))) {
        $self->{output}->add_option_msg(short_msg => "Need to specify manage-returns option correctly.");
        $self->{output}->option_exit();
    }

    for (my $i = 0; $i < scalar(@{$self->{expressions}}); $i++) {
        $self->{expressions}->[$i]->{test} =~ s/%\{(.*?)\}/\$values->{$1}/g;
        $self->{expressions}->[$i]->{test} =~ s/%\((.*?)\)/\$values->{$1}/g;
    }

    centreon::plugins::misc::check_security_whitelist(
        output => $self->{output},
        command => $self->{option_results}->{exec_command},
        command_path => $self->{option_results}->{exec_command_path},
        command_options => $self->{option_results}->{exec_command_options}
    );
}

sub run {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = $options{custom}->execute_command(
        command => $self->{option_results}->{exec_command},
        command_path => $self->{option_results}->{exec_command_path},
        command_options => $self->{option_results}->{exec_command_options},
        no_quit => 1
    );

    my $long_msg = $stdout;
    $long_msg =~ s/\|/~/mg;
    $self->{output}->output_add(long_msg => $long_msg);

    my $matched = 0;
    my $values = { code => $exit_code, output => $stdout };
    foreach (@{$self->{expressions}}) {
        if ($self->{output}->test_eval(test => $_->{test}, values => $values)) {
            $self->{output}->output_add(
                severity => $_->{rv}, 
                short_msg => $_->{msg}
            );
            $matched = 1;
            last;
        }
    }

    if ($matched == 0 && defined($self->{expression_default})) {
        $self->{output}->output_add(
            severity => $self->{expression_default}->{rv}, 
            short_msg => $self->{expression_default}->{msg}
        );
    } elsif ($matched == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN', 
            short_msg => "Command exit code ($exit_code)"
        );
    }

    if (defined($exit_code)) {
        $self->{output}->perfdata_add(
            nlabel => 'command.exit.code.count',
            value => $exit_code
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check command returns.

=over 8

=item B<--manage-returns>

Set action according command exit code.
Example: %(code) == 0,OK,File xxx exist#%(code) == 1,CRITICAL,File xxx not exist#,UNKNOWN,Command problem

=item B<--separator>

Set the separator used in --manage-returns (default : #)

=item B<--exec-command>

Command to test (default: none).
You can use 'sh' to use '&&' or '||'.

=item B<--exec-command-path>

Command path (default: none).

=item B<--exec-command-options>

Command options (default: none).

=back

=cut
