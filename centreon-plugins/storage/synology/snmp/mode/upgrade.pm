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

package storage::synology::snmp::mode::upgrade;

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
                    { name => 'model' }, { name => 'version' }, { name => 'upgrade' }
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

    return 'version is \'' . $self->{result_values}->{version} . '\', upgrade is \'' . $self->{result_values}->{upgrade} . '\''
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
        'warning-status:s'  => { name => 'warning_status', default => '%{upgrade} ne "unavailable"' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %states = (
    1 => 'available',
    2 => 'unavailable',
    3 => 'connecting',
    4 => 'disconnected',
    5 => 'others'
);

my $mapping = {
    modelName        => { oid => '.1.3.6.1.4.1.6574.1.5.1' },
    version          => { oid => '.1.3.6.1.4.1.6574.1.5.3' },
    upgradeAvailable => { oid => '.1.3.6.1.4.1.6574.1.5.4' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => 0);

    $self->{global}->{0}->{model} = $result->{modelName};
    $self->{global}->{0}->{version} = $result->{version};
    $self->{global}->{0}->{upgrade} = $states{$result->{upgradeAvailable}};

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
