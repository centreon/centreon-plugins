################################################################################
## Copyright 2005-2013 MERETHIS
## Centreon is developped by : Julien Mathis and Romain Le Merlus under
## GPL Licence 2.0.
##
## This program is free software; you can redistribute it and/or modify it under
## the terms of the GNU General Public License as published by the Free Software
## Foundation ; either version 2 of the License.
##
## This program is distributed in the hope that it will be useful, but WITHOUT ANY
## WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
## PARTICULAR PURPOSE. See the GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License along with
## this program; if not, see <http://www.gnu.org/licenses>.
##
## Linking this program statically or dynamically with other modules is making a
## combined work based on this program. Thus, the terms and conditions of the GNU
## General Public License cover the whole combination.
##
## As a special exception, the copyright holders of this program give MERETHIS
## permission to link this program with independent modules to produce an executable,
## regardless of the license terms of these independent modules, and to copy and
## distribute the resulting executable under terms of MERETHIS choice, provided that
## MERETHIS also meet, for each linked independent module, the terms  and conditions
## of the license of that module. An independent module is a module which is not
## derived from this program. If you modify this program, you may extend this
## exception to your version of the program, but you are not obliged to do so. If you
## do not wish to do so, delete this exception statement from your version.
##
## For more information : contact@centreon.com
## Authors : Simon Bomm <sbomm@merethis.com>
##
#####################################################################################

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
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
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
    
    if (defined $self->{option_results}->{peer}) {

        my $bgpPeerState = $result->{$oid_bgpPeerState . '.' . $self->{option_results}->{peer}};
        my $bgpPeerAdminStatus = $result->{$oid_bgpPeerAdminStatus . '.' . $self->{option_results}->{peer}};
        my $bgpPeerRemoteAs = $result->{$oid_bgpPeerRemoteAs . '.' . $self->{option_results}->{peer}};
        my $bgpPeerInUpdateElpasedTime = $result->{$oid_bgpPeerInUpdateElpasedTime . '.' . $self->{option_results}->{peer}};
        my $bgpLocalInfos = $result->{$oid_bgpPeerLocalAddr . '.' . $self->{option_results}->{peer}} . ':' . $result->{$oid_bgpPeerLocalPort . '.' . $self->{option_results}->{peer}};
        my $bgpRemoteInfos = $result->{$oid_bgpPeerRemoteAddr. '.' . $self->{option_results}->{peer}} . ':' . $result->{$oid_bgpPeerRemotePort . '.' . $self->{option_results}->{peer}};


        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("Peer %s AdminState=%s Connection=%s [Remote Addr:%s AS:%d] [Last Update %d s]",                                                              $self->{option_results}->{peer}, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState}                                                             , $bgpRemoteInfos, $bgpPeerRemoteAs, $bgpPeerInUpdateElpasedTime));

        if ($bgpPeerAdminStatus < 2) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Peer '%s' AdminState is '%s' Remote AS: %s Remote Addr: %s",
                                                             $self->{option_results}->{peer}, $map_admin_state{$bgpPeerAdminStatus}, $bgpPeerRemoteAs, $bgpRemoteInfos)
                                        );
        } elsif ($bgpPeerState != 6) {
            my $exit = $self->get_severity(section => 'peers', value => $map_peer_state{$bgpPeerState});
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Peer %s AdminState=%s Connection=%s [Remote Addr:%s AS:%d] [Last Update %d s]",                                                             $self->{option_results}->{peer}, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState}, $bgpRemoteInfos, $bgpPeerRemoteAs, $bgpPeerInUpdateElpasedTime));

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
                                            short_msg => sprintf("Peer '%s' AdminState is '%s' Remote AS: %s Remote Addr: %s \n",
                                                                 $instance, $map_admin_state{$bgpPeerAdminStatus}, $bgpPeerRemoteAs, 
								 $bgpRemoteInfos));
            } elsif ($bgpPeerState != 6) {
                my $exit = $self->get_severity(section => 'peers', value => $map_peer_state{$bgpPeerState});
                $self->{output}->output_add(severity => $exit,
                                            short_msg =>  sprintf("Peer %s AdminState=%s Connection=%s [Remote Addr:%s AS:%d] [Last Update %d s] \n",                                                             $instance, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState}, $bgpRemoteInfos, $bgpPeerRemoteAs, $bgpPeerInUpdateElpasedTime));

            }

            $self->{output}->output_add(long_msg => sprintf("Peer:%s Local:%s Remote:%s AS:%d AdminState:'%s' Connection:'%s' Last Update:%d sec \n", $instance, $bgpLocalInfos, $bgpRemoteInfos, $bgpPeerRemoteAs, $map_admin_state{$bgpPeerAdminStatus}, $map_peer_state{$bgpPeerState}, $bgpPeerInUpdateElpasedTime));


        }

    }
    
    $self->{output}->display();
    $self->{output}->exit();       
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


