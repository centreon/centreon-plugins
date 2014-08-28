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

package network::cisco::common::mode::memory;

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
                                  "filter-pool:s"           => { name => 'filter_pool' },
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

sub check_table_memory {
    my ($self, %options) = @_;

    my $checked = 0;
    foreach my $oid (keys %{$self->{results}->{$options{entry}}}) {
        next if ($oid !~ /^$options{poolName}/);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $memory_name = $self->{results}->{$options{entry}}->{$oid};
        my $memory_used = $self->{results}->{$options{entry}}->{$options{poolUsed} . '.' . $instance};
        my $memory_free = $self->{results}->{$options{entry}}->{$options{poolFree} . '.' . $instance};
        
        next if ($memory_name eq '');

        $checked = 1;

        my $total_size = $memory_used + $memory_free;
        my $prct_used = $memory_used * 100 / $total_size;
        my $prct_free = 100 - $prct_used;

        my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_size);
        my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $memory_used);
        my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $memory_free);

        $self->{output}->output_add(long_msg => sprintf("Memory '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $memory_name,
                                            $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,
                                            $free_value . " " . $free_unit, $prct_free));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
             $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $memory_name,
                                            $total_value . " " . $total_unit,
                                            $used_value . " " . $used_unit, $prct_used,
                                            $free_value . " " . $free_unit, $prct_free));
        }

        $self->{output}->perfdata_add(label => "used_" . $memory_name,
                                      value => $memory_used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size),
                                      min => 0, max => $total_size);
    }
    
    return $checked;
}

sub check_percent_memory {
    my ($self, %options) = @_;

    my $checked = 0;
    foreach my $oid (keys %{$self->{results}->{$options{entry}}}) {
        next if ($oid !~ /^$options{memUsage}/);
        $oid =~ /\.([0-9]+)$/;
        my $instance = $1;
        my $memory_usage = $self->{results}->{$options{entry}}->{$oid};

        next if ($memory_usage eq '');

        $checked = 1;

        my $exit = $self->{perfdata}->threshold_check(value => $memory_usage,
                               threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Memory used : %.2f%%", $memory_usage));
        }

        $self->{output}->perfdata_add(label => "utilization",
                                      value => $memory_usage,
                                      unit => "%",
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }

    return $checked;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_ciscoMemoryPoolEntry = '.1.3.6.1.4.1.9.9.48.1.1.1';
    my $oid_ciscoMemoryPoolName = '.1.3.6.1.4.1.9.9.48.1.1.1.2';
    my $oid_ciscoMemoryPoolUsed = '.1.3.6.1.4.1.9.9.48.1.1.1.5'; # in B
    my $oid_ciscoMemoryPoolFree = '.1.3.6.1.4.1.9.9.48.1.1.1.6'; # in B

    # OIDs for Nexus
    my $oid_cseSysMemoryEntry = '.1.3.6.1.4.1.9.9.305.1.1';
    my $oid_cseSysMemoryUtilization = '.1.3.6.1.4.1.9.9.305.1.1.2';

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_ciscoMemoryPoolEntry,
                                                              start => $oid_ciscoMemoryPoolName, end => $oid_ciscoMemoryPoolFree
                                                            },
                                                            { oid => $oid_cseSysMemoryEntry,
                                                              start => $oid_cseSysMemoryUtilization, end => $oid_cseSysMemoryUtilization }],
                                                   nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Memory is ok.');
    
    if (!$self->check_table_memory(entry => $oid_ciscoMemoryPoolEntry, poolName => $oid_ciscoMemoryPoolName, poolUsed => $oid_ciscoMemoryPoolUsed, poolFree => $oid_ciscoMemoryPoolFree)
        && !$self->check_percent_memory(entry => $oid_cseSysMemoryEntry, memUsage => $oid_cseSysMemoryUtilization)
        ) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => sprintf("Cannot find Memory informations."));
    }

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check memory usage (CISCO-MEMORY-POOL-MIB and CISCO-SYSTEM-EXT-MIB).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--filter-pool>

Filter pool to check (can use regexp).

=back

=cut
    
