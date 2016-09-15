#
# Copyright 2016 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
