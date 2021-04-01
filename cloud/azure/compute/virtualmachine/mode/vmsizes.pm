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

package cloud::azure::compute::virtualmachine::mode::vmsizes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %vm_types = (
    'general' => ['Standard_B1s', 'Standard_B1ms', 'Standard_B2s', 'Standard_B2ms', 'Standard_B4ms', 'Standard_B8ms',
        'Standard_D2s_v3', 'Standard_D4s_v3', 'Standard_D8s_v3', 'Standard_D16s_v3', 'Standard_D32s_v3',
        'Standard_D64s_v3', 'Standard_D2_v3', 'Standard_D4_v3', 'Standard_D8_v3', 'Standard_D16_v3', 'Standard_D32_v3',
        'Standard_D64_v3', 'Standard_DS1_v2', 'Standard_DS2_v2', 'Standard_DS3_v2', 'Standard_DS4_v2', 'Standard_DS5_v2',
        'Standard_D1_v2', 'Standard_D2_v2', 'Standard_D3_v2', 'Standard_D4_v2', 'Standard_D5_v2', 'Standard_A1_v2',
        'Standard_A2_v2', 'Standard_A4_v2', 'Standard_A8_v2', 'Standard_A2m_v2', 'Standard_A4m_v2', 'Standard_A8m_v2'],
    'compute' => ['Standard_F2s_v2', 'Standard_F4s_v2', 'Standard_F8s_v2', 'Standard_F16s_v2', 'Standard_F32s_v2',
        'Standard_F64s_v2', 'Standard_F72s_v2', 'Standard_F1s', 'Standard_F2s', 'Standard_F4s', 'Standard_F8s',
        'Standard_F16s', 'Standard_F1', 'Standard_F2', 'Standard_F4', 'Standard_F8', 'Standard_F16'],
    'memory' => ['Standard_E2s_v3', 'Standard_E4s_v3', 'Standard_E8s_v3', 'Standard_E16s_v3', 'Standard_E32s_v3',
        'Standard_E64s_v3', 'Standard_E64is_v3', 'Standard_E2_v3', 'Standard_E4_v3', 'Standard_E8_v3', 'Standard_E16_v3',
        'Standard_E32_v3', 'Standard_E64_v3', 'Standard_E64i_v3', 'Standard_M8ms3', 'Standard_M16ms', 'Standard_M32ts',
        'Standard_M32ls', 'Standard_M32ms', 'Standard_M64s', 'Standard_M64ls', 'Standard_M64ms', 'Standard_M128s',
        'Standard_M128ms', 'Standard_M64', 'Standard_M64m', 'Standard_M128', 'Standard_M128m', 'Standard_GS1',
        'Standard_GS2', 'Standard_GS3', 'Standard_GS4', 'Standard_GS5', 'Standard_G1', 'Standard_G2', 'Standard_G3',
        'Standard_G4', 'Standard_G5', 'Standard_DS11_v2', 'Standard_DS12_v2', 'Standard_DS13_v2', 'Standard_DS14_v2',
        'Standard_DS15_v2', 'Standard_D11_v2', 'Standard_D12_v2', 'Standard_D13_v2', 'Standard_D14_v2', 'Standard_D15_v2'],
    'storage' => ['Standard_L4s', 'Standard_L8s', 'Standard_L16s', 'Standard_L32s'],
    'gpu' => ['Standard_NC6', 'Standard_NC12', 'Standard_NC24', 'Standard_NC24r', 'Standard_NC6s_v2', 'Standard_NC12s_v2',
        'Standard_NC24s_v2', 'Standard_NC24rs_v2', 'Standard_NC6s_v3', 'Standard_NC12s_v3', 'Standard_NC24s_v3',
        'Standard_NC24rs_v3', 'Standard_ND6s', 'Standard_ND12s', 'Standard_ND24s', 'Standard_ND24rs', 'Standard_NV6',
        'Standard_NV12', 'Standard_NV24'],
    'high_performance' => ['Standard_H8', 'Standard_H16', 'Standard_H8m', 'Standard_H16m', 'Standard_H16r',
        'Standard_H16mr'],
);

