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

package storage::qnap::snmp::mode::upgrade;

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
        { label => 'status', type => 2, warning_default => '%{upgrade} eq "available"', set => {
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
        "upgrade is %s [model: %s] [version: %s]",
        $self->{result_values}->{upgrade},
        $self->{result_values}->{model},
        $self->{result_values}->{version}
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

my $mapping = {

    qts => {
        model   => { oid => '.1.3.6.1.4.1.55062.1.12.3' }, # systemModel
        version => { oid => '.1.3.6.1.4.1.55062.1.12.6' }, # firmwareVersion
        upgrade => { oid => '.1.3.6.1.4.1.55062.1.12.7' }  # firmwareUpgradeAvailable
    },
    quts => {
        model   => { oid => '.1.3.6.1.4.1.55062.2.12.3' }, # systemModel
        version => { oid => '.1.3.6.1.4.1.55062.2.12.6' }, # firmwareVersion
        upgrade => { oid => '.1.3.6.1.4.1.55062.2.12.7' }  # firmwareUpgradeAvailable
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            map(
                $_->{oid} . '.0',
                values(%{$mapping->{qts}}),
                values(%{$mapping->{quts}})
            )
        ],
        nothing_quit => 1
    );

    my $type = defined($snmp_result->{ $mapping->{quts}->{model}->{oid} . '.0' }) ? 'quts' : 'qts';

    $snmp_result->{$mapping->{$type}->{version}->{oid} . '.0'} =~ s/\r*\n*$//
        if defined($snmp_result->{$mapping->{$type}->{version}->{oid} . '.0'});

    $self->{global} = $options{snmp}->map_instance(mapping => $mapping->{$type}, results => $snmp_result, instance => 0);
    $self->{global}->{upgrade} = $self->{global}->{upgrade} ? 'available' : 'unavailable';
}

1;

__END__

=head1 MODE

Check upgrade status (only works with QTS or QuTS hero OS).

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default : '%{upgrade} eq "available"').
You can use the following variables: %{model}, %{version}, %{upgrade}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{model}, %{version}, %{upgrade}

=back

=cut
