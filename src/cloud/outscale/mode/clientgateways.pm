#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package cloud::outscale::mode::clientgateways;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_cg_output {
    my ($self, %options) = @_;

    return sprintf(
        "client gateway '%s' ",
        $options{instance_value}->{cgName}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of client gateways ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'cgs', type => 1, cb_prefix_output => 'prefix_cg_output', message_multiple => 'All client gateways are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'cgs-detected', display_ok => 0, nlabel => 'client_gateways.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'cgs-available', display_ok => 0, nlabel => 'client_gateways.available.count', set => {
                key_values => [ { name => 'available' } ],
                output_template => 'available: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'cgs-pending', display_ok => 0, nlabel => 'client_gateways.pending.count', set => {
                key_values => [ { name => 'pending' } ],
                output_template => 'pending: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'cgs-deleting', display_ok => 0, nlabel => 'client_gateways.deleting.count', set => {
                key_values => [ { name => 'deleting' } ],
                output_template => 'deleting: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'cgs-deleted', display_ok => 0, nlabel => 'client_gateways.deleted.count', set => {
                key_values => [ { name => 'deleted' } ],
                output_template => 'deleted: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cgs} = [
        {
            label => 'cg-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'cgName' } ],
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
        'cg-tag-name:s' => { name => 'cg_tag_name', default => 'name' }
    });

    return $self;
}

sub get_cg_name {
    my ($self, %options) = @_;

    foreach my $tag (@{$options{tags}}) {
        return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{cg_tag_name}$/i);
    }

    return $options{id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $cgs = $options{custom}->read_client_gateways();

    $self->{global} = { detected => 0, available => 0, pending => 0, deleting => 0, deleted => 0 };
    $self->{cgs} = {};

    foreach my $cg (@$cgs) {
        my $name = $self->get_cg_name(tags => $cg->{Tags}, id => $cg->{ClientGatewayId});

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{cgs}->{$name} = {
            cgName => $name,
            state => lc($cg->{State})
        };

        $self->{global}->{ lc($cg->{State}) }++
            if (defined($self->{global}->{ lc($cg->{State}) }));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check client gateways.

=over 8

=item B<--filter-name>

Filter client gateways by name.

=item B<--cg-tag-name>

Client gateway tags to be used for the name (default: 'name').

=item B<--unknown-cg-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{cgName}

=item B<--warning-cg-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{cgName}

=item B<--critical-cg-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{cgName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cgs-detected', 'cgs-available', 'cgs-pending',
'cgs-deleting', 'cgs-deleted'.

=back

=cut
