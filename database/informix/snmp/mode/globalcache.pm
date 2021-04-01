#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package database::informix::snmp::mode::globalcache;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_usage_calc {
    my ($self, %options) = @_;

    my $diff_logical = $options{new_datas}->{$self->{instance} . '_rdbmsSrvInfoLogical' . $options{extra_options}->{label_ref}} - 
        $options{old_datas}->{$self->{instance} . '_rdbmsSrvInfoLogical' . $options{extra_options}->{label_ref}};
    my $diff_disk = $options{new_datas}->{$self->{instance} . '_rdbmsSrvInfoDisk' . $options{extra_options}->{label_ref}} - 
        $options{old_datas}->{$self->{instance} . '_rdbmsSrvInfoDisk' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{prct} = $diff_logical <= 0 ? 0 : (100 * ($diff_logical - $diff_disk) / $diff_logical);

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_instances_output', message_multiple => 'All instances are ok' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'read', set => {
                key_values => [ { name => 'rdbmsSrvInfoDiskReads', diff => 1 }, { name => 'rdbmsSrvInfoLogicalReads', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'Reads' },
                output_template => 'Read Cached hitrate at %.2f%%',
                threshold_use => 'prct', output_use => 'prct',
                perfdatas => [
                    { label => 'read', value => 'prct', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write', set => {
                key_values => [ { name => 'rdbmsSrvInfoDiskWrites', diff => 1 }, { name => 'rdbmsSrvInfoLogicalWrites', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'Writes' },
                output_template => 'Write Cached hitrate at %.2f%%',
                threshold_use => 'prct', output_use => 'prct',
                perfdatas => [
                    { label => 'write', value => 'prct', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_instances_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
    });
    
    return $self;
}

my $mapping = {
    rdbmsSrvInfoDiskReads       => { oid => '.1.3.6.1.2.1.39.1.6.1.3' },
    rdbmsSrvInfoLogicalReads    => { oid => '.1.3.6.1.2.1.39.1.6.1.4' },
    rdbmsSrvInfoDiskWrites      => { oid => '.1.3.6.1.2.1.39.1.6.1.5' },
    rdbmsSrvInfoLogicalWrites   => { oid => '.1.3.6.1.2.1.39.1.6.1.6' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_applName = '.1.3.6.1.2.1.27.1.1.2';
    my $oid_rdbmsSrvInfoEntry = '.1.3.6.1.2.1.39.1.6.1';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $oid_applName },
            { oid => $oid_rdbmsSrvInfoEntry, start => $mapping->{rdbmsSrvInfoDiskReads}->{oid}, end => $mapping->{rdbmsSrvInfoLogicalWrites}->{oid} },
        ], nothing_quit => 1
    );

    $self->{global} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_rdbmsSrvInfoEntry}}) {
        next if ($oid !~ /^$mapping->{rdbmsSrvInfoDiskReads}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_rdbmsSrvInfoEntry}, instance => $instance);
        
        my $name = 'default';
        $name = $snmp_result->{$oid_applName}->{$oid_applName . '.' . $instance} 
            if (defined($snmp_result->{$oid_applName}->{$oid_applName . '.' . $instance}));
        
        $self->{global}->{$name} = { 
            display => $name, 
            %$result
        };
    }
    
    $self->{cache_name} = "informix_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check write/read cached.

=over 8

=item B<--warning-read>

Threshold read cached warning in percent.

=item B<--critical-read>

Threshold read cached critical in percent.

=item B<--warning-write>

Threshold write cached warning in percent.

=item B<--critical-write>

Threshold write cached critical in percent.

=back

=cut
