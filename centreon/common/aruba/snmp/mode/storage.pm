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

package centreon::common::aruba::snmp::mode::storage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %map_storage_type = (
    1 => 'ram',
    2 => 'flashMemory'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"       => { name => 'warning' },
                                  "critical:s"      => { name => 'critical' },
                                  "filter-name:s"   => { name => 'filter_name' },
                                  "filter-type:s"   => { name => 'filter_type' },
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
    
    my $oid_wlsxSysExtStorageEntry = '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1';
    my $oid_sysExtStorageType = '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.2';
    my $oid_sysExtStorageName = '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.5';
    my $oid_sysExtStorageSize = '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.3'; # MB
    my $oid_sysExtStorageUsed = '.1.3.6.1.4.1.14823.2.2.1.2.1.14.1.4'; # MB
    
    my $storage_num = 0;
    my $result = $self->{snmp}->get_table(oid => $oid_wlsxSysExtStorageEntry, nothing_quit => 1);

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All storages are ok.');
    
    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_sysExtStorageSize/);
        $oid =~ /\.([0-9]+)$/;
        
        my $name = $result->{$oid_sysExtStorageName . '.' . $1};
        my $type = $result->{$oid_sysExtStorageType . '.' . $1};;
        my $total_used = $result->{$oid_sysExtStorageUsed . '.' . $1} * 1024 * 1024;
        my $total_size = $result->{$oid_sysExtStorageSize . '.' . $1} * 1024 * 1024;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => sprintf("Skipping storage '%s'.", $name));
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $map_storage_type{$type} !~ /$self->{option_results}->{filter_type}/i) {
            $self->{output}->output_add(long_msg => sprintf("Skipping storage '%s'.", $name));
            next;
        }
        
        $storage_num++;
        my $total_free = $total_size - $total_used;
        my $prct_used = $total_used * 100 / $total_size;
        my $prct_free = 100 - $prct_used;
        
        my $exit = $self->{perfdata}->threshold_check(value => $prct_used, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $total_size);
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $total_used);
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $total_free);
        
        $self->{output}->output_add(long_msg => sprintf("Storage '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name,
                                                        $total_size_value . " " . $total_size_unit,
                                                        $total_used_value . " " . $total_used_unit, $prct_used,
                                                        $total_free_value . " " . $total_free_unit, $prct_free));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Storage '%s' Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", $name,
                                                             $total_size_value . " " . $total_size_unit,
                                                             $total_used_value . " " . $total_used_unit, $prct_used,
                                                             $total_free_value . " " . $total_free_unit, $prct_free));
        }    

        $self->{output}->perfdata_add(label => 'used_' . $name, unit => 'B',
                                      value => $total_used,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $total_size, cast_int => 1),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $total_size, cast_int => 1),
                                      min => 0, max => $total_size);
    }
    
    if ($storage_num == 0) {
        $self->{output}->add_option_msg(short_msg => "No storage information found (maybe your filters)");
        $self->{output}->option_exit();
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check storage device usage (aruba-systemext).

=over 8

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=item B<--filter-name>

Filter storage device name (regexp can be used).

=item B<--filter-type>

Filter storage device type (regexp can be used).
Can use: 'ram', 'flashMemory'

=back

=cut
