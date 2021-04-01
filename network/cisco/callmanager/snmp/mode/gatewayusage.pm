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

package network::cisco::callmanager::snmp::mode::gatewayusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_ccmGatewayStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_ccmGatewayName'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'gateway', type => 1, cb_prefix_output => 'prefix_gateway_output', message_multiple => 'All gateways are ok' },
    ];
    
    $self->{maps_counters}->{gateway} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'ccmGatewayStatus' }, { name => 'ccmGatewayName' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
    
    my @map = (
        ['total-registered', 'Registered : %s', 'registered'],
        ['total-unregistered', 'Unregistered : %s', 'unregistered'],
        ['total-rejected', 'Rejected : %s', 'rejected'],
        ['total-unknown', 'Unknown : %s', 'unknown'],
        ['total-partiallyregistered', 'Partially Registered : %s', 'partiallyregistered'],
    );
    
    $self->{maps_counters}->{global} = [];
    foreach (@map) {
        my $label = $_->[0];
        $label =~ tr/-/_/;
        push @{$self->{maps_counters}->{global}}, { label => $_->[0], set => {
                key_values => [ { name => $_->[2] } ],
                output_template => $_->[1],
                perfdatas => [
                    { label => $label, value => $_->[2] , template => '%s', min => 0 },
                ],
            }
        },
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "warning-status:s"    => { name => 'warning_status', default => '' },
                                "critical-status:s"   => { name => 'critical_status', default => '%{status} !~ /^registered/' },
                                });
                                
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_gateway_output {
    my ($self, %options) = @_;

    return "Gateway '" . $options{instance_value}->{ccmGatewayName} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "Total ";
}

my %mapping_status = (
    1 => 'unknown', 2 => 'registered', 3 => 'unregistered',
    4 => 'rejected', 5 => 'partiallyregistered',
);

my $mapping = {
    ccmGatewayName      => { oid => '.1.3.6.1.4.1.9.9.156.1.3.1.1.2' },
    ccmGatewayStatus    => { oid => '.1.3.6.1.4.1.9.9.156.1.3.1.1.5', map => \%mapping_status },
};

my $oid_ccmGatewayEntry = '.1.3.6.1.4.1.9.9.156.1.3.1.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    my $snmp_result = $options{snmp}->get_table(oid => $oid_ccmGatewayEntry, start => $mapping->{ccmGatewayName}->{oid}, end => $mapping->{ccmGatewayStatus}->{oid}, nothing_quit => 1);
    
    $self->{phone} = {};
    $self->{global} = { unknown => 0, registered => 0, unregistered => 0, rejected => 0, partiallyregistered => 0 };
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{ccmGatewayStatus}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{phone}->{$instance} = { %$result };
        $self->{global}->{$result->{ccmGatewayStatus}}++;
    }
}
    
1;

__END__

=head1 MODE

Check gateway usage.

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
