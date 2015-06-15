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
# Authors : Simon BOMM <sbomm@centreon.com>
#
####################################################################################

package apps::visimax::mode::cameraconnection;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_state = (
    0 => 'connected',
    1 => 'disconnected',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';

    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"              => { name => 'warning' },
                                  "critical:s"             => { name => 'critical', default => '0' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp}; 

    my $i = 0;
    my $count = 0;
    
    my $oid_etatCameras = '.1.3.6.1.4.1.26956.9';
	
    my $result = $self->{snmp}->get_table(oid => [$oid_etatCameras], nothing_quit => 1);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All cameras are connected to the system (%d/%d)');


    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        $key =~ /\.([0-9]+)$/;
        
	my $id_cam = $1;
        $count++;
        my $state = $result->{$id_cam};

        $self->{output}->output_add(severity => 'CRITICAL',
                                    long_msg => sprintf("Camera %u state is '%s'", $id_cam, $map_state{$state}));
       		
        if ($state != 0) {
	    $i++;
	}
    }
    
    if ($i > 0) {
        my $exit = $self->{perfdata}->threshold_check(value => $i,
                                                      threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', 'exit_litteral' => 'warning'} ]);
        $self->{output}->output_add(severity => $exit,
	                            short_msg => sprintf('%d cameras are disconnected of the system (%d/%d)', $i, $i, $count));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check cameras state from visimax.mib - Plugin triggers a critical when one or more cameras are disconnected of the system.

=item B<--warning>

Trigger a warning if number of disconnected cameras is above ((default none)

=item B<--critical>

Trigger a critical if number of disconnected cameras is above (default 0)

=back

=cut
