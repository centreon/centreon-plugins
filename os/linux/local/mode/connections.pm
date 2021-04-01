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

package os::linux::local::mode::connections;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_ss_states = (
    UNCONN => 'closed',
    LISTEN => 'listen',
    'SYN-SENT' => 'synSent',
    'SYN-RECV' => 'synReceived',
    ESTAB => 'established',
    'FIN-WAIT-1' => 'finWait1',
    'FIN-WAIT-2' => 'finWait2',
    'CLOSE-WAIT' => 'closeWait',
    'LAST-ACK' => 'lastAck',
    CLOSING => 'closing',
    'TIME-WAIT' => 'timeWait',
    UNKNOWN => 'unknown',
);

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
    
    $options{options}->add_options(arguments => { 
        'warning:s'      => { name => 'warning', },
        'critical:s'     => { name => 'critical', },
        'service:s@'     => { name => 'service', },
        'application:s@' => { name => 'application', },
        'con-mode:s'     => { name => 'con_mode', default => 'netstat' }
    });

    $self->{connections} = [];
    $self->{services} = { total => { filter => '(?!(udp*))#.*?#.*?#.*?#.*?#(?!(listen))', builtin => 1, number => 0, msg => 'Total connections: %d' } };
    $self->{applications} = {};
    $self->{states} = {
        closed => 0, listen => 0, synSent => 0, synReceived => 0,
        established => 0, finWait1 => 0, finWait2 => 0, closeWait => 0,
        lastAck => 0, closing => 0, timeWait => 0
    };

    return $self;
}

sub netstat_build {
    my ($self, %options) = @_;

    foreach my $line (split /\n/, $self->{stdout}) {
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

sub ss_build {
    my ($self, %options) = @_;

    foreach my $line (split /\n/, $self->{stdout}) {
        next if ($line !~ /^(tcp|udp)\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s*(\S+)/);
        my ($type, $src, $dst, $state) = ($1, $3, $4, $2);
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
            $state = $map_ss_states{$state};
            $self->{states}->{$state}++;
        }
        
        push @{$self->{connections}}, $type . "#$src_addr#$src_port#$dst_addr#$dst_port#" . lc($state);
    }
}

sub build_connections {
    my ($self, %options) = @_;

    if ($self->{option_results}->{con_mode} !~ /^ss|netstat$/) {
        $self->{output}->add_option_msg(short_msg => "Unknown --con-mode option.");
        $self->{output}->option_exit();
    }

    my ($command, $command_options) = ('netstat', '-antu 2>&1');
    if ($self->{option_results}->{con_mode} eq 'ss') {
        $command = 'ss';
        $command_options = '-a -A tcp,udp -n 2>&1';
    }

    ($self->{stdout}) = $options{custom}->execute_command(
        command => $command,
        command_options => $command_options
    );

    if ($self->{option_results}->{con_mode} eq 'ss') {
        $self->ss_build();
    } else {
        $self->netstat_build();
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

        $self->{services}->{$tag} = {
            filter => 
                ((defined($ipv) && $ipv ne '') ? $ipv : '.*?') . '#' . 
                ((defined($filter_ip_src) && $filter_ip_src ne '') ? $filter_ip_src : '.*?') . '#' . 
                ((defined($port_src) && $port_src ne '') ? $port_src : '.*?') . '#' . 
                ((defined($filter_ip_dst) && $filter_ip_dst ne '') ? $filter_ip_dst : '.*?') . '#' . 
                ((defined($port_dst) && $port_dst ne '') ? $port_dst : '.*?') . '#' . 
                ((defined($state) && $state ne '') ? lc($state) : '(?!(listen))'), 
            builtin => 0,
            number => 0
        };
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
            services => {}
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

        my $exit_code = $self->{perfdata}->threshold_check(
            value => $self->{services}->{$tag}->{number}, 
            threshold => [ { label => 'critical-service-' . $tag, 'exit_litteral' => 'critical' }, { label => 'warning-service-' . $tag, exit_litteral => 'warning' } ]
        );
        my ($perf_label, $msg) = ('service_' . $tag, "Service '$tag' connections: %d");
        if ($self->{services}->{$tag}->{builtin} == 1) {
            ($perf_label, $msg) = ($tag, $self->{services}->{$tag}->{msg});
        }

        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf($msg, $self->{services}->{$tag}->{number})
        );
        $self->{output}->perfdata_add(
            label => $perf_label,
            value => $self->{services}->{$tag}->{number},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-service-' . $tag),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-service-' . $tag),
            min => 0
        );
    }
}

sub test_applications {
    my ($self, %options) = @_;

    foreach my $tag (keys %{$self->{applications}}) {
        my $number = 0;

        foreach (keys %{$self->{applications}->{$tag}->{services}}) {
            $number += $self->{services}->{$_}->{number};
        }

        my $exit_code = $self->{perfdata}->threshold_check(
            value => $number, 
            threshold => [ { label => 'critical-app-' . $tag, 'exit_litteral' => 'critical' }, { label => 'warning-app-' . $tag, exit_litteral => 'warning' } ]
        );
        $self->{output}->output_add(
            severity => $exit_code,
            short_msg => sprintf("Applicatin '%s' connections: %d", $tag, $number)
        );
        $self->{output}->perfdata_add(
            label => 'app_' . $tag,
            value => $number,
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-app-' . $tag),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-app-' . $tag),
            min => 0
        );
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

    $self->build_connections(custom => $options{custom});
    $self->test_services();
    $self->test_applications();

    foreach (keys %{$self->{states}}) {
        $self->{output}->perfdata_add(
            label => 'con_' . $_,
            value => $self->{states}->{$_},
            min => 0
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check tcp/udp connections (udp connections are not in total. Use option '--service' to check it).
'ipx', 'x25' connections are not checked (need output to do it. If you have, you can post it in github :)

Command used: 'netstat -antu 2>&1' or 'ss -a -A tcp,udp -n 2>&1'

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

=item B<--con-mode>

Default mode for parsing and command: 'netstat' (default) or 'ss'.

=back

=cut
