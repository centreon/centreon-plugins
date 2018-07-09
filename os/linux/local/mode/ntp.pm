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

package os::linux::local::mode::ntp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %state_map_ntpq = (
    '<sp>' => 'discarded due to high stratum and/or failed sanity checks',
    'x' => 'designated falsticker by the intersection algorithm',
    '.' => 'culled from the end of the candidate list',
    '-' => 'discarded by the clustering algorithm',
    '+' => 'included in the final selection set',
    '#' => 'selected for synchronization but distance exceeds maximum',
    '*' => 'selected for synchronization',
    'o' => 'selected for synchronization, PPS signal in use'
);

my %type_map_ntpq = (
    'l' => 'local',
    'u' => 'unicast',
    'm' => 'multicast',
    'b' => 'broadcast',
    '-' => 'netaddr'
);

my %state_map_chronyc = (
    'x' => 'time may be in error',
    '-' => 'not combined',
    '+' => 'combined',
    '?' => 'unreachable',
    '*' => 'current synced',
    '~' => 'time too variable'
);

my %type_map_chronyc = (
    '^' => 'server',
    '=' => 'peer',
    '#' => 'local clock'
);

my %unit_map_chronyc = (
    'ns' => 0.000001,
    'us' => 0.001,
    'ms' => 1,
    's'  => 1000
);

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
                                  "command:s"         => { name => 'command', default => 'ntpq' },
                                  "command-path:s"    => { name => 'command_path', },
                                  "command-options:s" => { name => 'command_options', default => '-p -n 2>&1' },
                                  "warning-peer:s"    => { name => 'warning_peer_count', default => 0 },
                                  "critical-peer:s"   => { name => 'critical_peer_count' },
                                  "warning-offset:s"  => { name => 'warning_peer_offset', default => 150 },
                                  "critical-offset:s" => { name => 'critical_peer_offset', default => 1000 },
                                  "filter-name:s"     => { name => 'filter_name',  },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (defined($self->{option_results}->{warning_peer_count})){
        $self->{warn_peer_count} = $self->{option_results}->{warning_peer_count};
        if (($self->{perfdata}->threshold_validate(label => 'warn_peer_count', value => $self->{warn_peer_count})) == 0 || ( $self->{warn_peer_count}< 0)) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{warn_peer_count} . "'.");
            $self->{output}->option_exit();
        }
    }
    if (defined($self->{option_results}->{critical_peer_count})){
        $self->{crit_peer_count} = $self->{option_results}->{critical_peer_count};
        if (($self->{perfdata}->threshold_validate(label => 'crit_peer_count', value => $self->{crit_peer_count})) == 0 ||  $self->{crit_peer_count}<0 ) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{crit_peer_count} . "'.");
            $self->{output}->option_exit();
        }
    }
    $self->{warn_offset} = $self->{option_results}->{warning_peer_offset};
    if (($self->{perfdata}->threshold_validate(label => 'warning_offset', value => $self->{warn_offset})) == 0 || ( $self->{warn_offset}< 0) || $self->{warn_offset} !~ /^\d+/){
        $self->{output}->add_option_msg(short_msg => "Wrong Offset: warning threshold '" . $self->{warn_offset} . "' should be a postive Number.");
        $self->{output}->option_exit();
    }
    $self->{crit_offset} = $self->{option_results}->{critical_peer_offset};
    if (($self->{perfdata}->threshold_validate(label => 'critical_offset', value => $self->{crit_offset})) == 0 || ( $self->{crit_offset}< 0) || $self->{crit_offset} !~ /^\d+/){
        $self->{output}->add_option_msg(short_msg => "Wrong Offset: critical threshold '" . $self->{crit_offset} . "' should be a postive Number.");
        $self->{output}->option_exit();
    }
    if ($self->{crit_offset}<$self->{warn_offset}) {
        $self->{output}->add_option_msg(short_msg => "Critical threshold should be greater then Warning threshold '" . $self->{crit_offset} . " <= ".$self->{warn_offset}."'.");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{command} eq 'ntpq'){
        $self->{regex} = '^(\+|\*|\.|\-|\#|x|\<sp\>|o)(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)';
    }elsif ($self->{option_results}->{command} eq 'chronyc'){
        $self->{regex} = '^(.)(\+|\*|\.|\-|\#|x|\<sp\>)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.\d+)(\w+).{2}(.\d+)(\w+).{7}(\d+)(\w+)';
    }else{
        $self->{output}->add_option_msg(short_msg => "Critical: command". $self->{option_results}->{command} ." not implemented '" );
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
                                                 );
    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        if ($line =~ /Connection refused/){
            $self->{output}->output_add(severity => 'CRITICAL',
                                short_msg => 'CRITICAL: check ntp.conf and ntp daemon');
            $self->{output}->display(nolabel => 1);
            $self->{output}->exit();
        }
        next if ($line !~ /$self->{regex}/);
        if ($self->{option_results}->{command} eq 'ntpq'){
            my ($peer_fate, $remote_peer, $refid, $stratum, $type, $last_time, $polling_intervall, $reach, $delay, $offset, $jitter ) = ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11);
            $self->{result}->{centreon::plugins::misc::trim($remote_peer)} = {peer    => centreon::plugins::misc::trim($remote_peer),
                                                                  state   => centreon::plugins::misc::trim($peer_fate),
                                                                  stratum => centreon::plugins::misc::trim($stratum),
                                                                  type    => centreon::plugins::misc::trim($type),
                                                                  reach   => centreon::plugins::misc::trim($reach),
                                                                  offset  => centreon::plugins::misc::trim($offset)};
        }elsif ($self->{option_results}->{command} eq 'chronyc'){
            my ($type, $peer_fate, $remote_peer, $stratum, $poll, $reach, $lastRX, $last_sample, $offset ) = ($1, $2, $3, $4, $5, $6, $7, $8.$9.'[ '.$10.$11.'] +/-  '.$12.$13 , $10);
            $self->{result}->{centreon::plugins::misc::trim($remote_peer)} = {peer    => centreon::plugins::misc::trim($remote_peer),
                                                                  state         => centreon::plugins::misc::trim($peer_fate),
                                                                  stratum       => centreon::plugins::misc::trim($stratum),
                                                                  type          => centreon::plugins::misc::trim($type),
                                                                  reach         => centreon::plugins::misc::trim($reach),
                                                                  offset        => centreon::plugins::misc::trim(abs($offset)),
                                                                  unit          => centreon::plugins::misc::trim($11),
                                                                  last_sample   => centreon::plugins::misc::trim($last_sample)};
        }
        
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection();
    my $peer_count=0;
    foreach my $peer (sort(keys %{$self->{result}})) {
        if ($self->{option_results}->{command} eq 'ntpq'){
            $self->{output}->output_add(long_msg => 'NTP Peer '.++(my $count = $peer_count).': [peer => ' . $self->{result}->{$peer}->{peer} .
                                                          '] [type => ' . $type_map_ntpq{$self->{result}->{$peer}->{type}} .
                                                          '] [stratum => ' . $self->{result}->{$peer}->{stratum} .
                                                          '] [reach => ' . $self->{result}->{$peer}->{reach} .
                                                          '] [offset => ' . $self->{result}->{$peer}->{offset} .
                                                          '] [state => ' . $state_map_ntpq{$self->{result}->{$peer}->{state}} .
                                                          '] [rawtype => ' . $self->{result}->{$peer}->{type} .
                                                          '] [rawstate => ' . $self->{result}->{$peer}->{state} . ']');
        }elsif ($self->{option_results}->{command} eq 'chronyc'){
            $self->{result}->{$peer}->{offset}=$self->{result}->{$peer}->{offset}*$unit_map_chronyc{$self->{result}->{$peer}->{unit}};
            $self->{output}->output_add(long_msg => 'NTP Peer '.++(my $count = $peer_count).': [peer => ' . $self->{result}->{$peer}->{peer} .
                                                          '] [type => ' . $type_map_chronyc{$self->{result}->{$peer}->{type}} .
                                                          '] [stratum => ' . $self->{result}->{$peer}->{stratum} .
                                                          '] [reach => ' . $self->{result}->{$peer}->{reach} .
                                                          '] [offset => ' . $self->{result}->{$peer}->{offset} .
                                                          '] [last_sample => ' . $self->{result}->{$peer}->{last_sample} .
                                                          '] [state => ' . $state_map_chronyc{$self->{result}->{$peer}->{state}} .
                                                          '] [rawtype => ' . $self->{result}->{$peer}->{type} .
                                                          '] [rawstate => ' . $self->{result}->{$peer}->{state} . ']');
        }
        $peer_count = $peer_count+1;
        $self->{output}->perfdata_add(label => 'stratum-'.$self->{result}->{$peer}->{peer},
                                  value => $self->{result}->{$peer}->{stratum},
                                  min => 0);
                                  
        $self->{output}->perfdata_add(label => 'offset-'.$self->{result}->{$peer}->{peer},
                                  value => $self->{result}->{$peer}->{offset},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_offset'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_offset'),
                                  min => 0);
                                  
        if($self->{result}->{$peer}->{state} eq '*'){
            if (abs($self->{result}->{$peer}->{offset}) >= $self->{warn_offset} && abs($self->{result}->{$peer}->{offset}) < $self->{crit_offset}){
                $self->{output}->output_add(severity => 'WARNING',
                            short_msg => 'WARNING: The NTP-Offset reach the threshold '. abs($self->{result}->{$peer}->{offset}) .' > '. $self->{warn_offset} .'.');
            }elsif(abs($self->{result}->{$peer}->{offset}) >= $self->{crit_offset}){
                $self->{output}->output_add(severity => 'CRITICAL',
                            short_msg => 'CRITICAL: The NTP-Offset reach the threshold '. abs($self->{result}->{$peer}->{offset}) .' > '. $self->{crit_offset} .'.');
            
            }
        }
    }
    $self->{output}->perfdata_add(label => 'NTP-Peers',
                                value => $peer_count,
                                warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn_peer_count'),
                                critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit_peer_count'),
                                min => 0);
    

    $self->{output}->output_add(severity => 'UNKNOWN');
    if ($peer_count > 0){
        $self->{output}->output_add(severity => 'OK',
                            short_msg => 'OK: There are '.$peer_count.' NTP Peers available');
    
    
    }
    if (defined( $self->{warn_peer_count} ) && $self->{warn_peer_count}  ne '' &&
            $peer_count <= $self->{warn_peer_count} && $peer_count>=0 ) {
            $self->{output}->output_add(severity => 'WARNING',
                            short_msg => 'WARNING: Not enough NTP-Server available '.$peer_count.' <= '. $self->{warn_peer_count});
        
    }
    if (defined( $self->{crit_peer_count} ) && $self->{crit_peer_count}  ne '' &&
            $peer_count <= $self->{crit_peer_count} && $peer_count>=0 ) {
            $self->{output}->output_add(severity => 'CRITICAL',
                            short_msg => 'CRITICAL: Not enough NTP-Server available '.$peer_count.' <= '. $self->{crit_peer_count});
        
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

=item B<--warning-peer>

Threshold warning minimum Amount of NTP-Server (default: 0)

=item B<--critical-peer>

Threshold critical minimum Amount of NTP-Server

=item B<--warning-offset>

Threshold warning Offset deviation value in miliseconds (default: 150)

=item B<--critical-offset>

Threshold critical Offset deviation value in miliseconds (default: 1000)

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

Command options (Default: '/proc/mounts 2>&1').

=back

=cut
