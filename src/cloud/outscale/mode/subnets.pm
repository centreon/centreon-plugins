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

package cloud::outscale::mode::subnets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_subnet_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub subnet_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking subnet '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_subnet_output {
    my ($self, %options) = @_;

    return sprintf(
        "subnet '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of subnets ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'subnets', type => 3, cb_prefix_output => 'prefix_subnet_output', cb_long_output => 'subnet_long_output', indent_long_output => '    ', message_multiple => 'All subnets are ok',
            group => [
                { name => 'status', type => 0 },
                { name => 'metrics', type => 0 }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('detected', 'pending', 'available', 'deleted') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'subnets-' . $_, display_ok => 0, nlabel => 'subnets.' . $_ . '.count', set => {
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
            label => 'subnet-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'subnetName' } ],
                output_template => 'state: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{metrics} = [
        { label => 'subnet-addresses-usage-free', nlabel => 'subnet.addresses.free.count', set => {
                key_values => [ { name => 'freeAddresses' }, { name => 'subnetName'} ],
                output_template => 'number of addresses free: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'subnetName' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'subnet-tag-name:s' => { name => 'subnet_tag_name', default => 'name' }
    });

    return $self;
}

sub get_subnet_name {
    my ($self, %options) = @_;

    foreach my $tag (@{$options{tags}}) {
        return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{subnet_tag_name}$/i);
    }

    return $options{id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $subnets = $options{custom}->read_subnets();

    $self->{global} = { available => 0, pending => 0, deleted => 0 };
    $self->{subnets} = {};
    foreach (@$subnets) {
        my $name = $self->get_subnet_name(tags => $_->{Tags}, id => $_->{SubnetId});

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{subnets}->{ $_->{SubnetId} } = {
            name => $name,
            status => {
                subnetName => $name,
                state => lc($_->{State})
            },
            metrics => {
                subnetName => $name,
                freeAddresses => $_->{AvailableIpsCount}
            }
        };

        $self->{global}->{ lc($_->{State}) }++
            if (defined($self->{global}->{ lc($_->{State}) }));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check subnets.

=over 8

=item B<--filter-name>

Filter subnets by name.

=item B<--subnet-tag-name>

Subnet tags to be used for the name (default: 'name').

=item B<--unknown-subnet-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{subnetName}

=item B<--warning-subnet-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{subnetName}

=item B<--critical-subnet-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{subnetName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'subnets-detected', 'subnets-available', 'subnets-pending',
'subnets-deleted'.

=back

=cut
