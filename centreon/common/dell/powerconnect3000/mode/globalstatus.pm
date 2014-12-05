################################################################################
# Copyright 2005-2014 MERETHIS
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

package centreon::common::dell::powerconnect3000::mode::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %states = (
    3 => ['ok', 'OK'], 
    4 => ['non critical', 'WARNING'],
    5 => ['critical', 'CRITICAL'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
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

    my $oid_productStatusGlobalStatus = '.1.3.6.1.4.1.674.10895.3000.1.2.110.1';
    my $oid_productIdentificationDisplayName = '.1.3.6.1.4.1.674.10895.3000.1.2.100.1';
    my $oid_productIdentificationBuildNumber = '.1.3.6.1.4.1.674.10895.3000.1.2.100.5';
    my $oid_productIdentificationServiceTag = '.1.3.6.1.4.1.674.10895.3000.1.2.100.8.1.4';
	
	my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_productStatusGlobalStatus, start => $oid_productStatusGlobalStatus },
                                                            { oid => $oid_productIdentificationDisplayName, start => $oid_productIdentificationDisplayName },
                                                            { oid => $oid_productIdentificationBuildNumber, start => $oid_productIdentificationBuildNumber },
                                                            { oid => $oid_productIdentificationServiceTag, start => $oid_productIdentificationServiceTag },
                                                           ],
													nothing_quit => 1 );

	my $globalStatus = $result->{$oid_productStatusGlobalStatus}->{$oid_productStatusGlobalStatus . '.0'};
	my $displayName = $result->{$oid_productIdentificationDisplayName}->{$oid_productIdentificationDisplayName . '.0'};
	my $buildNumber = $result->{$oid_productIdentificationBuildNumber}->{$oid_productIdentificationBuildNumber . '.0'};

	my $serviceTag;
	foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_productIdentificationServiceTag}})) {
        next if ($key !~ /^$oid_productIdentificationServiceTag\.(\d+)$/);
		if (!defined($serviceTag)) {
			$serviceTag = $result->{$oid_productIdentificationServiceTag}->{$oid_productIdentificationServiceTag . '.' . $1};
		} else {
			$serviceTag .= ',' . $result->{$oid_productIdentificationServiceTag}->{$oid_productIdentificationServiceTag . '.' . $1};
		}
	}
    
    $self->{output}->output_add(severity =>  ${$states{$globalStatus}}[1],
                                short_msg => sprintf("Overall global status is '%s' [Product: %s] [Version: %s] [Service Tag: %s]", 
                                                ${$states{$globalStatus}}[0], $displayName, $buildNumber, $serviceTag));
                                                
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the overall status of Dell Powerconnect 3000.

=over 8

=back

=cut
    
