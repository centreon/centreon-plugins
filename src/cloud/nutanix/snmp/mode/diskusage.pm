#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package cloud::nutanix::snmp::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw/trim is_excluded/;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_controllervm_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "ControllerVM '%s' ",
        $options{instance}
    );
}

sub controllervm_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking ControllerVM '%s'",
        $options{instance}
    );
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return sprintf(
        "Disk '%s' ",
        $options{instance}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "state: '%s'",
        $self->{result_values}->{state}
    );
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{crtName} = $options{new_datas}->{$self->{instance} . '_crtName'};
    $self->{result_values}->{diskId} = $options{new_datas}->{$self->{instance} . '_diskId'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_dstState'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $nlabel = 'disk.storage.space.usage.bytes';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $nlabel = 'disk.storage.space.free.bytes';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        nlabel => $nlabel,
        unit => 'B',
        value => $value_perf,
        instances => [ $self->{result_values}->{crtName}, $self->{result_values}->{diskId} ],
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value, 
        threshold => [ 
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, 
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } 
        ]
    );
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{crtName} = $options{new_datas}->{$self->{instance} . '_crtName'};
    $self->{result_values}->{diskId} = $options{new_datas}->{$self->{instance} . '_diskId'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_dstNumTotalBytes'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_dstNumFreeBytes'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'controllervm', type => 3, cb_prefix_output => 'prefix_controllervm_output', 
          cb_long_output => 'controllervm_long_output', indent_long_output => '    ', 
          message_multiple => 'All ControllerVM disks are ok', 
            group => [
                { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{disk} = [
        { label => 'status', type => 2, set => {
                key_values => [ { name => 'dstState' }, { name => 'diskId' }, { name => 'crtName' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'dstNumFreeBytes' }, { name => 'dstNumTotalBytes' }, { name => 'diskId' }, { name => 'crtName' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold')
            }
        },
        { label => 'inodes', nlabel => 'disk.storage.inodes.usage.percentage', set => {
                key_values => [ { name => 'inodes_used' } ],
                output_template => 'inodes used: %s %%',
                perfdatas => [
                    { template => '%s', unit => '%', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'avg-latency', nlabel => 'disk.average.io.latency.milliseconds', set => {
                key_values => [ { name => 'dstAverageLatency' } ],
                output_template => 'average latency: %.3f ms',
                perfdatas => [
                    { template => '%.3f', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'iops', nlabel => 'disk.operations.iops', set => {
                key_values => [ { name => 'dstNumberIops' } ],
                output_template => 'IOPs: %s',
                perfdatas => [
                    { template => '%s', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        }
        ,

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-controllervm:s' => { name => 'filter_controllervm', default => '' },
        'filter-name:s'         => { name => 'filter_name', default => '' },
        'units:s'               => { name => 'units', default => '%' },
        'free'                  => { name => 'free' }
    });

    return $self;
}

my %map_state = (1 => 'online', 2 => 'offline');

my $disk_mapping = {
    dstDiskId               => { oid => '.1.3.6.1.4.1.41263.3.1.2' },
    dstControllerVMId	    => { oid => '.1.3.6.1.4.1.41263.3.1.3' },
    dstNumTotalBytes        => { oid => '.1.3.6.1.4.1.41263.3.1.6' },
    dstNumFreeBytes         => { oid => '.1.3.6.1.4.1.41263.3.1.7' },
    dstNumTotalInodes       => { oid => '.1.3.6.1.4.1.41263.3.1.8' },
    dstNumFreeInodes        => { oid => '.1.3.6.1.4.1.41263.3.1.9' },
    dstAverageLatency       => { oid => '.1.3.6.1.4.1.41263.3.1.10' },
    dstNumberIops           => { oid => '.1.3.6.1.4.1.41263.3.1.12' },
    dstState                => { oid => '.1.3.6.1.4.1.41263.3.1.13', map => \%map_state }
};

my $controllervm_mapping = {
    crtControllerVMId       => { oid => '.1.3.6.1.4.1.41263.4.1.2' },
    crtName                 => { oid => '.1.3.6.1.4.1.41263.4.1.5' }
};

my $oid_dstEntry = '.1.3.6.1.4.1.41263.3.1';
my $oid_cstEntry = '.1.3.6.1.4.1.41263.4.1';
my $oid_cstControllerVM = '.1.3.6.1.4.1.41263.11.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{output}->option_exit(short_msg => "Need to use SNMP v2c or v3.")
        if $options{snmp}->is_snmpv1();

    $self->{controllervm} = {};
    my $controllervm_snmp_result = $options{snmp}->get_table(
        oid => $oid_cstEntry,
        nothing_quit => 1
    );

    my $controllervm_name_mapping = {};
    foreach my $oid (keys %{$controllervm_snmp_result}) {
        next if $oid !~ /^$controllervm_mapping->{crtControllerVMId}->{oid}\.(.*)$/;
        my $controllervm_instance = $1;
        my $controllervm_result = $options{snmp}->map_instance(mapping => $controllervm_mapping, results => $controllervm_snmp_result, instance => $controllervm_instance);

        $controllervm_result->{crtName} = trim($controllervm_result->{crtName}) =~ s/^"(.*)"$/$1/r;
        if (is_excluded($controllervm_result->{crtName}, $self->{option_results}->{filter_controllervm})) {
            $self->{output}->output_add(long_msg => "skipping '" . $controllervm_result->{crtName} . "': no matching filter.", debug => 1);
            next
        }

        $controllervm_name_mapping->{ $controllervm_result->{crtControllerVMId} } = $controllervm_result->{crtName};
    }

    # CTOR-2055: Also check for ControlerVM IDs in cstControllerVMId
    my $cstControllerVMId_snmp_result = $options{snmp}->get_table(
        oid => $oid_cstControllerVM
    );

    my $controllervm_name_list_mapping={};
    foreach my $cstControllerVMId (values %$cstControllerVMId_snmp_result) {
        $cstControllerVMId =~ s/^"(.*)"$/$1/;
        if (is_excluded($cstControllerVMId, $self->{option_results}->{filter_controllervm})) {
            $self->{output}->output_add(long_msg => "skipping '" . $cstControllerVMId . "': no matching filter.", debug => 1);
            next
        }

        $controllervm_name_list_mapping->{$cstControllerVMId} = 1;
    }

    my $disk_snmp_result = $options{snmp}->get_table(
        oid => $oid_dstEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %$disk_snmp_result) {
        next if $oid !~ /^$disk_mapping->{dstDiskId}->{oid}\.(.*)$/;
        my $disk_instance = $1;
        my $disk_result = $options{snmp}->map_instance(mapping => $disk_mapping, results => $disk_snmp_result, instance => $disk_instance);

        $disk_result->{dstControllerVMId} =~ s/^"(.*)"$/$1/;
        $disk_result->{dstDiskId} =~ s/^"(.*)"$/$1/;
        my $dstVM = $disk_result->{dstControllerVMId};

        my $ctrName;
        if (defined $controllervm_name_mapping->{$dstVM}) {
            $ctrName = $controllervm_name_mapping->{$dstVM}
        } elsif ($controllervm_name_list_mapping->{$dstVM}) {
            $ctrName = $dstVM;
        }
        next unless defined $ctrName;

        if (is_excluded($disk_result->{dstDiskId}, $self->{option_results}->{filter_name})) {
            $self->{output}->output_add(long_msg => "skipping '" . $disk_result->{dstDiskId} . "': no matching filter.", debug => 1);
            next
        }

        $disk_result->{dstDiskId} = trim($disk_result->{dstDiskId});

        my $inodes_used;
        $inodes_used = 100 - ($disk_result->{dstNumFreeInodes} * 100 / $disk_result->{dstNumTotalInodes}) if ($disk_result->{dstNumTotalInodes} > 0);

        $disk_result->{dstAverageLatency} /= 1000;

        $self->{controllervm}->{ $ctrName }->{disk}->{ $disk_result->{dstDiskId} } = {
            crtName => $ctrName,
            diskId => $disk_result->{dstDiskId}, 
            inodes_used => $inodes_used,
            inodes => 1111,
            %$disk_result,
        };
    }

    $self->{output}->option_exit(short_msg => "No ControllerVM found.")
        if keys %{$self->{controllervm}} <= 0;

    my $diskless_controller = 0;
    foreach my $controllervm (keys %{$self->{controllervm}}) {
        $diskless_controller++
            if keys %{$self->{controllervm}->{$controllervm}->{disk}} <= 0;
    }
    
    $self->{output}->option_exit(short_msg => "No disk found.")
        if $diskless_controller eq keys %{$self->{controllervm}};
}

1;

__END__

=head1 MODE

Check disk usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^usage$'

=item B<--filter-name>

Filter disk name (can be a regexp).

=item B<--filter-controllervm>

Filter controller VM name (can be a regexp).
Depending on the Nutanix configuration and version this may refer to the controller VM's name or ID.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{crtName}, %{diskId}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{crtName}, %{diskId}

=item B<--warning-avg-latency>

Threshold in milliseconds.

=item B<--critical-avg-latency>

Threshold in milliseconds.

=item B<--warning-inodes>

Threshold in percentage.

=item B<--critical-inodes>

Threshold in percentage.

=item B<--warning-iops>

Threshold in iops.

=item B<--critical-iops>

Threshold in iops.

=item B<--warning-usage>

Threshold.

=item B<--critical-usage>

Threshold.

=item B<--units>

Units of thresholds (default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
