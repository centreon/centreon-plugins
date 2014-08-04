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
# Authors : Simon Bomm <sbomm@merethis.com>
#
####################################################################################

package network::f5::mode::connections;

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
                                  "warning-client:s"               => { name => 'warning_client' },
                                  "critical-client:s"              => { name => 'critical_client' },
                                  "warning-server:s"               => { name => 'warning_server' },
                                  "critical-server:s"              => { name => 'critical_server' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-client', value => $self->{option_results}->{warning_client})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-client threshold '" . $self->{option_results}->{option_results}->{warning_client} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-client', value => $self->{option_results}->{critical_client})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-client threshold '" . $self->{option_results}->{critical_client} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-server', value => $self->{option_results}->{warning_server})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning-server threshold '" . $self->{option_results}->{warning_client} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-server', value => $self->{option_results}->{critical_server})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical-server threshold '" . $self->{option_results}->{critical_client} . "'.");
       $self->{output}->option_exit();
    }


}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $oid_sysStatClientCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.8.0';
    my $oid_sysStatServerCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.15.0';
    my $oid_sysClientsslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.2.0';
    my $oid_sysServersslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.10.2.0';
      
    my $result = $self->{snmp}->get_leef(oids => [$oid_sysStatClientCurConns, $oid_sysStatServerCurConns, $oid_sysClientsslStatCurConns, $oid_sysServersslStatCurConns], nothing_quit => 0);
    
    my $sysStatClientCurConns = $result->{$oid_sysStatClientCurConns};
    my $sysStatServerCurConns = $result->{$oid_sysStatServerCurConns};
    my $sysClientsslStatCurConns = $result->{$oid_sysClientsslStatCurConns};
    my $sysServersslStatCurConns = $result->{$oid_sysServersslStatCurConns};
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $sysStatClientCurConns, threshold => [ { label => 'critical-client', 'exit_litteral' => 'critical' }, { label => 'warning-client', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $sysStatServerCurConns, threshold => [ { label => 'critical-server', 'exit_litteral' => 'critical' }, { label => 'warning-server', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Current connections : Client = %d (SSL: %d) , Server = %d (SSL: %d)",
                                                     $sysStatClientCurConns, $sysClientsslStatCurConns, 
                                                     $sysStatServerCurConns, $sysServersslStatCurConns));
    $self->{output}->perfdata_add(label => "Client", unit => 'con',
                                  value => $sysStatClientCurConns,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-client'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-client'),
                                  );
    $self->{output}->perfdata_add(label => "Server", unit => 'con',
                                  value => $sysStatServerCurConns,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-server'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-server'),
                                  );
    $self->{output}->perfdata_add(label => "ClientSSL", unit => 'con',
                                  value => $sysClientsslStatCurConns);
    $self->{output}->perfdata_add(label => "ServerSSL", unit => 'con',
                                  value => $sysServersslStatCurConns);
   

    $self->{output}->display();
    $self->{output}->exit();



}
    
1;

__END__

=head1 MODE

Check current connections on F5 BIG IP device.

=over 8

=item B<--warning-client>

Threshold warning (current client connection number)

=item B<--critical-client>

Threshold critical (current client connection number)

=item B<--warning-server>

Threshold warning (current server connection number)

=item B<--critical-server>

Threshold critical (current server connection number)

=back

=cut
    
