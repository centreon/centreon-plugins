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

package network::mikrotik::snmp::mode::firmware;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "'%s': software is '%s', firmware is '%s'",
        $self->{result_values}->{model},
        $self->{result_values}->{software_version},
        $self->{result_values}->{firmware_version}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, warning_default => '%{firmware_version} ne %{software_version}', set => {
                key_values => [
                    { name => 'model' }, { name => 'software_version' },
                    { name => 'firmware_version' }, { name => 'firmware_version_update' }
                ],
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

my $mapping = {
    model                   => { oid => '.1.3.6.1.2.1.1.1' }, # sysDescr
    software_version        => { oid => '.1.3.6.1.4.1.14988.1.1.4.4' }, # mtxrLicVersion
    firmware_version        => { oid => '.1.3.6.1.4.1.14988.1.1.7.4' }, # mtxrFirmwareVersion
    firmware_version_update => { oid => '.1.3.6.1.4.1.14988.1.1.7.7' }  # mtxrFirmwareUpgradeVersion
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    $self->{global}->{firmware_version} = 'n/a' if (!defined($self->{global}->{firmware_version}));
    $self->{global}->{firmware_version_update} = 'n/a' if (!defined($self->{global}->{firmware_version_update}));
}

1;

__END__

=head1 MODE

Check firmware status.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default : '%{firmware_version} ne %{software_version}').
Can used special variables like: %{model}, %{software_version}, %{firmware_version}, %{firmware_version_update}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{model}, %{software_version}, %{firmware_version}, %{firmware_version_update}

=back

=cut
