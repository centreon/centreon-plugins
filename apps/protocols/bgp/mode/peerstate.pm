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

package apps::protocols::bgp::mode::peerstate;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_states_peer = (
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    return $self;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_bgpPeerEntry = '.1.3.6.1.2.1.15.3.1';
    my $oid_bgpPeerState = '.1.3.6.1.2.1.15.3.1.2';
    my $oid_bgpPeerAdminStatus = '.1.3.6.1.2.1.15.3.1.3';
    my $oid_bgpPeerRemoteAs = '.1.3.6.1.2.1.15.3.1.9';    
    
    my $result = $self->{snmp}->get_table(oid => $oid_bgpPeerEntry);
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_bgpPeerState\.(.*)$/);
        my $instance = $1;

        my $bgpPeerState = $result->{$oid_bgpPeerState . '.' . $instance};
        my $bgpPeerAdminStatus = $result->{$oid_bgpPeerAdminStatus . '.' . $instance};
        my $bgpPeerRemoteAs = $result->{$oid_bgpPeerRemoteAs . '.' . $instance};

        $self->{output_add}->output_add(long_msg => sprintf("Peer '%s' (Remote AS: '%d') state is '%s'", 
                                                            $instance, $bgpPeerRemoteAs, $map_states_peer{$bgpPeerState}));
        
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => sprintf("All peers are in an Established state"));

        if ($bgpPeerState != 6) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Peer '%s' (Remote AS number: '%d') state is '%s'",
                                                           $instance, $bgpPeerRemoteAs, $map_states_peer{$bgpPeerState}));
        } elsif ($bgpPeerAdminStatus < 2) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Peer '%s' (Remote AS number: '%d') admin state is '%s'",
                                                            $instance, $bgpPeerRemoteAs, $map_admin_state{$bgpPeerAdminStatus}));
        }     
        
    }
            
}

1; 

__END__

=head1 MODE

Check remote BGP Peer State (BGP4-MIB.mib and rfc4273)

=over 8

=back

=cut


