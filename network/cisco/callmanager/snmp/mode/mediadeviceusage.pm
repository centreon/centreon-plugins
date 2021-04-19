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

package network::cisco::callmanager::snmp::mode::mediadeviceusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_md_output {
    my ($self, %options) = @_;

    return "Media device '" . $options{instance_value}->{display} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Total ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'md', type => 1, cb_prefix_output => 'prefix_md_output', message_multiple => 'All media devices are ok' }
    ];
    
    $self->{maps_counters}->{md} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /^registered/', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
    
    my @map = (
        ['total-registered', 'registered: %s', 'registered', 'media_devices.registered.count'],
        ['total-unregistered', 'unregistered: %s', 'unregistered', 'media_devices.unregistered.count'],
        ['total-rejected', 'rejected: %s', 'rejected', 'media_devices.rejected.count'],
        ['total-unknown', 'unknown: %s', 'unknown', 'media_devices.unknown.count'],
        ['total-partiallyregistered', 'partially registered: %s', 'partiallyregistered', 'media_devices.partially_registered.count']
    );
    
    $self->{maps_counters}->{global} = [];
    foreach (@map) {
        my $label = $_->[0];
        $label =~ tr/-/_/;
        push @{$self->{maps_counters}->{global}}, {
            label => $_->[0], nlabel => $_->[3], set => {
                key_values => [ { name => $_->[2] } ],
                output_template => $_->[1],
                perfdatas => [
                    { label => $label, value => $_->[2] , template => '%s', min => 0 }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my %mapping_status = (
    1 => 'unknown', 2 => 'registered', 3 => 'unregistered',
    4 => 'rejected', 5 => 'partiallyregistered'
);

my $mapping = {
    display => { oid => '.1.3.6.1.4.1.9.9.156.1.6.1.1.2' }, # ccmMediaDeviceName
    status  => { oid => '.1.3.6.1.4.1.9.9.156.1.6.1.1.5', map => \%mapping_status } # ccmMediaDeviceStatus
};
my $oid_ccmMediaDeviceEntry = '.1.3.6.1.4.1.9.9.156.1.6.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ccmMediaDeviceEntry,
        start => $mapping->{display}->{oid},
        end => $mapping->{status}->{oid},
        nothing_quit => 1
    );

    $self->{md} = {};
    $self->{global} = { unknown => 0, registered => 0, unregistered => 0, rejected => 0, partiallyregistered => 0 };
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{md}->{$instance} = { %$result };
        $self->{global}->{ $result->{status} }++;
    }
}
    
1;

__END__

=head1 MODE

Check media device usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /^registered/').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.

=item B<--critical-*>

Threshold critical.

Can be: 'total-registered', 'total-unregistered', 'total-rejected', 
'total-unknown', 'total-partiallyregistered'.

=back

=cut
