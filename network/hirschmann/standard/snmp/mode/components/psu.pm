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

package network::hirschmann::standard::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    1 => 'ok', 
    2 => 'failed', 
    3 => 'notInstalled', 
    4 => 'unknown',
);

# In MIB 'hmpriv.mib'
my $mapping = {
    hmPSState => { oid => '.1.3.6.1.4.1.2352.2.4.1.2.1.2', map => \%map_psu_status },
};

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $mapping->{hmPSState}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{hmPSState}->{oid}}})) {
        next if ($oid !~ /^$mapping->{hmPSState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{hmPSState}->{oid}}, instance => $instance);

        next if ($self->check_exclude(section => 'psu', instance => $instance));
        next if ($result->{hmPSState} =~ /notInstalled/i && 
                 $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s [instance: %s].",
                                    $instance, $result->{hmPSState},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{hmPSState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s' status is %s",
                                                             $instance, $result->{hmPSState}));
        }
    }
}

1;