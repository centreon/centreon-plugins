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

package storage::ibm::fs900::snmp::mode::arraysstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s'", $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_arrayStatus'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output', message_multiple => "All arrays metrics are ok", message_separator => ' - ' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'arrayStatus' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'vdisk-count', set => {
                key_values => [ { name => 'arrayVDiskCount' }, { name => 'arrayId' } ],
                output_template => 'VDisk count: %s',
                perfdatas => [
                    { label => 'vdisk_count', value => 'arrayVDiskCount', template => '%s', label_extra_instance => 1,
                      instance_use => 'arrayId', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Array '" . $options{instance_value}->{arrayId} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "warning-status:s"  => { name => 'warning_status', default => '' },
                                    "critical-status:s" => { name => 'critical_status', default => '%{status} =~ /degraded/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $mapping = {
    arrayId => { oid => '.1.3.6.1.4.1.2.6.255.1.1.1.52.1.2' },
    arrayStatus => { oid => '.1.3.6.1.4.1.2.6.255.1.1.1.52.1.3' },
    arrayVDiskCount => { oid => '.1.3.6.1.4.1.2.6.255.1.1.1.52.1.9' },
};

my $oid_arrayIndex = '.1.3.6.1.4.1.2.6.255.1.1.1.52.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(oid => $oid_arrayIndex,
                                                nothing_quit => 1);

    $self->{global} = {};

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{arrayId}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{global}->{$result->{arrayId}} = $result;
    }
}

1;

__END__

=head1 MODE

Check arrays status.

=over 8

=item B<--warning-status>

Set warning threshold for status.
'status' can be: 'online', 'offline', 'excluded', 'degraded'.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /degraded/i').
'status' can be: 'online', 'offline', 'excluded', 'degraded'.

=item B<--warning-vdisk-count>

Threshold warning for VDisks count.

=item B<--critical-vdisk-count>

Threshold critical for VDisks count.

=back

=cut
