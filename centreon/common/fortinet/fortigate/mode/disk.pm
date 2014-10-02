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

package centreon::common::fortinet::fortigate::mode::disk;

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
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_fgSysDiskUsage = '.1.3.6.1.4.1.12356.101.4.1.6.0'; # in MB
    my $oid_fgSysDiskCapacity = '.1.3.6.1.4.1.12356.101.4.1.7.0'; # in MB
    $self->{result} = $self->{snmp}->get_leef(oids => [ $oid_fgSysDiskUsage, $oid_fgSysDiskCapacity ], 
                                              nothing_quit => 1);
    
    if (!defined($self->{result}->{$oid_fgSysDiskCapacity}) || $self->{result}->{$oid_fgSysDiskCapacity} == 0) {
        $self->{output}->output_add(severity => 'ok',
                                    short_msg => sprintf("No disk present."));
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    my $fgSysDiskUsage = $self->{result}->{$oid_fgSysDiskUsage} * 1024 * 1024;
    my $fgSysDiskCapacity = $self->{result}->{$oid_fgSysDiskCapacity} * 1024 * 1024;
    
    my $prct = $fgSysDiskUsage * 100 / $fgSysDiskCapacity;
    
    my $exit = $self->{perfdata}->threshold_check(value => $prct, 
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $fgSysDiskCapacity);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Disk Usage: %.2f%% used [Total: %s]", 
                                                     $prct, $size_value . " " . $size_unit));
    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => $fgSysDiskUsage,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $fgSysDiskCapacity, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $fgSysDiskCapacity, cast_int => 1),
                                  min => 0, max => $fgSysDiskCapacity);
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system disk usage (FORTINET-FORTIGATE).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut