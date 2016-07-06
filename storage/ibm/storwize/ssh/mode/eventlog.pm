#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package storage::ibm::storwize::ssh::mode::eventlog;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"           => { name => 'warning', },
                                  "critical:s"          => { name => 'critical', },
                                  "filter-event-id:s"   => { name => 'filter_event_id'  },
                                  "filter-message:s"    => { name => 'filter_message' },
                                  "retention:s"         => { name => 'retention' },
                                  "hostname:s"          => { name => 'hostname' },
                                  "ssh-option:s@"       => { name => 'ssh_option' },
                                  "ssh-path:s"          => { name => 'ssh_path' },
                                  "ssh-command:s"       => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "sudo"                => { name => 'sudo' },
                                  "command:s"           => { name => 'command' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options' },
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
    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
    
    my $last_timestamp = '';
    if (defined($self->{option_results}->{retention}) && $self->{option_results}->{retention} =~ /^\d+$/) {
        # by default UTC timezone used
        my $dt = DateTime->from_epoch(epoch => time() - $self->{option_results}->{retention});
        my $dt_format = sprintf("%d%02d%02d%02d%02d%02d", substr($dt->year(), 2), $dt->month(), $dt->day(), $dt->hour(), $dt->minute(), $dt->second());
        $last_timestamp = 'last_timestamp>=' . $dt_format . ":";
    }
    $self->{ls_command} = "lseventlog -message no -alert yes -filtervalue '${last_timestamp}fixed=no' -delim :";
}

sub get_hasharray {
    my ($self, %options) = @_;

    my $result = [];
    return $result if ($options{content} eq '');
    my ($header, @lines) = split /\n/, $options{content};
    my @header_names = split /$options{delim}/, $header;
    
    for (my $i = 0; $i <= $#lines; $i++) {
        my @content = split /$options{delim}/, $lines[$i];
        my $data = {};
        for (my $j = 0; $j <= $#header_names; $j++) {
            $data->{$header_names[$j]} = $content[$j];
        }
        push @$result, $data;
    }
    
    return $result;
}

sub run {
    my ($self, %options) = @_;

    my $content = centreon::plugins::misc::execute(output => $self->{output},
                                                   options => $self->{option_results},
                                                   sudo => $self->{option_results}->{sudo},
                                                   command => defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : $self->{ls_command} . " ; exit ;",
                                                   command_path => $self->{option_results}->{command_path},
                                                   command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef);
    my $result = $self->get_hasharray(content => $content, delim => ':');
    
    my ($num_eventlog_checked, $num_errors) = (0, 0);
    foreach (@$result) {
        $num_eventlog_checked++;
        if (defined($self->{option_results}->{filter_message}) && $self->{option_results}->{filter_message} ne '' &&
            $_->{description} !~ /$self->{option_results}->{filter_message}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{description} . "': no matching filter description.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_event_id}) && $self->{option_results}->{filter_event_id} ne '' &&
            $_->{event_id} !~ /$self->{option_results}->{filter_event_id}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{event_id} . "': no matching filter event id.", debug => 1);
            next;
        }
        
        $self->{output}->output_add(long_msg => sprintf("%s : %s - %s", 
                                                         scalar(localtime($_->{last_timestamp})),
                                                         $_->{event_id}, $_->{description}
                                                         )
                                    );
        $num_errors++;
    }
    
    $self->{output}->output_add(long_msg => sprintf("Number of message checked: %s", $num_eventlog_checked));
    my $exit = $self->{perfdata}->threshold_check(value => $num_errors, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d problem detected (use verbose for more details)", $num_errors)
                                );
    $self->{output}->perfdata_add(label => 'problems',
                                  value => $num_errors,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check eventlogs.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--filter-event-id>

Filter on event id.

=item B<--filter-message>

Filter on event message.

=item B<--retention>

Get eventlog of X last seconds. For the last minutes: --retention=60

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=back

=cut
    