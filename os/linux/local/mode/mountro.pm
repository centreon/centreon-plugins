#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package os::linux::local::mode::mountro;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'mount' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => ' 2>&1' },
                                  "critical:s"        => { name => 'critical', default => 1 },
                                  "filter-name:s"     => { name => 'filter_name', },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->{crit} = $self->{option_results}->{critical};
    if (($self->{perfdata}->threshold_validate(label => 'crit', value => $self->{crit})) == 0 ||  $self->{crit}<=0 ){
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{crit} . "'.");
       $self->{output}->option_exit();
    }

}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    my $counter = 0;
    my @lines = split /\n/, $stdout;
    # Header not needed
    shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)(.*)/);
        my ($device, $mountpoint, $filesystem, $options) = ($1, $3, $5, $6);
        next if ($options !~ /ro[\s,]/ && $options !~ /read-only/);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $filesystem !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping partition '" . $filesystem . "': no matching filter name");
            next;
        }
        $self->{result}->{"$counter.mountpoint"} = $mountpoint;
        $self->{result}->{"$counter.device"} = $device;
        $self->{result}->{"$counter.options"} = $options;
        $self->{result}->{"$counter.filesystem"} = $filesystem;
        $self->{result}->{"$counter.description"} = "Mountpoint $mountpoint from $device with Filesystem $filesystem is mounted readonly ($options)";
        $counter = $counter + 1;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();
    my $countFs=0;
    foreach my $identifier (sort(keys %{$self->{result}})) {
        #print $identifier . "=" . $self->{result}->{$identifier}. "\n";
        next if ($identifier !~ /description/);
        $self->{output}->output_add(long_msg => "'" . $self->{result}->{$identifier} . "'");
        $countFs = $countFs + 1;
    }
        $self->{output}->perfdata_add(label => 'count_roFs',
                                  value => $countFs,
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit'),
                                  min => 1);

    my $exit = $self->{perfdata}->threshold_check(value => $countFs,
                                                  threshold => [ { label => 'crit', 'exit_litteral' => 'critical' } ]);
        if (($countFs < $self->{crit})){
            $self->{output}->output_add(severity => 'OK',
                                short_msg => 'No Read-Only Filesystems');
        }else{
            $self->{output}->output_add(severity => 'CRITICAL',
                                short_msg => 'There is at least 1 Filesystem mounted as RO');
        }


    $self->{output}->display(nolabel => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['roFS']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection();
    foreach my $name (sort(keys %{$self->{result}})) {
        next if ($name !~ /description/);
        $self->{output}->add_disco_entry(roFS => $self->{result}->{$name},
                                         );
    }
}

1;

__END__

=head1 MODE

List partitions.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--critical>
Threshold critical Amount of read-only Filesystems (default: 0)

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

Command to get information (Default: 'mount').

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: ' 2>&1').

=item B<--filter-name>

Filter filesystem name (regexp can be used) eg: (!fs).

=back

=cut