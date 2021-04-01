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

package storage::synology::snmp::mode::upgrade;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, warning_default => '%{upgrade} ne "unavailable"', set => {
                key_values => [
                    { name => 'model' }, { name => 'version' }, { name => 'upgrade' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "'%s': version is '%s', upgrade is '%s'",
        $self->{result_values}->{model},
        $self->{result_values}->{version},
        $self->{result_values}->{upgrade}
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_states = {
    1 => 'available', 2 => 'unavailable',
    3 => 'connecting', 4 => 'disconnected',
    5 => 'others'
};

my $mapping = {
    model   => { oid => '.1.3.6.1.4.1.6574.1.5.1' }, # modelName
    version => { oid => '.1.3.6.1.4.1.6574.1.5.3' }, # version
    upgrade => { oid => '.1.3.6.1.4.1.6574.1.5.4', map => $map_states }  # upgradeAvailable
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

}

1;

__END__

=head1 MODE

Check upgrade status

=over 8

=item B<--warning-status>

Set warning threshold for status (Default : '%{upgrade} ne "unavailable"').
Can used special variables like: %{model}, %{version}, %{upgrade}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{model}, %{version}, %{upgrade}

=back

=cut
