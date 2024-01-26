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

package cloud::outscale::mode::nets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_net_output {
    my ($self, %options) = @_;

    return sprintf(
        "net '%s' ",
        $options{instance_value}->{netName}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of nets ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'nets', type => 1, cb_prefix_output => 'prefix_net_output', message_multiple => 'All nets are ok' }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('detected', 'pending', 'available', 'deleted') {
        push @{$self->{maps_counters}->{global}}, {
            label => 'nets-' . $_, display_ok => 0, nlabel => 'nets.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{nets} = [
        {
            label => 'net-status',
            type => 2,
            set => {
                key_values => [ { name => 'state' }, { name => 'netName' } ],
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
        'filter-name:s'  => { name => 'filter_name' },
        'net-tag-name:s' => { name => 'net_tag_name', default => 'name' }
    });

    return $self;
}

sub get_net_name {
    my ($self, %options) = @_;

    foreach my $tag (@{$options{tags}}) {
        return $tag->{Value} if ($tag->{Key} =~ /^$self->{option_results}->{net_tag_name}$/i);
    }

    return $options{id};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $nets = $options{custom}->read_nets();

    $self->{global} = { detected => 0, available => 0, pending => 0, deleted => 0 };
    $self->{nets} = {};

    foreach my $net (@$nets) {
        my $name = $self->get_net_name(tags => $net->{Tags}, id => $net->{NetId});

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/);

        $self->{nets}->{$name} = {
            netName => $name,
            state => lc($net->{State})
        };

        $self->{global}->{ lc($net->{State}) }++
            if (defined($self->{global}->{ lc($net->{State}) }));
        $self->{global}->{detected}++;
    }
}

1;

__END__

=head1 MODE

Check nets.

=over 8

=item B<--filter-name>

Filter nets by name.

=item B<--net-tag-name>

Nets tag to be used for the name (default: 'name').

=item B<--unknown-net-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{netName}

=item B<--warning-net-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{netName}

=item B<--critical-net-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{netName}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'nets-detected', 'nets-available', 'nets-pending',
'nets-deleted'.

=back

=cut
