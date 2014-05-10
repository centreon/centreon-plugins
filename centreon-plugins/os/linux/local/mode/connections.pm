################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package os::linux::local::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %map_states = (
    CLOSED => 'closed',
    LISTEN => 'listen',
    SYN_SENT => 'synSent',
    SYN_RECV => 'synReceived',
    ESTABLISHED => 'established',
    FIN_WAIT1 => 'finWait1',
    FIN_WAIT2 => 'finWait2',
    CLOSE_WAIT => 'closeWait',
    LAST_ACK => 'lastAck',
    CLOSING => 'closing',
    TIME_WAIT => 'timeWait',
    UNKNOWN => 'unknown',
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
                                  "command:s"         => { name => 'command', default => 'netstat' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-antu 2>&1' },
                                  "warning:s"       => { name => 'warning', },
                                  "critical:s"      => { name => 'critical', },
                                  "service:s@"      => { name => 'service', },
                                  "application:s@"  => { name => 'application', },
                                });
    @{$self->{connections}} = ();
    $self->{services} = { total => { filter => '.*?#.*?#.*?#.*?#.*?#(?!(listen))', builtin => 1, number => 0, msg => 'Total connections: %d' } };
    $self->{applications} = {};
    $self->{states} = { closed => 0, listen => 0, synSent => 0, synReceived => 0,
                        established => 0, finWait1 => 0, finWait2 => 0, closeWait => 0,
                        lastAck => 0, closing => 0, timeWait => 0 };
    return $self;
}

sub build_connections {
    my ($self, %options) = @_;
    
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    foreach my $line (split /\n/, $stdout) {
        next if ($line !~ /^(tcp|udp)\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s*(\S*)/);
        my ($type, $src, $dst, $state) = ($1, $2, $3, $4);
        $src =~ /(.*):(\d+|\*)$/;
        my ($src_addr, $src_port) = ($1, $2);
        $dst =~ /(.*):(\d+|\*)$/;
        my ($dst_addr, $dst_port) = ($1, $2);
        $type .= '6' if ($src_addr !~ /^\d+\.\d+\.\d+\.\d+$/);
        
        if ($type =~ /^udp/) {
            if ($dst_port eq '*') {
                $state = 'listen';
            } else {
                $state = 'established';
            }
        } else {
            $state = $map_states{$state};
            $self->{states}->{$state}++;
        }
        
        push @{$self->{connections}}, $type . "#$src_addr#$src_port#$dst_addr#$dst_port#" . lc($state);
    }
}

sub check_services {
    my ($self, %options) = @_;
    
    foreach my $service (@{$self->{option_results}->{service}}) {
        my ($tag, $ipv, $state, $port_src, $port_dst, $filter_ip_src, $filter_ip_dst, $warn, $crit) = split /,/, $service;
        
        if (!defined($tag) || $tag eq '') {
            $self->{output}->add_option_msg(short_msg => "Tag for service '" . $service . "' must be defined.");
            $self->{output}->option_exit();
        }
        if (defined($self->{services}->{$tag})) {
            $self->{output}->add_option_msg(short_msg => "Tag '" . $tag . "' (service) already exists.");
            $self->{output}->option_exit();
        }
        
        $self->{services}->{$tag} = { filter => ((defined($ipv) && $ipv ne '') ? $ipv : '.*?') . '#' . 
                                                ((defined($filter_ip_src) && $filter_ip_src ne '') ? $filter_ip_src : '.*?') . '#' . 
                                                ((defined($port_src) && $port_src ne '') ? $port_src : '.*?') . '#' . 
                                                ((defined($filter_ip_dst) && $filter_ip_dst ne '') ? $filter_ip_dst : '.*?') . '#' . 
                                                ((defined($port_dst) && $port_dst ne '') ? $port_dst : '.*?') . '#' . 
                                                ((defined($state) && $state ne '') ? lc($state) : '(?!(listen))')
                                                , 
                                      builtin => 0, number => 0 };
        if (($self->{perfdata}->threshold_validate(label => 'warning-service-' . $tag, value => $warn)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $warn . "' for service '$tag'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-service-' . $tag, value => $crit)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $crit . "' for service '$tag'.");
            $self->{output}->option_exit();
        }
    }
}

sub check_applications {
    my ($self, %options) = @_;
    
    foreach my $app (@{$self->{option_results}->{application}}) {
        my ($tag, $services, $warn, $crit) = split /,/, $app;
        
        if (!defined($tag) || $tag eq '') {
            $self->{output}->add_option_msg(short_msg => "Tag for application '" . $app . "' must be defined.");
            $self->{output}->option_exit();
        }
        if (defined($self->{applications}->{$tag})) {
            $self->{output}->add_option_msg(short_msg => "Tag '" . $tag . "' (application) already exists.");
            $self->{output}->option_exit();
        }
        
        $self->{applications}->{$tag} = {
                                            services => {},
                                        };
        foreach my $service (split /\|/, $services) {
            if (!defined($self->{services}->{$service})) {
                $self->{output}->add_option_msg(short_msg => "Service '" . $service . "' is not defined.");
                $self->{output}->option_exit();
            }
            $self->{applications}->{$tag}->{services}->{$service} = 1;
        }
        
        if (($self->{perfdata}->threshold_validate(label => 'warning-app-' . $tag, value => $warn)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $warn . "' for application '$tag'.");
            $self->{output}->option_exit();
        }
        if (($self->{perfdata}->threshold_validate(label => 'critical-app-' . $tag, value => $crit)) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $crit . "' for application '$tag'.");
            $self->{output}->option_exit();
        }
    }
}

sub test_services {
    my ($self, %options) = @_;
    
    foreach my $tag (keys %{$self->{services}}) {
        foreach (@{$self->{connections}}) {
            if (/$self->{services}->{$tag}->{filter}/) {
                $self->{services}->{$tag}->{number}++;
            }
        }        
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $self->{services}->{$tag}->{number}, 
                               threshold => [ { label => 'critical-service-' . $tag, 'exit_litteral' => 'critical' }, { label => 'warning-service-' . $tag, exit_litteral => 'warning' } ]);
        my ($perf_label, $msg) = ('service_' . $tag, "Service '$tag' connections: %d");
        if ($self->{services}->{$tag}->{builtin} == 1) {
            ($perf_label, $msg) = ($tag, $self->{services}->{$tag}->{msg});
        }
        
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf($msg, $self->{services}->{$tag}->{number}));
        $self->{output}->perfdata_add(label => $perf_label,
                                      value => $self->{services}->{$tag}->{number},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-service-' . $tag),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-service-' . $tag),
                                      min => 0);
    }
}

sub test_applications {
    my ($self, %options) = @_;

    foreach my $tag (keys %{$self->{applications}}) {
        my $number = 0;
        
        foreach (keys %{$self->{applications}->{$tag}->{services}}) {
            $number += $self->{services}->{$_}->{number};
        }
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $number, 
                               threshold => [ { label => 'critical-app-' . $tag, 'exit_litteral' => 'critical' }, { label => 'warning-app-' . $tag, exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit_code,
                                    short_msg => sprintf("Applicatin '%s' connections: %d", $tag, $number));
        $self->{output}->perfdata_add(label => 'app_' . $tag,
                                      value => $number,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-app-' . $tag),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-app-' . $tag),
                                      min => 0);
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-service-total', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-service-total', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    $self->check_services();
    $self->check_applications();
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->build_connections();
    $self->test_services();
    $self->test_applications();
    
    foreach (keys %{$self->{states}}) {
        $self->{output}->perfdata_add(label => 'con_' . $_,
                                      value => $self->{states}->{$_},
                                      min => 0);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check tcp/udp connections (udp connections are not in total. Use option '--service' to check it).
'ipx', 'x25' connections are not checked (need output to do it. If you have, you can post it in forge :)

=over 8

=item B<--warning>

Threshold warning for total connections.

=item B<--critical>

Threshold critical for total connections.

=item B<--service>

Check tcp connections following rules:
tag,[type],[state],[port-src],[port-dst],[filter-ip-src],[filter-ip-dst],[threshold-warning],[threshold-critical]

Example to test SSH connections on the server: --service="ssh,,,22,,,,10,20" 

=over 16

=item <tag>

Name to identify service (must be unique and couldn't be 'total').

=item <type>

regexp - can use 'ipv4', 'ipv6', 'udp', 'udp6'. Empty means all.

=item <state>

regexp - can use 'finWait1', 'established',... Empty means all (minus listen).
For udp connections, there are 'established' and 'listen'.

=item <filter-ip-*>

regexp - can use to exclude or include some IPs.

=item <threshold-*>

nagios-perfdata - number of connections.

=back

=item B<--application>

Check tcp connections of mutiple services:
tag,[services],[threshold-warning],[threshold-critical]

Example:
--application="web,http|https,100,200"

=over 16

=item <tag>

Name to identify application (must be unique).

=item <services>

List of services (used the tag name. Separated by '|').

=item <threshold-*>

nagios-perfdata - number of connections.

=back

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

Command to get information (Default: 'netstat').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-antu 2>&1').

=back

=cut
