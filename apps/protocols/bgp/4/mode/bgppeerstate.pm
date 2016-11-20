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

package apps::protocols::bgp::4::mode::bgppeerstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_peer_state = (
    1 => 'idle',
    2 => 'connect',
    3 => 'active',
    4 => 'opensent',
    5 => 'openconfirm',
    6 => 'established',
);

my %map_admin_state = (
    1 => 'stop',
    2 => 'start',
);

my $thresholds = {
    peers => [
        ['idle', 'CRITICAL'],
        ['active', 'CRITICAL'],
        ['connect', 'CRITICAL'],
        ['opensent', 'WARNING'],
        ['openconfirm', 'WARNING'],
        ['established', 'OK'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';

    $options{options}->add_options(arguments =>
                                {
                                  "peer:s"               => { name => 'peer', },
                                  "threshold-overload:s@"   => { name => 'threshold_overload' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    my $oid_bgpPeerTable = '.1.3.6.1.2.1.15.3';
    my $oid_bgpPeerState = '.1.3.6.1.2.1.15.3.1.2';
    my $oid_bgpPeerAdminStatus = '.1.3.6.1.2.1.15.3.1.3';
    my $oid_bgpPeerRemoteAs = '.1.3.6.1.2.1.15.3.1.9';    
    my $oid_bgpPeerLocalAddr = '.1.3.6.1.2.1.15.3.1.5';
    my $oid_bgpPeerLocalPort = '.1.3.6.1.2.1.15.3.1.6';
    my $oid_bgpPeerRemoteAddr = '.1.3.6.1.2.1.15.3.1.7';
    my $oid_bgpPeerRemotePort = '.1.3.6.1.2.1.15.3.1.8';
    my $oid_bgpPeerInUpdateElpasedTime = '.1.3.6.1.2.1.15.3.1.24';    

    my $result = $self->{snmp}->get_table(oid => $oid_bgpPeerTable, nothing_quit => 1);
    
    if (defined($self->{option_results}->{peer})) {
        my $bgpPeerState = $result->{$oid_bgpPeerState . '.' . $self->{option_results}->{peer}};
        my $bgpPeerAdminStatus = $result->{$oid_bgpPeerAdminStatus . '.' . $self->{option_results}->{peer}};
        my $bgpPeerRemoteAs = $result->{$oid_bgpPeerRemoteAs . '.' . $self->{option_results}->{peer}};
        my $bgpPeerInUpdateElpasedTime = $result->{$oid_bgpPeerInUpdateElpasedTime . '.' . $self->{option_results}->{peer}};
        my $bgpLocalInfos = $result->{$oid_bgpPeerLocalAddr . '.' . $self->{option_results}->{peer}} . ':' . $result->{$oid_bgpPeerLocalPort . '.' . $self->{option_results}->{peer}};
        my $bgpRemoteInfos = $result->{$oid_bgpPeerRemoteAddr. '.' . $self->{option_results}->{peer}} . ':' . $result->{$oid_bgpPeerRemotePort . '.' . $self->{option_results}->{peer}};

        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("Peer %s AdminState=%s Connection=%s [Remote Addr:%s AS:%d] [Last Update %d s]",  
                                                         $self->{option_results}->{peer}, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState},
                                                         $bgpRemoteInfos, $bgpPeerRemoteAs, $bgpPeerInUpdateElpasedTime));
        if ($bgpPeerAdminStatus < 2) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Peer '%s' AdminState is '%s' Remote AS: %s Remote Addr: %s",
                                                             $self->{option_results}->{peer}, $map_admin_state{$bgpPeerAdminStatus}, $bgpPeerRemoteAs, $bgpRemoteInfos)
                                        );
        } else {
            my $exit = $self->get_severity(section => 'peers', value => $map_peer_state{$bgpPeerState});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Peer %s AdminState=%s Connection=%s [Remote Addr:%s AS:%d] [Last Update %d s]", 
                                                    $self->{option_results}->{peer}, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState}, $bgpRemoteInfos, $bgpPeerRemoteAs, $bgpPeerInUpdateElpasedTime));
            }
        }   
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("All BGP peers are in an OK state"));

        foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
            next if ($key !~ /^$oid_bgpPeerState\.(.*)$/);
            my $instance = $1;
            next if ($instance eq '0.0.0.0');
        
            my $bgpPeerState = $result->{$oid_bgpPeerState . '.' . $instance};
            my $bgpPeerAdminStatus = $result->{$oid_bgpPeerAdminStatus . '.' . $instance};
            my $bgpPeerRemoteAs = $result->{$oid_bgpPeerRemoteAs . '.' . $instance};
            my $bgpPeerInUpdateElpasedTime = $result->{$oid_bgpPeerInUpdateElpasedTime . '.' . $instance};
            my $bgpLocalInfos = $result->{$oid_bgpPeerLocalAddr . '.' . $instance} . ':' . $result->{$oid_bgpPeerLocalPort . '.' . $instance};
            my $bgpRemoteInfos = $result->{$oid_bgpPeerRemoteAddr. '.' . $instance} . ':' . $result->{$oid_bgpPeerRemotePort . '.' . $instance};
        
            if ($bgpPeerAdminStatus < 2) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Peer '%s' AdminState is '%s' Remote AS: %s Remote Addr: %s",
                                                                 $instance, $map_admin_state{$bgpPeerAdminStatus}, $bgpPeerRemoteAs, 
                                                                 $bgpRemoteInfos));
            } else {
                my $exit = $self->get_severity(section => 'peers', value => $map_peer_state{$bgpPeerState});
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit,
                                                short_msg => sprintf("Peer %s AdminState=%s Connection=%s [Remote Addr:%s AS:%d] [Last Update %d s]",
                                                                  $instance, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState}, $bgpRemoteInfos, $bgpPeerRemoteAs, $bgpPeerInUpdateElpasedTime));
                }
            }

            $self->{output}->output_add(long_msg => sprintf("Peer:%s Local:%s Remote:%s AS:%d AdminState:'%s' Connection:'%s' Last Update:%d sec", 
                                                            $instance, $bgpLocalInfos, $bgpRemoteInfos, $bgpPeerRemoteAs, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState}, $bgpPeerInUpdateElpasedTime));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();       
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default

    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }

    return $status;
}

1; 

__END__

=head1 MODE

Check BGP basic infos (BGP4-MIB.mib and rfc4273)

Default is Active,Connect,Idle=CRITICAL // Opensent,Openconfirm=WARNING // Established=OK

=over 8

=item B<--peer>

Specify IP of a specific peer (otherwise all peer are checked

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='peers,CRITICAL,^(?!(ok)$)'


=back

=cut


