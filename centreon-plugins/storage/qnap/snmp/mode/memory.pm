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

package storage::qnap::snmp::mode::memory;

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
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
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

sub convert_bytes {
    my ($self, %options) = @_;
    my $multiple = defined($options{network}) ? 1000 : 1024;
    my %units = (K => 1, M => 2, G => 3, T => 4);
    
    if ($options{value} !~ /^\s*([0-9\.\,]+)\s*(.)/) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    output => "Cannot convert value '" . $options{value} . "'");
        $self->{output}->display();
        $self->{output}->exit();
    }
    my ($bytes, $unit) = ($1, uc($2));
    
    for (my $i = 0; $i < $units{$unit}; $i++) {
        $bytes *= $multiple;
    }

    return $bytes;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_SystemTotalMem = '.1.3.6.1.4.1.24681.1.2.2.0';
    my $oid_SystemFreeMem = '.1.3.6.1.4.1.24681.1.2.3.0';

    my $result = $self->{snmp}->get_leef(oids => [ $oid_SystemTotalMem, $oid_SystemFreeMem ],
                                         nothing_quit => 1);
    my $total_size = $self->convert_bytes(value => $result->{$oid_SystemTotalMem});
    my $memory_free = $self->convert_bytes(value => $result->{$oid_SystemFreeMem});    
    my $memory_used = $total_size - $memory_free;

    my $prct_used = $memory_used * 100 / $total_size;
    my $prct_free = 100 - $prct_used;

    my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                                        $total_value . " " . $total_unit,
                                        $used_value . " " . $used_unit, $prct_used,
                                        $free_value . " " . $free_unit, $prct_free));

    $self->{output}->perfdata_add(label => "used", unit => 'B',
                                  value => int($memory_used),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                  min => 0, max => int($total_size));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check memory usage (NAS.mib).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
    
