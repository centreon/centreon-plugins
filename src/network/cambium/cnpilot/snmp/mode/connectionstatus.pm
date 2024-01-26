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

package network::cambium::cnpilot::snmp::mode::connectionstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_connection_output {
    my ($self, %options) = @_;

    return "Access point '" . $options{instance_value}->{name} . "' ";
}

sub custom_connection_output {
    my ($self, %options) = @_;

    return sprintf(
        'connection status: %s',
        $self->{result_values}->{connection_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'connection', type => 1, cb_prefix_output => 'prefix_connection_output', message_multiple => 'All connection status are ok' }
    ];

     $self->{maps_counters}->{connection} = [
        { label => 'connection-status', type => 2,
            set => {
                key_values => [ { name => 'connection_status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_connection_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-ap:s' => { name => 'filter_ap' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        cambiumAPName        => { oid => '.1.3.6.1.4.1.17713.22.1.1.1.2' },
        cambiumAPCnmConstaus => { oid => '.1.3.6.1.4.1.17713.22.1.1.1.12' }
    };

    # Point at the begining of the table 
    my $oid_cambiumAccessPointEntry = '.1.3.6.1.4.1.17713.22.1.1.1';

    my $connectionstatus_result = $options{snmp}->get_table(
        oid => $oid_cambiumAccessPointEntry,
        nothing_quit => 1
    );

    $self->{connection} = {};
    foreach my $oid (keys %{$connectionstatus_result}) {
        next if ($oid !~ /^$mapping->{cambiumAPName}->{oid}\.(.*)$/);
        # Catch instance in table
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $connectionstatus_result, instance => $instance);

        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $result->{cambiumAPName} !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{cambiumAPName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{connection}->{$instance} = {
            name => $result->{cambiumAPName},
            connection_status => $result->{cambiumAPCnmConstaus}
        };

    }

    if (scalar(keys %{$self->{connection}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP matching with filter found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Connection status.

=over 8

=item B<--filter-ap>

Filter on one or several AP.

=item B<--warning-connection-status>

Define the conditions to match for the status to be WARNING.
Can used special variables like: %{status}, %{name}

=item B<--critical-connection-status>

Define the conditions to match for the status to be CRITICAL.
Can used special variables like: %{status}, %{name}

=back

=cut
