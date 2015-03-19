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

package network::juniper::common::junos::mode::components::operating;

use strict;
use warnings;

my %map_operating_states = (
    1 => 'unknown', 
    2 => 'running', 
    3 => 'ready', 
    4 => 'reset',
    5 => 'runningAtFullSpeed',
    6 => 'down',
    7 => 'standby',
);

# In MIB 'mib-jnx-chassis'
my $mapping = {
    jnxOperatingDescr => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.5' },
    jnxOperatingState => { oid => '.1.3.6.1.4.1.2636.3.1.13.1.6', map => \%map_operating_states },
};
my $oid_jnxOperatingEntry = '.1.3.6.1.4.1.2636.3.1.13.1';

sub load {
    my (%options) = @_;
    
    push @{$options{request}}, { oid => $oid_jnxOperatingEntry, start => $mapping->{jnxOperatingDescr}->{oid}, end => $mapping->{jnxOperatingState}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking operatings");
    $self->{components}->{operating} = {name => 'operatings', total => 0, skip => 0};
    return if ($self->check_exclude(section => 'operating'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_jnxOperatingEntry}})) {
        next if ($oid !~ /^$mapping->{jnxOperatingDescr}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_jnxOperatingEntry}, instance => $instance);
        
        next if ($self->check_exclude(section => 'operating', instance => $instance));
        $self->{components}->{operating}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Operating '%s' state is %s [instance: %s]", 
                                                        $result->{jnxOperatingDescr}, $result->{jnxOperatingState}, $instance));
        my $exit = $self->get_severity(section => 'operating', value => $result->{jnxOperatingState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Operating '%s' state is %s", 
                                    $result->{jnxOperatingDescr}, $result->{jnxOperatingState}));
        }
    }
}

1;