sub prefix_general_output {
    my ($self, %options) = @_;

    return "Virtual machine type 'General purpose' resource sizes count ";
}

sub prefix_compute_output {
    my ($self, %options) = @_;

    return "Virtual machine type 'Compute optimized' resource sizes count ";
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Virtual machine type 'Memory optimized' resource sizes count ";
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Virtual machine type 'Storage optimized' resource sizes count ";
}

sub prefix_gpu_output {
    my ($self, %options) = @_;

    return "Virtual machine type 'GPU' resource sizes count ";
}

sub prefix_high_performance_output {
    my ($self, %options) = @_;

    return "Virtual machine type 'High performance compute' resource sizes count ";
}

sub set_counters {
    my ($self, %options) = @_;

    foreach my $type (keys %vm_types) {
        my $counter = { name => $type, type => 0, cb_prefix_output => 'prefix_' . $type . '_output', skipped_code => { -10 => 1 } };

        push @{$self->{maps_counters_type}}, $counter;
        
        $self->{maps_counters}->{$type} = [];
        
        foreach my $size (@{$vm_types{$type}}) {
            my $perf = lc($size);
            my $label = lc($size);
            $label =~ s/_/-/g;
            my $entry = { label => $label, set => {
                            key_values => [ { name => $size }  ],
                            output_template => $size . ": %s",
                            perfdatas => [
                            { label => $perf, value => $size , template => '%d', min => 0 },
                            ],
                        }
                    };
            push @{$self->{maps_counters}->{$type}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "filter-type:s"         => { name => 'filter_type' },
                                    "filter-size:s"         => { name => 'filter_size' },
                                    "running"               => { name => 'running' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    foreach my $type (keys %vm_types) {
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping type '%s'", $type), debug => 1);
            $self->{maps_counters}->{$type} = undef;
        } else {
            foreach my $size (@{$vm_types{$type}}) {
                if (defined($self->{option_results}->{filter_size}) && $self->{option_results}->{filter_size} ne '' &&
                    $size !~ /$self->{option_results}->{filter_size}/) {
                    next;
                }
                $self->{$type}->{$size} = 0;
            }
        }
    }

    my $vms = $options{custom}->azure_list_vms(resource_group => $self->{option_results}->{resource_group}, show_details => 1);
    
    foreach my $vm (@{$vms}) {
        next if (defined($self->{option_results}->{running}) && defined($vm->{powerState}) && $vm->{powerState} !~ /running/);
        if (defined($self->{option_results}->{filter_size}) && $self->{option_results}->{filter_size} ne '' &&
            (defined($vm->{hardwareProfile}->{vmSize}) && $vm->{hardwareProfile}->{vmSize} !~ /$self->{option_results}->{filter_size}/ ||
            defined($vm->{properties}->{hardwareProfile}->{vmSize}) && $vm->{properties}->{hardwareProfile}->{vmSize} !~ /$self->{option_results}->{filter_size}/)) {
            $self->{output}->output_add(long_msg => sprintf("skipping size '%s'", $vm->{hardwareProfile}->{vmSize}), debug => 1) if (defined($vm->{hardwareProfile}->{vmSize}));
            $self->{output}->output_add(long_msg => sprintf("skipping size '%s'", $vm->{properties}->{hardwareProfile}->{vmSize}), debug => 1) if (defined($vm->{properties}->{hardwareProfile}->{vmSize}));
            next;
        }
        foreach my $type (keys %vm_types) {
            next if (!defined($self->{maps_counters}->{$type}));
            $self->{$type}->{$vm->{hardwareProfile}->{vmSize}}++ if (defined($vm->{hardwareProfile}->{vmSize}) && map(/$vm->{hardwareProfile}->{vmSize}/, @{$vm_types{$type}}));
            $self->{$type}->{$vm->{properties}->{hardwareProfile}->{vmSize}}++ if (defined($vm->{properties}->{hardwareProfile}->{vmSize}) && map(/$vm->{properties}->{hardwareProfile}->{vmSize}/, @{$vm_types{$type}}));
        }
    }
    
    if (scalar(keys %{$self->{general}}) <= 0 && scalar(keys %{$self->{compute}}) <= 0 && scalar(keys %{$self->{memory}}) <= 0 &&
        scalar(keys %{$self->{storage}}) <= 0 && scalar(keys %{$self->{gpu}}) <= 0 && scalar(keys %{$self->{high_performance}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No result matched with applied filters.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

List virtual machine resources sizes.

=over 8

=item B<--resource-group>

Set resource group (Optional).

=item B<--filter-type>

Filter by virtual machine type (regexp)
(Can be: 'general', 'compute', 'memory', 'storage', 'gpu', 'high_performance')

=item B<--filter-size>

Filter by virtual machine size (regexp)

=item B<--warning-*>

Threshold warning.
Can be: 'standard-b1s', 'standard-b1ms', 'standard-b2s', 'standard-b2ms', 'standard-b4ms', 'standard-b8ms',
'standard-d2s-v3', 'standard-d4s-v3', 'standard-d8s-v3', 'standard-d16s-v3', 'standard-d32s-v3',
'standard-d64s-v3', 'standard-d2-v3', 'standard-d4-v3', 'standard-d8-v3', 'standard-d16-v3', 'standard-d32-v3',
'standard-d64-v3', 'standard-ds1-v2', 'standard-ds2-v2', 'standard-ds3-v2', 'standard-ds4-v2', 'standard-ds5-v2',
'standard-d1-v2', 'standard-d2-v2', 'standard-d3-v2', 'standard-d4-v2', 'standard-d5-v2', 'standard-a1-v2',
'standard-a2-v2', 'standard-a4-v2', 'standard-a8-v2', 'standard-a2m-v2', 'standard-a4m-v2', 'standard-a8m-v2',
'standard-f2s-v2', 'standard-f4s-v2', 'standard-f8s-v2', 'standard-f16s-v2', 'standard-f32s-v2',
'standard-f64s-v2', 'standard-f72s-v2', 'standard-f1s', 'standard-f2s', 'standard-f4s', 'standard-f8s',
'standard-f16s', 'standard-f1', 'standard-f2', 'standard-f4', 'standard-f8', 'standard-f16',
'standard-e2s-v3', 'standard-e4s-v3', 'standard-e8s-v3', 'standard-e16s-v3', 'standard-e32s-v3',
'standard-e64s-v3', 'standard-e64is-v3', 'standard-e2-v3', 'standard-e4-v3', 'standard-e8-v3', 'standard-e16-v3',
'standard-e32-v3', 'standard-e64-v3', 'standard-e64i-v3', 'standard-m8ms3', 'standard-m16ms', 'standard-m32ts',
'standard-m32ls', 'standard-m32ms', 'standard-m64s', 'standard-m64ls', 'standard-m64ms', 'standard-m128s',
'standard-m128ms', 'standard-m64', 'standard-m64m', 'standard-m128', 'standard-m128m', 'standard-gs1',
'standard-gs2', 'standard-gs3', 'standard-gs4', 'standard-gs5', 'standard-g1', 'standard-g2', 'standard-g3',
'standard-g4', 'standard-g5', 'standard-ds11-v2', 'standard-ds12-v2', 'standard-ds13-v2', 'standard-ds14-v2',
'standard-ds15-v2', 'standard-d11-v2', 'standard-d12-v2', 'standard-d13-v2', 'standard-d14-v2', 'standard-d15-v2',
'standard-l4s', 'standard-l8s', 'standard-l16s', 'standard-l32s', 'standard-nc6', 'standard-nc12', 'standard-nc24',
'standard-nc24r', 'standard-nc6s-v2', 'standard-nc12s-v2', 'standard-nc24s-v2', 'standard-nc24rs-v2', 'standard-nc6s-v3',
'standard-nc12s-v3', 'standard-nc24s-v3', 'standard-nc24rs-v3', 'standard-nd6s', 'standard-nd12s', 'standard-nd24s',
'standard-nd24rs', 'standard-nv6', 'standard-nv12', 'standard-nv24','standard-h8', 'standard-h16', 'standard-h8m',
'standard-h16m', 'standard-h16r', 'standard-h16mr'.

=item B<--critical-*>

Threshold critical.
Can be: 'standard-b1s', 'standard-b1ms', 'standard-b2s', 'standard-b2ms', 'standard-b4ms', 'standard-b8ms',
'standard-d2s-v3', 'standard-d4s-v3', 'standard-d8s-v3', 'standard-d16s-v3', 'standard-d32s-v3',
'standard-d64s-v3', 'standard-d2-v3', 'standard-d4-v3', 'standard-d8-v3', 'standard-d16-v3', 'standard-d32-v3',
'standard-d64-v3', 'standard-ds1-v2', 'standard-ds2-v2', 'standard-ds3-v2', 'standard-ds4-v2', 'standard-ds5-v2',
'standard-d1-v2', 'standard-d2-v2', 'standard-d3-v2', 'standard-d4-v2', 'standard-d5-v2', 'standard-a1-v2',
'standard-a2-v2', 'standard-a4-v2', 'standard-a8-v2', 'standard-a2m-v2', 'standard-a4m-v2', 'standard-a8m-v2',
'standard-f2s-v2', 'standard-f4s-v2', 'standard-f8s-v2', 'standard-f16s-v2', 'standard-f32s-v2',
'standard-f64s-v2', 'standard-f72s-v2', 'standard-f1s', 'standard-f2s', 'standard-f4s', 'standard-f8s',
'standard-f16s', 'standard-f1', 'standard-f2', 'standard-f4', 'standard-f8', 'standard-f16',
'standard-e2s-v3', 'standard-e4s-v3', 'standard-e8s-v3', 'standard-e16s-v3', 'standard-e32s-v3',
'standard-e64s-v3', 'standard-e64is-v3', 'standard-e2-v3', 'standard-e4-v3', 'standard-e8-v3', 'standard-e16-v3',
'standard-e32-v3', 'standard-e64-v3', 'standard-e64i-v3', 'standard-m8ms3', 'standard-m16ms', 'standard-m32ts',
'standard-m32ls', 'standard-m32ms', 'standard-m64s', 'standard-m64ls', 'standard-m64ms', 'standard-m128s',
'standard-m128ms', 'standard-m64', 'standard-m64m', 'standard-m128', 'standard-m128m', 'standard-gs1',
'standard-gs2', 'standard-gs3', 'standard-gs4', 'standard-gs5', 'standard-g1', 'standard-g2', 'standard-g3',
'standard-g4', 'standard-g5', 'standard-ds11-v2', 'standard-ds12-v2', 'standard-ds13-v2', 'standard-ds14-v2',
'standard-ds15-v2', 'standard-d11-v2', 'standard-d12-v2', 'standard-d13-v2', 'standard-d14-v2', 'standard-d15-v2',
'standard-l4s', 'standard-l8s', 'standard-l16s', 'standard-l32s', 'standard-nc6', 'standard-nc12', 'standard-nc24',
'standard-nc24r', 'standard-nc6s-v2', 'standard-nc12s-v2', 'standard-nc24s-v2', 'standard-nc24rs-v2', 'standard-nc6s-v3',
'standard-nc12s-v3', 'standard-nc24s-v3', 'standard-nc24rs-v3', 'standard-nd6s', 'standard-nd12s', 'standard-nd24s',
'standard-nd24rs', 'standard-nv6', 'standard-nv12', 'standard-nv24','standard-h8', 'standard-h16', 'standard-h8m',
'standard-h16m', 'standard-h16r', 'standard-h16mr'.

=item B<--running>

Only check running virtual machines (only with az CLI).

=back

=cut
