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

package storage::ibm::fs900::snmp::mode::fcusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_bandwidth_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => lc($self->{result_values}->{type}) . "_bandwidth", unit => 'B/s',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{bandwidth},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_bandwidth_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{bandwidth},
                                                  threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
                                                                 { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_bandwidth_output {
    my ($self, %options) = @_;
    
    my ($bandwidth, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{bandwidth});
    
    my $msg = sprintf("%s bandwidth: %s %s/s", $self->{result_values}->{type}, $bandwidth, $unit);
    return $msg;
}

sub custom_bandwidth_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_fcObject'};
    $self->{result_values}->{type} = $options{extra_options}->{type};
    $self->{result_values}->{bandwidth} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{bandwidth}} * 1024 * 1024;

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output', message_multiple => "All fibre channels read/write metrics are ok", skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'read-bandwidth', set => {
                key_values => [ { name => 'fcReadBW' }, { name => 'fcObject' } ],
                closure_custom_calc => $self->can('custom_bandwidth_calc'),
                closure_custom_calc_extra_options => { type => 'Read', bandwidth => 'fcReadBW' },
                closure_custom_output => $self->can('custom_bandwidth_output'),
                closure_custom_perfdata => $self->can('custom_bandwidth_perfdata'),
                closure_custom_threshold_check => $self->can('custom_bandwidth_threshold'),
            }
        },
        { label => 'write-bandwidth', set => {
                key_values => [ { name => 'fcWriteBW' }, { name => 'fcObject' } ],
                closure_custom_calc => $self->can('custom_bandwidth_calc'),
                closure_custom_calc_extra_options => { type => 'Write', bandwidth => 'fcWriteBW' },
                closure_custom_output => $self->can('custom_bandwidth_output'),
                closure_custom_perfdata => $self->can('custom_bandwidth_perfdata'),
                closure_custom_threshold_check => $self->can('custom_bandwidth_threshold'),
            }
        },
        { label => 'read-iops', set => {
                key_values => [ { name => 'fcReadIOPS' }, { name => 'fcObject' } ],
                output_template => 'Read IOPS: %s iops',
                perfdatas => [
                    { label => 'read_iops', value => 'fcReadIOPS', template => '%s', label_extra_instance => 1,
                      instance_use => 'fcObject', min => 0, unit => 'iops' },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'fcWriteIOPS' }, { name => 'fcObject' } ],
                output_template => 'Write IOPS: %s iops',
                perfdatas => [
                    { label => 'write_iops', value => 'fcWriteIOPS', template => '%s', label_extra_instance => 1, 
                      instance_use => 'fcObject', min => 0, unit => 'iops' },
                ],
            }
        },
        { label => 'read-queue-depth', set => {
                key_values => [ { name => 'fcReadQueueDepth' }, { name => 'fcObject' } ],
                output_template => 'Read queue depth: %s',
                perfdatas => [
                    { label => 'read_queue_depth', value => 'fcReadQueueDepth', template => '%s', label_extra_instance => 1,
                      instance_use => 'fcObject', min => 0, unit => 'iops' },
                ],
            }
        },
        { label => 'write-queue-depth', set => {
                key_values => [ { name => 'fcWriteQueueDepth' }, { name => 'fcObject' } ],
                output_template => 'Write queue depth: %s',
                perfdatas => [
                    { label => 'write_queue_depth', value => 'fcWriteQueueDepth', template => '%s', label_extra_instance => 1,
                      instance_use => 'fcObject', min => 0, unit => 'iops' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Fibre channel '" . $options{instance_value}->{fcObject} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

my $mapping = {
    fcObject => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.2' },
    fcReadBW => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.13' }, #MB/s
    fcWriteBW => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.14' }, #MB/s
    fcReadIOPS => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.16' },
    fcWriteIOPS => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.17' },
    fcReadQueueDepth => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.19' },
    fcWriteQueueDepth => { oid => '.1.3.6.1.4.1.2.6.255.1.1.2.1.1.20' },
};

my $oid_fcTableEntry = '.1.3.6.1.4.1.2.6.255.1.1.2.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(oid => $oid_fcTableEntry,
                                                nothing_quit => 1);

    $self->{global} = {};

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{fcObject}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{global}->{$result->{fcObject}} = $result;
    }
}

1;

__END__

=head1 MODE

Check fibre channels usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read-bandwidth', 'write-bandwidth', 'read-iops', 'write-iops', 'read-queue-depth', 'write-queue-depth'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-bandwidth', 'write-bandwidth', 'read-iops', 'write-iops', 'read-queue-depth', 'write-queue-depth'.

=back

=cut
