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

package hardware::devices::gorgy::ntpserver::snmp::mode::globalstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_sync_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'Current synchronization status : ' . $self->{result_values}->{sync_status};
    return $msg;
}

sub custom_timebase_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'Internal time base status : ' . $self->{result_values}->{timebase_status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{$options{extra_options}->{label_ref}} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'sync-status', threshold => 0, set => {
                key_values => [ { name => 'sync_status' } ],
                closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => 'sync_status' },
                closure_custom_output => $self->can('custom_sync_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'timebase-status', threshold => 0, set => {
                key_values => [ { name => 'timebase_status' } ],
                closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => 'timebase_status' },
                closure_custom_output => $self->can('custom_timebase_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'ntp-requests', set => {
                key_values => [ { name => 'ntp_requests', diff => 1 } ],
                output_template => 'Number of ntp requests : %s',
                perfdatas => [
                    { label => 'ntp_requests', value => 'ntp_requests', template => '%s', 
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-sync-status:s'      => { name => 'warning_sync_status', default => '%{sync_status} =~ /Running with autonomy|Free running/i' },
        'critical-sync-status:s'     => { name => 'critical_sync_status', default => '%{sync_status} =~ /Server locked|Never synchronized|Server not synchronized/i' },
        'warning-timebase-status:s'  => { name => 'warning_timebase_status', default => '%{timebase_status} =~ /^(?!(XO|XO OK|TCXO Precision < 2usec|OCXO Precision < 1usec)$)/i' },
        'critical-timebase-status:s' => { name => 'critical_timebase_status', default => '%{timebase_status} =~ /^XO$/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_sync_status', 'critical_sync_status', 'warning_timebase_status', 'critical_timebase_status']);
}

# timeBaseState values:
#   XO Warming up...
#   XO OK
#   TCXO
#   TCXO Precision > 25usec
#   2usec < TCXO Precision < 25usec
#   TCXO Precision < 2usec
#   OCXO Warming up...
#   OCXO Precision > 20usec
#   1usec < OCXO Precision < 20usec
#   OCXO Precision < 1usec
#   XO

# currentSyncState values:
#   Server locked
#   Free running
#   Never synchronized
#   Server synchronized
#   Running with autonomy
#   Server not synchronized
#   Computing synchronization

my $mapping = {
    currentSyncState    => { oid => '.1.3.6.1.4.1.8955.1.8.1.10' },
    timeBaseState       => { oid => '.1.3.6.1.4.1.8955.1.8.1.12' },
    powerDownFlags      => { oid => '.1.3.6.1.4.1.8955.1.8.1.20' },
    ntpRequestsNumber   => { oid => '.1.3.6.1.4.1.8955.1.8.2.3' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $mapping->{currentSyncState}->{oid} . '.0',
            $mapping->{timeBaseState}->{oid} . '.0',
            $mapping->{ntpRequestsNumber}->{oid} . '.0'
        ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->{global} = {
        sync_status     => $result->{currentSyncState}, 
        timebase_status => $result->{timeBaseState}, 
        ntp_requests    => $result->{ntpRequestsNumber}
    };

    $self->{cache_name} = "gorgy_ntpserver_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check ntp server status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^sync-status$'

=item B<--warning-sync-status>

Set warning threshold for status (Default: '%{sync_status} =~ /Running with autonomy|Free running/i').
Can used special variables like: %{sync_status}

=item B<--critical-sync-status>

Set critical threshold for status (Default: '%{sync_status} =~ /Server locked|Never synchronized|Server not synchronized/i').
Can used special variables like: %{sync_status}

=item B<--warning-timebase-status>

Set warning threshold for status (Default: '%{timebase_status} =~ /^(?!(XO|XO OK|TCXO Precision < 2usec|OCXO Precision < 1usec)$)/i').
Can used special variables like: %{timebase_status}

=item B<--critical-timebase-status>

Set critical threshold for status (Default: '%{timebase_status} =~ /^XO$/i').
Can used special variables like: %{timebase_status}

=item B<--warning-*>

Threshold warning.
Can be: 'ntp-requests'.

=item B<--critical-*>

Threshold critical.
Can be: 'ntp-requests'.

=back

=cut
