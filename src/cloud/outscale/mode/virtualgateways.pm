#
# Copyright 2023 Centreon (http://www.centreon.com/)
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

package cloud::outscale::mode::virtualgateways;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_vg_output {
    my ($self, %options) = @_;

    return sprintf(
        "virtual gateway '%s' ",
        $options{instance_value}->{vgName}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of virtual gateways ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'vgs', type => 1, cb_prefix_output => 'prefix_vg_output', message_multiple => 'All virtual gateways are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vgs-detected', display_ok => 0, nlabel => 'virtual_gateways.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vgs-available', display_ok => 0, nlabel => 'virtual_gateways.available.count', set => {
                key_values => [ { name => 'available' } ],
                output_template => 'available: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vgs-pending', display_ok => 0, nlabel => 'virtual_gateways.pending.count', set => {
                key_values => [ { name => 'pending' } ],
                output_template => 'pending: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vgs-deleting', display_ok => 0, nlabel => 'virtual_gateways.deleting.count', set => {
                key_values => [ { name => 'deleting' } ],
                output_template => 'deleting: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'vgs-deleted', display_ok => 0, nlabel => 'virtual_gateways.deleted.count', set => {
                key_values => [ { name => 'deleted' } ],
                output_template => 'deleted: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vgs} = [
        {
            label => 'vg-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'vgName' } ],
                output_template => 'state: %s',
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
        'filter-name:s' => { name => 'filter_name' },
        'vg-tag-name:s' => { name => 'vg_tag_name', default => 'name' }
    });

    return $self;
}

sub get_vg_name {
    my ($self, %options) = @_;

    foreach my $tag (@{$options{tags}}) {
        return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{vg_tag_name}$/i);
    }

    return $options{id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $vgs = $options{custom}->read_virtual_gateways();

    $self->{global} = { detected => 0, available => 0, pending => 0, deleting => 0, deleted => 0 };
    $self->{vgs} = {};

    foreach my $vg (@$vgs) {
        my $name = $self->get_vg_name(tags => $vg->{Tags}, id => $vg->{VirtualGatewayId});

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{vgs}->{$name} = {
            vgName => $name,
            state => lc($vg->{State})
        };

        $self->{global}->{ lc($vg->{State}) }++
            if (defined($self->{global}->{ lc($vg->{State}) }));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check virtual gateways.

=over 8

=item B<--filter-name>

Filter virtual gateways by name.

=item B<--vg-tag-name>

Virtual gateway tag to be used for the name (Default: 'name').

=item B<--unknown-vg-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{vgName}

=item B<--warning-vg-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{vgName}

=item B<--critical-vg-status>

Set critical threshold for status.
Can used special variables like: %{state}, %{vgName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'vgs-detected', 'vgs-available', 'vgs-pending',
'vgs-deleting', 'vgs-deleted'.

=back

=cut
