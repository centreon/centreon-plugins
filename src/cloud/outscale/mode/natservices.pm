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

package cloud::outscale::mode::natservices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_service_output {
    my ($self, %options) = @_;

    return sprintf(
        "nat service '%s' ",
        $options{instance_value}->{natName}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of nat services ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All nat services are ok' }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('detected', 'pending', 'available', 'deleting', 'deleted') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'nat-services-' . $_, display_ok => 0, nlabel => 'nat_services.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{services} = [
        {
            label => 'nat-service-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'natName' } ],
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
        'filter-id:s'   => { name => 'filter_id' },
        'filter-name:s' => { name => 'filter_name' },
        'nat-tag-name:s' => { name => 'nat_tag_name', default => 'name' }
    });

    return $self;
}

sub get_nat_name {
    my ($self, %options) = @_;

    foreach my $tag (@{$options{tags}}) {
        return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{nat_tag_name}$/i);
    }

    return $options{id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $services = $options{custom}->read_nat_services();

    $self->{global} = { detected => 0, pending => 0, available => 0, deleting => 0, deleted => 0 };
    $self->{services} = {};

    foreach (@$services) {
        my $name = $self->get_nat_name(tags => $_->{Tags}, id => $_->{NatServiceId});

        next if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $_->{NatServiceId} !~ /$self->{option_results}->{filter_id}/);
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{services}->{ $_->{NatServiceId} } = {
            natName => $name,
            state => lc($_->{State})
        };

        $self->{global}->{ lc($_->{State}) }++
            if (defined($self->{global}->{ lc($_->{State}) }));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check nat services.

=over 8

=item B<--filter-id>

Filter nat services by id.

=item B<--filter-name>

Filter nat services by name.

=item B<--nat-tag-name>

Nat service tag to be used for the name (default: 'name').

=item B<--unknown-nat-service-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{natName}

=item B<--warning-nat-service-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{natName}

=item B<--critical-nat-service-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{natName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'nat-services-detected', 'nat-services-pending', 'nat-services-available',
'nat-services-deleting', 'nat-services-deleted'.

=back

=cut
