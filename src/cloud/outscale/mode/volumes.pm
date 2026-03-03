#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package cloud::outscale::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:values :counters);

sub volume_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking volume '%s'",
        $options{instance_value}->{id}
    );
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return sprintf(
        "volume '%s' ",
        $options{instance_value}->{id}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of volumes ';
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "virtual machine '" . $options{instance_value}->{vmName} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'volumes', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_volume_output', cb_long_output => 'volume_long_output', indent_long_output => '    ', message_multiple => 'All volumes are ok',
            group => [
                { name => 'status', type => COUNTER_MULTIPLE_INSTANCE },
                { name => 'vms', display_long => COUNTER_MULTIPLE_SUBINSTANCE, cb_prefix_output => 'prefix_vm_output', message_multiple => 'all virtual machines are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('detected', 'creating', 'available', 'in-use', 'updating', 'deleting', 'error') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'volumes-' . $_, display_ok => 0, nlabel => 'volumes.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{status} = [
        {
            label => 'volume-status',
            type => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'state' }, { name => 'volumeId' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{vms} = [
        {
            label => 'vm-status',
            type => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'state' }, { name => 'vmName' } ],
                output_template => 'volume state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-id:s'   => { name => 'filter_id' },
        'vm-tag-name:s' => { name => 'vm_tag_name', default => 'name' }
    });

    return $self;
}

sub get_vm_name {
    my ($self, %options) = @_;

    foreach my $vm (@{$options{vms}}) {
        next if ($vm->{VmId} ne $options{vm_id});

        foreach my $tag (@{$vm->{Tags}}) {
            return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{vm_tag_name}$/i);
        }
    }

    return $options{vm_id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $volumes = $options{custom}->read_volumes();
    my $vms = $options{custom}->read_vms();

    $self->{global} = { detected => 0, creating => 0, available => 0, 'in-use' => 0, updating => 0, deleting => 0, error => 0 };
    $self->{volumes} = {};

    foreach my $volume (@$volumes) {
        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $volume->{VolumeId} !~ /$self->{option_results}->{filter_id}/);

        $self->{volumes}->{ $volume->{VolumeId} } = {
            id => $volume->{VolumeId},
            status => {
                volumeId => $volume->{VolumeId},
                state => lc($volume->{State})
            },
            vms => {}
        };

        $self->{global}->{ lc($volume->{State}) }++
            if (defined($self->{global}->{ lc($volume->{State}) }));
        $self->{global}->{detected}++;

        foreach (@{$volume->{LinkedVolumes}}) {
            my $name = $self->get_vm_name(vms => $vms, vm_id => $_->{VmId});

            $self->{volumes}->{ $volume->{VolumeId} }->{vms}->{ $_->{VmId} } = {
                vmName => $name,
                state => lc($_->{State})
            };
        }
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-id>

Filter volumes by id.

=item B<--vm-tag-name>

Virtual machine tags to used for the name (default: 'name').

=item B<--unknown-volume-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{volumeId}

=item B<--warning-volume-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{volumeId}

=item B<--critical-volume-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{volumeId}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'volumes-detected', 'volumes-creating', 'volumes-available', 
'volumes-in-use', 'volumes-updating', 'volumes-deleting', 'volumes-error'.

=back

=cut
