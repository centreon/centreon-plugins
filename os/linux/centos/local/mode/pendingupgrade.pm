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

package os::linux::centos::local::mode::pendingupgrade;

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
                                  "command:s"         => { name => 'command', default => 'yum' },
                                  "command-path:s"    => { name => 'command_path', },
                                  "command-options:s" => { name => 'command_options', default => 'check-update 2>&1' },
                                  "warning:s"         => { name => 'warning', default => 40 },
                                  "critical:s"        => { name => 'critical', default => 50 },
                                  "filter-name:s"     => { name => 'filter_name',  },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->{warn} = $self->{option_results}->{warning};
    if (($self->{perfdata}->threshold_validate(label => 'warn', value => $self->{warn})) == 0 || ( $self->{warn}<= 0)) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warn} . "'.");
       $self->{output}->option_exit();
    }
    $self->{crit} = $self->{option_results}->{critical};
    if (($self->{perfdata}->threshold_validate(label => 'crit', value => $self->{crit})) == 0 ||  $self->{crit}<=0 ) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{crit} . "'.");
       $self->{output}->option_exit();
    }elsif ($self->{crit}<=$self->{warn}) {
       $self->{output}->add_option_msg(short_msg => "Critical threshold should be greater then Warning threshold '" . $self->{crit} . " <= ".$self->{warn}."'.");
       $self->{output}->option_exit();
    }



}

sub manage_selection {
    my ($self, %options) = @_;
    my $no_errors;
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options},
                                                  no_errors => { 100 => 1 });
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        next if ($line !~ /^(\w\S+)\s*(\d\S+)\s*(\S+)/);
        my ($package, $version, $upgradePath) = ($1, $2, $3);
        $self->{result}->{$package} = $version.' '.$upgradePath;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();
    my $amount=0;
    foreach my $package (sort(keys %{$self->{result}})) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $self->{result}{$package} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping Package '" . $package . "': no security upgrade");
            next;
        }
        $self->{output}->output_add(long_msg => "'package: " .$package. "\t". $self->{result}{$package} . "'");
        $amount = $amount+1;
    }
    $self->{output}->perfdata_add(label => 'pendingUpgrades',
                                value => $amount,
                                critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit'),
                                min => 0);

    my $exit = $self->{perfdata}->threshold_check(value => $amount,
                                                  threshold => [ { label => 'crit', 'exit_litteral' => 'critical' } ]);
        if (($amount >= 0 && $amount < $self->{warn})){
            $self->{output}->output_add(severity => 'OK',
                                short_msg => 'There are '.$amount.' pending upgrades');
        }elsif ($amount >= $self->{warn} && $amount < $self->{crit}){
            $self->{output}->output_add(severity => 'WARNING',
                                short_msg => 'WARNING: There are '.$amount.' pending upgrades');
        }elsif ($amount >= $self->{crit}){
            $self->{output}->output_add(severity => 'CRITICAL',
                                short_msg => 'CRITICAL: There are '.$amount.' pending upgrades');
        }else{
            $self->{output}->output_add(severity => 'UNKNOWN');
        }
    $self->{output}->display(nolabel => 1);
    $self->{output}->exit();
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

=item B<--warning>

Threshold warning Amount of Pending Upgrades (default: 40)

=item B<--critical>

Threshold critical Amount of Pending Upgrades (default: 50)

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

Command to get information (Default: 'yum').

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: 'check-updates 2>&1').

=item B<--filter-name>

Filter update path.

=back

=cut