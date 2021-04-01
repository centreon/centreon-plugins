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

package network::cisco::asa::snmp::mode::failover;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Primary unit is '%s' [details: '%s'], Secondary unit is '%s' [details : '%s']", 
        $self->{result_values}->{primaryState}, $self->{result_values}->{primaryDetails}, 
        $self->{result_values}->{secondaryState}, $self->{result_values}->{secondaryDetails});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{primaryStateLast} = $options{old_datas}->{$self->{instance} . '_primary_state'};
    $self->{result_values}->{primaryState} = $options{new_datas}->{$self->{instance} . '_primary_state'};
    $self->{result_values}->{secondaryStateLast} = $options{old_datas}->{$self->{instance} . '_secondary_state'};
    $self->{result_values}->{secondaryState} = $options{new_datas}->{$self->{instance} . '_secondary_state'};
    $self->{result_values}->{primaryDetails} = $options{new_datas}->{$self->{instance} . '_primary_details'};
    $self->{result_values}->{secondaryDetails} = $options{new_datas}->{$self->{instance} . '_secondary_details'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'active-units', set => {
                key_values => [ { name => 'active_units' } ],
                output_template => 'Active units : %s',
                perfdatas => [
                    { label => 'active_units', value => 'active_units', template => '%s', 
                      min => 0, max => 2 },
                ],
            }
        },
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'primary_state' }, { name => 'secondary_state' }, { name => 'primary_details' }, { name => 'secondary_details' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "warning-status:s"        => { name => 'warning_status', default => '' },
                                "critical-status:s"       => { name => 'critical_status', default => '' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_failover = (
    1 => 'other',
    2 => 'up', # for '.4' index
    3 => 'down', # can be
    4 => 'error', # maybe
    5 => 'overTemp',
    6 => 'busy',
    7 => 'noMedia',
    8 => 'backup',
    9 => 'active', # can be
    10 => 'standby' # can be
);

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    
    # primary is '.6' index and secondary is '.7' index (it's like that. '.4' is the global interface)
    my $oid_cfwHardwareStatusValue_primary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.3.6';
    my $oid_cfwHardwareStatusValue_secondary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.3.7';
    my $oid_cfwHardwareStatusDetail_primary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.4.6';
    my $oid_cfwHardwareStatusDetail_secondary = '.1.3.6.1.4.1.9.9.147.1.2.1.1.1.4.7';
    my $result = $options{snmp}->get_leef(oids => [$oid_cfwHardwareStatusValue_primary, $oid_cfwHardwareStatusValue_secondary, 
                                                   $oid_cfwHardwareStatusDetail_primary, $oid_cfwHardwareStatusDetail_secondary], nothing_quit => 1);
    
    $self->{global}->{primary_state} = $map_failover{$result->{$oid_cfwHardwareStatusValue_primary}};
    $self->{global}->{primary_details} = $result->{$oid_cfwHardwareStatusDetail_primary};
    $self->{global}->{secondary_state} = $map_failover{$result->{$oid_cfwHardwareStatusValue_secondary}};
    $self->{global}->{secondary_details} = $result->{$oid_cfwHardwareStatusDetail_secondary};
    my $active_units = 0;
    $active_units++ if ($result->{$oid_cfwHardwareStatusValue_primary} == 9 || $result->{$oid_cfwHardwareStatusValue_primary} == 10);
    $active_units++ if ($result->{$oid_cfwHardwareStatusValue_secondary} == 9 || $result->{$oid_cfwHardwareStatusValue_secondary} == 10);
    $self->{global}->{active_units} = $active_units;
    
    $self->{cache_name} = "cisco_asa_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check failover status on Cisco ASA (CISCO-UNIFIED-FIREWALL-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{primaryStateLast}, %{secondaryStateLast}, %{primaryState}, %{secondaryState}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{primaryStateLast}, %{secondaryStateLast}, %{primaryState}, %{secondaryState}

=item B<--warning-*>

Threshold warning.
Can be: 'active-units'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-units'.

=back

=cut
    
