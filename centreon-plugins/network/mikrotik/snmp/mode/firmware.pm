#
# Copyright 2020 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [
                    { name => 'model' }, { name => 'software_version' },
                    { name => 'firmware_version' }, { name => 'firmware_version_update' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;

    return  'software is \'' . $self->{result_values}->{software_version} . '\', firmware is \'' . $self->{result_values}->{firmware_version} . '\''
}

sub prefix_output {
    my ($self, %options) = @_;

    return '\'' . $options{instance_value}->{model} . '\' : ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '%{firmware_version} ne %{software_version}' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $mapping = {
    sysDescr                   => { oid => '.1.3.6.1.2.1.1.1' },
    mtxrLicVersion             => { oid => '.1.3.6.1.4.1.14988.1.1.4.4' },
    mtxrFirmwareVersion        => { oid => '.1.3.6.1.4.1.14988.1.1.7.4' },
    mtxrFirmwareUpgradeVersion => { oid => '.1.3.6.1.4.1.14988.1.1.7.7' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => 0);

    $self->{global}->{0}->{model} = $result->{sysDescr};
    $self->{global}->{0}->{software_version} = $result->{mtxrLicVersion};
    $self->{global}->{0}->{firmware_version} = $result->{mtxrFirmwareVersion};
    $self->{global}->{0}->{firmware_version_update} = $result->{mtxrFirmwareUpgradeVersion};

}

1;

__END__

=head1 MODE

Check firmware status

=over 8

=item B<--warning-status>

Set warning threshold for status (Default : '%{firmware_version} ne %{software_version}').
Can used special variables like: %{model}, %{software_version}, %{firmware_version}, %{firmware_version_update}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{model}, %{software_version}, %{firmware_version}, %{firmware_version_update}

=back

=cut
