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

package apps::pineapp::securemail::snmp::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status is ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_storage_status_output {
    my ($self, %options) = @_;

    my $msg = 'Storage status is ' . $self->{result_values}->{status};
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global_load', type => 0, cb_prefix_output => 'prefix_load_output', skipped_code => { -10 => 1 } },
        { name => 'global', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
        { name => 'service', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok' },
    ];

    $self->{maps_counters}->{global_load} = [];
    foreach ('1', '5', '15') {
        push @{$self->{maps_counters}->{global_load}}, {
            label => 'load-' . $_ . 'm', nlabel => 'system.load.' . $_ . 'm.count', set => {
                key_values => [ { name => 'cpuload' . $_ . 'minavg' } ],
                output_template => '%s (' . $_ . 'm)',
                perfdatas => [
                    { value => 'cpuload' . $_ . 'minavg', template => '%s', min => 0 },
                ],
            }
        };
    }

    $self->{maps_counters}->{global} = [
        { label => 'storage-status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_storage_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'messages-queue-inbound', nlabel => 'system.messages.queue.inbound.count', display_ok => 0, set => {
                key_values => [ { name => 'mailsysteminboundqueue' } ],
                output_template => 'messages inbound queue: %s',
                perfdatas => [
                    { value => 'mailsysteminboundqueue', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-queue-outbound', nlabel => 'system.messages.queue.outbound.count', display_ok => 0, set => {
                key_values => [ { name => 'mailsystemoutboundqueue' } ],
                output_template => 'messages outbound queue: %s',
                perfdatas => [
                    { value => 'mailsystemoutboundqueue', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-priority-high', nlabel => 'system.messages.priority.high.count', display_ok => 0, set => {
                key_values => [ { name => 'mailQueueHigh' } ],
                output_template => 'messages high priority: %s',
                perfdatas => [
                    { value => 'mailQueueHigh', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-priority-normal', nlabel => 'system.messages.priority.normal.count', display_ok => 0, set => {
                key_values => [ { name => 'mailQueueNormal' } ],
                output_template => 'messages normal priority: %s',
                perfdatas => [
                    { value => 'mailQueueNormal', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-priority-low', nlabel => 'system.messages.priority.low.count', display_ok => 0, set => {
                key_values => [ { name => 'mailQueueLow' } ],
                output_template => 'messages low priority: %s',
                perfdatas => [
                    { value => 'mailQueueLow', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'messages-queue-total', nlabel => 'system.messages.queue.total.count', display_ok => 0, set => {
                key_values => [ { name => 'mailQueueTotal' } ],
                output_template => 'messages queue total: %s',
                perfdatas => [
                    { value => 'mailQueueTotal', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{service} = [
        { label => 'service-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_load_output {
    my ($self, %options) = @_;
    
    return 'Load average: ';
}

sub prefix_service_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-service-status:s'  => { name => 'unknown_service_status', default => '' },
        'warning-service-status:s'  => { name => 'warning_service_status', default => '' },
        'critical-service-status:s' => { name => 'critical_service_status', default => '%{status} !~ /running/i' },
        'unknown-storage-status:s'  => { name => 'unknown_storage_status', default => '' },
        'warning-storage-status:s'  => { name => 'warning_storage_status', default => '' },
        'critical-storage-status:s' => { name => 'critical_storage_status', default => '%{status} !~ /ok/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'unknown_service_status', 'warning_service_status', 'critical_service_status',
            'unknown_storage_status', 'warning_storage_status', 'critical_storage_status',
        ]
    );
}

my $map_sc_status = { 0 => 'stopped', 1 => 'running' };

my $mapping = {
    cpuload1minavg  => { oid => '.1.3.6.1.4.1.19801.1.1.3.1' },
    cpuload5minavg  => { oid => '.1.3.6.1.4.1.19801.1.1.3.2' },
    cpuload15minavg => { oid => '.1.3.6.1.4.1.19801.1.1.3.3' },
    storage         => { oid => '.1.3.6.1.4.1.19801.1.4' },
    smtpservicestatus       => { oid => '.1.3.6.1.4.1.19801.2.1.1', map => $map_sc_status },
    pop3servicestatus       => { oid => '.1.3.6.1.4.1.19801.2.1.2', map => $map_sc_status },
    imap4servicestatus      => { oid => '.1.3.6.1.4.1.19801.2.1.3', map => $map_sc_status },
    mailsysteminboundqueue  => { oid => '.1.3.6.1.4.1.19801.2.1.10.1' },
    mailsystemoutboundqueue => { oid => '.1.3.6.1.4.1.19801.2.1.10.2' },
    mailQueueHigh           => { oid => '.1.3.6.1.4.1.19801.2.1.10.3.1' },
    mailQueueNormal         => { oid => '.1.3.6.1.4.1.19801.2.1.10.3.2' },
    mailQueueLow            => { oid => '.1.3.6.1.4.1.19801.2.1.10.3.3' },
    mailQueueTotal          => { oid => '.1.3.6.1.4.1.19801.2.1.10.3.4' },
    antivirusservicestatus  => { oid => '.1.3.6.1.4.1.19801.2.5.1', map => $map_sc_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ], nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    $self->{service} = {
        smtp => { status => $result->{smtpservicestatus}, display => 'smtp' },
        pop3 => { status => $result->{pop3servicestatus}, display => 'pop3' },
        imap4 => { status => $result->{imap4servicestatus}, display => 'imap4' },
        antivirus => { status => $result->{antivirusservicestatus}, display => 'antivirus' },
    };

    $self->{global_load} = { %$result };
    $self->{global} = {
        status => $result->{storage},
        mailsysteminboundqueue => $result->{mailsysteminboundqueue},
        mailsystemoutboundqueue => $result->{mailsystemoutboundqueue},
        mailQueueHigh => $result->{mailQueueHigh},
        mailQueueNormal => $result->{mailQueueNormal},
        mailQueueLow => $result->{mailQueueLow},
        mailQueueTotal => $result->{mailQueueTotal},
    };
}
    
1;

__END__

=head1 MODE

Check system usage.

=over 8

=item B<--unknown-service-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-service-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-service-status>

Set critical threshold for status (Default: '%{status} !~ /running/i').
Can used special variables like: %{status}, %{display}

=item B<--unknown-storage-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-storage-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-storage-status>

Set critical threshold for status (Default: '%{status} !~ /ok/i').
Can used special variables like: %{status}

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'load-1m', 'load-5m', 'load-15m', 
'messages-priority-high', 'messages-priority-medium', 'messages-priority-low',
'messages-queue-inbound', 'messages-queue-outbound',
'messages-queue-total'.

=back

=cut
    
