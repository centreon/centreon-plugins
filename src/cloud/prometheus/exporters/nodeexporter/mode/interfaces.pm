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

package cloud::prometheus::exporters::nodeexporter::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(is_not_empty);
use centreon::plugins::constants qw(:counters :values);

sub custom_interface_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "operational status: %s [admin: %s]",
        $self->{result_values}->{opstatus},
        $self->{result_values}->{admstatus}
    );
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "interface '%s'%s ",
        $options{instance_value}->{name},
        $self->{multiple_instances} == 1 ? ' [instance: ' . $options{instance_value}->{instance} . ']' : ''
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'interfaces', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All interfaces are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'interface-status', type => COUNTER_KIND_TEXT, critical_default => '%{name} ne "lo" and %{admstatus} eq "up" and %{opstatus} ne "up"', set => {
                key_values => [ { name => 'opstatus' }, { name => 'admstatus' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_interface_status_output'),
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
        'filter-instance:s' => { name => 'filter_instance' },
        'filter-name:s'     => { name => 'filter_name' }
    });

    return $self;
}

sub get_network_info {
    my ($self, %options) = @_;

    my $interfaces = $options{custom}->query(queries => ['node_network_info']);

    my $flags;
    foreach my $interface (@$interfaces) {
        next if (defined($interface->{metric}->{adminstate})); # adminstate label only exists since node_exporter 1.6.0

        if (!defined($flags)) {
            $flags = {};
            my $results = $options{custom}->query(queries => ['node_network_flags']);
            foreach (@$results) {
                $flags->{ $_->{metric}->{instance} . $_->{metric}->{device} } = $_->{value}->[1];
            }
        }

        my $flag = $flags->{ $interface->{metric}->{instance} . $interface->{metric}->{device} };
        $interface->{metric}->{adminstate} = !defined($flag) ? 'unknown' : ($flag & 1) ? 'up' : 'down';
    }

    return $interfaces;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $interfaces = $self->get_network_info(custom => $options{custom});

    my $instances = {};
    $self->{interfaces} = {};
    foreach my $interface (@$interfaces) {
        next if (is_not_empty($self->{option_results}->{filter_instance})
            && $interface->{metric}->{instance} !~ /$self->{option_results}->{filter_instance}/);
        next if (is_not_empty($self->{option_results}->{filter_name})
            && $interface->{metric}->{device} !~ /$self->{option_results}->{filter_name}/);

        $instances->{ $interface->{metric}->{instance} } = 1;
        $self->{interfaces}->{ $interface->{metric}->{instance} . $interface->{metric}->{device} } = {
            instance => $interface->{metric}->{instance},
            name => $interface->{metric}->{device},
            opstatus => $interface->{metric}->{operstate},
            admstatus => $interface->{metric}->{adminstate}
        };
    }

    $self->{multiple_instances} = scalar(keys %$instances) > 1 ? 1 : 0;
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['instance', 'name', 'opstatus', 'admstatus']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(custom => $options{custom});
    foreach my $id (sort keys %{$self->{interfaces}}) {
        $self->{output}->add_disco_entry(
            instance  => $self->{interfaces}->{$id}->{instance},
            name      => $self->{interfaces}->{$id}->{name},
            opstatus  => $self->{interfaces}->{$id}->{opstatus},
            admstatus => $self->{interfaces}->{$id}->{admstatus}
        );
    }
}


1;

__END__

=head1 MODE

Check interfaces.
This mode also supports service discovery (C<--disco-format>, C<--disco-show>).

=over 8

=item B<--filter-name>

Filter interfaces by name.

=item B<--filter-instance>

Filter interfaces by instance.

=item B<--unknown-interface-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{opstatus}, %{admstatus}, %{name}

=item B<--warning-interface-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{opstatus}, %{admstatus}, %{name}

=item B<--critical-interface-status>

Define the conditions to match for the status to be CRITICAL (default: '%{name} ne "lo" and %{admstatus} eq "up" and %{opstatus} ne "up"').
You can use the following variables: %{opstatus}, %{admstatus}, %{name}

=back

=cut
