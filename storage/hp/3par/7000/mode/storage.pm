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

package storage::hp::3par::7000::mode::storage;

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
                                  "hostname:s"              => { name => 'hostname' },
                                  "timeout:s"               => { name => 'timeout', default => 30 },
                                  "sudo"                    => { name => 'sudo' },
                                  "ssh-option:s@"           => { name => 'ssh_option' },
                                  "ssh-path:s"              => { name => 'ssh_path' },
                                  "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "filter-type:s"           => { name => 'filter_type' },
                                  "disk:s"                  => { name => 'disk' },
                                  "regexp"                  => { name => 'regexp' },
                                });
    $self->{components} = {};
    $self->{no_components} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify a hostname.");
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
}

sub run {
    my ($self, %options) = @_;

    $self->{option_results}->{remote} = 1;
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => "showpd",
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});


    my $total_disks = 0;
    my @disks = split("\n",$stdout);
    foreach my $disk (@disks) {
        if ($disk =~ /(\d+)\s+\S+\s+(\S+)\s+\d+\s+\S+\s+(\d+)\s+(\d+)\s+\S+\s+\S+\s+\d+/) {
            $total_disks++;
            my $diskId = $1;
            my $diskType = $2;
            my $diskSize = $3 * 1024 * 1024;
            my $diskFree = $4 * 1024 * 1024;
            my $diskUsed = $diskSize - $diskFree;
            my $percentUsed = ($diskUsed / $diskSize) * 100;
            my $percentFree = ($diskFree / $diskSize) * 100;

            next if (defined($self->{option_results}->{filter_type}) && ($diskType !~ /$self->{option_results}->{filter_type}/i));
            next if (defined($self->{option_results}->{disk}) && defined($self->{option_results}->{regexp}) && ($diskId !~ /$self->{option_results}->{disk}/i));
            next if (defined($self->{option_results}->{disk}) && !defined($self->{option_results}->{regexp}) && ($diskId != $self->{option_results}->{disk}));

            my ($diskSizeValue, $diskSizeUnit) = $self->{perfdata}->change_bytes(value => $diskSize);
            my ($diskUsedValue, $diskUsedUnit) = $self->{perfdata}->change_bytes(value => $diskUsed);
            my ($diskFreeValue, $diskFreeUnit) = $self->{perfdata}->change_bytes(value => $diskFree);

            $self->{output}->output_add(long_msg => sprintf("Disk '%d' Total: %.2f%s Used: %.2f%s (%.2f%%) Free: %.2f%s (%.2f%%)",
                                        $diskId, $diskSizeValue, $diskSizeUnit, $diskUsedValue, $diskUsedUnit, $percentUsed, $diskFreeValue, $diskFreeUnit, $percentFree));
            my $exit = $self->{perfdata}->threshold_check(value => $percentUsed, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Disk '%d' Total: %.2f%s Used: %.2f%s (%.2f%%) Free: %.2f%s (%.2f%%)",
                                            $diskId, $diskSizeValue, $diskSizeUnit, $diskUsedValue, $diskUsedUnit, $percentUsed, $diskFreeValue, $diskFreeUnit, $percentFree));
            }
            $self->{output}->perfdata_add(label => 'disk_'.$diskId,
                                          unit => 'B',
                                          value => $diskUsed,
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $diskSize, cast_int => 1),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $diskSize, cast_int => 1),
                                          min => 0,
                                          max => $diskSize);
        }
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All disks are ok.');
     
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Physical disks.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh').

=item B<--sudo>

Use sudo.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut