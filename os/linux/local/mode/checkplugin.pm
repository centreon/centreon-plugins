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

package os::linux::local::mode::checkplugin;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::ssh;
use centreon::plugins::misc;

sub custom_status_output {
    my ($self, %options) = @_;

    return $self->{result_values}->{short_message};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'commands', type => 1, message_separator => ' - ', display_long => 0 }
    ];

    $self->{maps_counters}->{commands} = [
         {
             label => 'status', type => 2, 
             unknown_default => '%{exit_code} == 3',
             warning_default => '%{exit_code} == 1',
             critical_default => '%{exit_code} == 2',
             set => {
                key_values => [
                    { name => 'short_message' }, { name => 'exit_code' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'time', nlabel => 'ssh.response.time.seconds', display_ok => 0, set => {
                key_values => [ { name => 'time' } ],
                output_template => 'response time: %.3fs',
                perfdatas => [
                    { template => '%.3f', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s' => { name => 'hostname' },
        'timeout:s'  => { name => 'timeout' },
        'command:s@' => { name => 'command' }
    });

    $self->{ssh} = centreon::plugins::ssh->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Set --hostname option');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{command})) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify at least one --command option');
        $self->{output}->option_exit();
    }

    $self->{ssh}->check_options(option_results => $self->{option_results});
}

sub parse_perfdatas {
    my ($self, %options) = @_;

    while ($options{perfdatas} =~ /(.*?)=([0-9\.]+)([^0-9;]+?)?([0-9.@;]+?)?(?:\s+|\Z)/g) {
        my ($label, $value, $unit, $extra) = ($1, $2, $3, $4);
        $label = centreon::plugins::misc::trim($label);
        $label =~ s/^'//;
        $label =~ s/'$//;
        my @extras = split(';', $extra);
        $self->{output}->perfdata_add(
            nlabel => $label,
            unit => $unit,
            value => $value,
            warning => $extras[1],
            critical => $extras[2],
            min => $extras[3],
            max => $extras[4]
        );
    }
}

sub parse_plugin_output {
    my ($self, %options) = @_;

    my @lines = split(/\n/, $options{output});
    my $short = 'no output';
    my $line = shift(@lines);
    if (defined($line) && $line =~ /^(.*?)(?:\|(.*)|\Z)/) {
        $short = $1;
        if (defined($2)) {
            $self->parse_perfdatas(perfdatas => $2);
        }
    }

    $self->{commands}->{ $options{cmd} }->{short_message} = $short;
    foreach (@lines) {
        $self->{output}->output_add(long_msg => $_);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{output}->set_ignore_label();

    my $timeout = $self->{option_results}->{timeout};
    $timeout = 45 if (!defined($timeout) || $timeout !~ /\d+/);

    $self->{commands} = {};
    my $i = 1;
    foreach my $command (@{$self->{option_results}->{command}}) {
        my $timing0 = [gettimeofday];
        my ($stdout, $exit_code) = $self->{ssh}->execute(
            hostname => $self->{option_results}->{hostname},
            command => $command,
            timeout => $timeout,
            no_quit => 1
        );
        my $cmd = 'command' . $i;
        $self->{commands}->{$cmd} = {
            time => tv_interval($timing0, [gettimeofday]),
            exit_code => $exit_code
        };
        $self->parse_plugin_output(cmd => $cmd, output => $stdout);
        $i++;
    }
}

1;

__END__

=head1 MODE

SSH execution commands in a remote host.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--timeout>

Timeout in seconds for the command (Default: 45).

=item B<--command>

command to execute on the remote machine

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{exit_code} == 3').
Can used special variables like: %{short_message}, %{exit_code}

=item B<--warning-status>

Set warning threshold for status (Default: '%{exit_code} == 1').
Can used special variables like: %{short_message}, %{exit_code}

=item B<--critical-status>

Set critical threshold for status (Default: '%{exit_code} == 2').
Can used special variables like: %{short_message}, %{exit_code}

=item B<--warning-time>

Threshold warning in seconds.

=item B<--critical-time>

Threshold critical in seconds.

=back

=cut
