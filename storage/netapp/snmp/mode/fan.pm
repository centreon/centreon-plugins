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

package storage::netapp::snmp::mode::fan;

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

    my $oid_envFailedFanCount = '.1.3.6.1.4.1.789.1.2.4.2';
    my $oid_envFailedFanMessage = '.1.3.6.1.4.1.789.1.2.4.3';
    my $oid_nodeName = '.1.3.6.1.4.1.789.1.25.2.1.1';
    my $oid_nodeEnvFailedFanCount = '.1.3.6.1.4.1.789.1.25.2.1.19';
    my $oid_nodeEnvFailedFanMessage = '.1.3.6.1.4.1.789.1.25.2.1.20';
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_envFailedFanCount }, 
                                                            { oid => $oid_envFailedFanMessage },
                                                            { oid => $oid_nodeName },
                                                            { oid => $oid_nodeEnvFailedFanCount },
                                                            { oid => $oid_nodeEnvFailedFanMessage }
                                                            ], nothing_quit => 1);
    
    if (defined($results->{$oid_envFailedFanCount}->{$oid_envFailedFanCount . '.0'})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Fans are ok.');
        if ($results->{$oid_envFailedFanCount}->{$oid_envFailedFanCount . '.0'} != 0) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("'%d' fans are failed [message: %s].", 
                                                        $results->{$oid_envFailedFanCount}->{$oid_envFailedFanCount . '.0'},
                                                        $results->{$oid_envFailedFanMessage}->{$oid_envFailedFanMessage . '.0'}));
        }
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Fans are ok on all nodes');
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$results->{$oid_nodeEnvFailedFanCount}})) {
            $oid =~ /^$oid_nodeEnvFailedFanCount\.(.*)$/;
            my $instance = $1;
            my $name = $results->{$oid_nodeName}->{$oid_nodeName . '.' . $instance};
            my $count = $results->{$oid_nodeEnvFailedFanCount}->{$oid};
            my $message = $results->{$oid_nodeEnvFailedFanMessage}->{$oid_nodeEnvFailedFanMessage . '.' . $instance};
            $self->{output}->output_add(long_msg => sprintf("'%d' fans are failed on node '%s' [message: %s]", 
                                                            $count, $name, defined($message) ? $message : '-'));
            if ($count != 0) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("'%d' fans are failed on node '%s' [message: %s]", 
                                                        $count, $name, defined($message) ? $message : '-'));
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check if fans are failed (not operating within the recommended RPM range).

=over 8

=back

=cut
    