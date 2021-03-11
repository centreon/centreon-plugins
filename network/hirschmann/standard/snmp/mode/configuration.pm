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

package network::hirschmann::standard::snmp::mode::configuration;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "configuration status is '%s'",
        $self->{result_values}->{config_status}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
         { label => 'status', type => 2, warning_default => '%{config_status} =~ /notInSync|outOfSync/', set => {
                key_values => [ { name => 'config_status' } ],
                closure_custom_output => $self->can('custom_status_output'),
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
    });

    return $self;
}

my $map_config_status = {
    1 => 'ok', 2 => 'notInSync'
};
my $map_nvm_state = {
    1 => 'ok', 2 => 'outOfSync', 3 => 'busy'
};

my $mapping = {
    hios => {
        config_status => { oid => '.1.3.6.1.4.1.248.11.21.1.3.1', map => $map_config_status } # hm2FMNvmState
    },
    classic => {
        config_status => { oid => '.1.3.6.1.4.1.248.14.2.4.12', map => $map_config_status } # hmConfigurationStatus
    }
};

sub check_config {
    my ($self, %options) = @_;

    my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => 0);
    return 0 if (!defined($result->{config_status}));

    $self->{global} = $result;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{hios}}), values(%{$mapping->{classic}})),  ],
        nothing_quit => 1
    );
    if ($self->check_config(snmp => $options{snmp}, type => 'hios', snmp_result => $snmp_result) == 0) {
        $self->check_config(snmp => $options{snmp}, type => 'classic', snmp_result => $snmp_result);
    }
}

1;

__END__

=head1 MODE

Check configuration status.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default : '%{config_status} =~ /notInSync|outOfSync/').
Can used special variables like: %{config_status}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{config_status}

=back

=cut
