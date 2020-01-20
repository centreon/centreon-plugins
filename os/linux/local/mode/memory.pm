#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package os::linux::local::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub rhelUp70{
	my @result;
	my $pathFile="/etc/redhat-release";
	my $line;
	unless(open FILE,$pathFile){
		print "Cannot open file - <$pathFile>\n";
		return 0;
	}
	while ($line=<FILE>){
		chomp $line;
		push (@result,$line);
	}
    unless(close FILE){
		print "Can't close file - <$pathFile>\n";
		return 0;
	}
	my ($version_maj,$version_min);
	($version_maj,$version_min) = $result[0] =~ m/(?>\w*\s*)+(\d+)\.(\d+).*/i;
	if ($version_maj > 7){
		return 1;
	}
	if ($version_maj < 7){
		return 0;
	}
	else{
		if ($version_min > 0){
			return 1;
		}
		else{
			return 0;
		}
	}
	return 1;
}

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
                                  "command:s"         => { name => 'command', default => 'cat' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '/proc/meminfo 2>&1' },
                                  "warning:s"         => { name => 'warning', },
                                  "critical:s"        => { name => 'critical', },
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
}

sub run {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});

    # Buffer can be missing. In Openvz container for example.
    my $buffer_used = 0;
    my ($cached_used, $free, $total_size, $slab_used);
    foreach (split(/\n/, $stdout)) {
        if (/^MemTotal:\s+(\d+)/i) {
            $total_size = $1 * 1024;
        } elsif (/^Cached:\s+(\d+)/i) {
            $cached_used = $1 * 1024;
        } elsif (/^Buffers:\s+(\d+)/i) {
            $buffer_used = $1 * 1024;
        } elsif (/^Slab:\s+(\d+)/i) {
            $slab_used = $1 * 1024;
		} elsif (/^MemFree:\s+(\d+)/i) {
            $free = $1 * 1024;
        }
    }

    if (!defined($total_size) || !defined($cached_used) || !defined($free) || !defined($slab_used)) {
        $self->{output}->add_option_msg(short_msg => "Some informations missing.");
        $self->{output}->option_exit();
    }
	
	my $physical_used = $total_size - $free;
	my $nobuf_used;
	if (rhelUp70) {
		$nobuf_used = $physical_used - $buffer_used - $cached_used - $slab_used; 
	} else {
		$nobuf_used = $physical_used - $buffer_used - $cached_used;
	}
    my $prct_used = $nobuf_used * 100 / $total_size;
    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my ($nobuf_value, $nobuf_unit) = $self->{perfdata}->change_bytes(value => $nobuf_used);
    my ($buffer_value, $buffer_unit) = $self->{perfdata}->change_bytes(value => $buffer_used);
    my ($cached_value, $cached_unit) = $self->{perfdata}->change_bytes(value => $cached_used);
	if (rhelUp70) {
    my ($slab_value, $slab_unit) = $self->{perfdata}->change_bytes(value => $slab_used);
	
	$self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Ram used (-buffers/cache/slab) %s (%.2f%%), Buffer: %s, Cached: %s, Slab: %s",
                                            $nobuf_value . " " . $nobuf_unit, $prct_used,
                                            $buffer_value . " " . $buffer_unit,
                                            $cached_value . " " . $cached_unit,
											$slab_value . " " . $slab_unit));

    $self->{output}->perfdata_add(label => "cached", unit => 'B',
                                  value => $cached_used,
                                  min => 0);
    $self->{output}->perfdata_add(label => "buffer", unit => 'B',
                                  value => $buffer_used,
                                  min => 0);
    $self->{output}->perfdata_add(label => "slab", unit => 'B',
                                  value => $slab_used,
                                  min => 0);
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $nobuf_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size),
                                  min => 0, max => $total_size);

    $self->{output}->display();
    $self->{output}->exit();
	} else {
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Ram used (-buffers/cache) %s (%.2f%%), Buffer: %s, Cached: %s",
                                            $nobuf_value . " " . $nobuf_unit, $prct_used,
                                            $buffer_value . " " . $buffer_unit,
                                            $cached_value . " " . $cached_unit));

    $self->{output}->perfdata_add(label => "cached", unit => 'B',
                                  value => $cached_used,
                                  min => 0);
    $self->{output}->perfdata_add(label => "buffer", unit => 'B',
                                  value => $buffer_used,
                                  min => 0);
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $nobuf_used,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size),
                                  min => 0, max => $total_size);

    $self->{output}->display();
    $self->{output}->exit();
	}
}

1;

__END__

=head1 MODE

Check physical memory (need '/proc/meminfo' file).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

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

Command to get information (Default: 'cat').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '/proc/meminfo 2>&1').

=back

=cut
