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

package centreon::common::cisco::ironport::snmp::mode::mailusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'queue status: ' . $self->{result_values}->{queue_status} . ' [resource conservation: ' . $self->{result_values}->{resource_conservation} . ']';
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'keys', type => 1, cb_prefix_output => 'prefix_keys_output', message_multiple => 'All keys are ok' },
        { name => 'updates', type => 1, cb_prefix_output => 'prefix_updates_output', message_multiple => 'All service updates are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'queue_status' }, { name => 'resource_conservation' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'messages-workqueue', nlabel => 'system.queue.messages.workqueue.count', display_ok => 0, set => {
                key_values => [ { name => 'msgs_in_work_queue' } ],
                output_template => 'messages in work queue: %s',
                perfdatas => [
                    { value => 'msgs_in_work_queue', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'dns-requests-outstanding', nlabel => 'system.dns.requests.outstanding.count', display_ok => 0, set => {
                key_values => [ { name => 'outstandingDNSRequests' } ],
                output_template => 'dns requests with no reply: %s',
                perfdatas => [
                    { value => 'outstandingDNSRequests', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'dns-requests-pending', nlabel => 'system.dns.requests.pending.count', display_ok => 0, set => {
                key_values => [ { name => 'pendingDNSRequests' } ],
                output_template => 'dns requests pending: %s',
                perfdatas => [
                    { value => 'pendingDNSRequests', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'fd-opened', nlabel => 'system.fd.opened.count', display_ok => 0, set => {
                key_values => [ { name => 'openFilesOrSockets' } ],
                output_template => 'fd opened: %s',
                perfdatas => [
                    { value => 'openFilesOrSockets', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'threads-mail', nlabel => 'system.threads.mail.count', display_ok => 0, set => {
                key_values => [ { name => 'mailTransferThreads' } ],
                output_template => 'threads mail: %s',
                perfdatas => [
                    { value => 'mailTransferThreads', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{updates} = [
        { label => 'update-failures', nlabel => 'service.update.failures.count', set => {
                key_values => [ { name => 'updateFailures', diff => 1 }, { name => 'updateServiceName' } ],
                output_template => 'update failures: %s',
                perfdatas => [
                    { value => 'updateFailures', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'updateServiceName' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{keys} = [
        { label => 'time-expiration', nlabel => 'key.time.expiration.seconds', set => {
                key_values => [ { name => 'seconds' }, { name => 'msg' }, { name => 'display' } ],
                output_template => '%s remaining before expiration',
                output_use => 'msg',
                perfdatas => [
                    { value => 'seconds', template => '%s',
                      unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_keys_output {
    my ($self, %options) = @_;
    
    return "Key '" . $options{instance_value}->{display} . "' ";
}

sub prefix_updates_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{updateServiceName} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{resource_conservation} =~ /memoryShortage|queueSpaceShortage/i || %{queue_status} =~ /queueSpaceShortage/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{resource_conservation} =~ /queueFull/i || %{queue_status} =~ /queueFull/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $mapping = {
    keyDescription          => { oid => '.1.3.6.1.4.1.15497.1.1.1.12.1.2' },
    keyIsPerpetual          => { oid => '.1.3.6.1.4.1.15497.1.1.1.12.1.3' },
    keySecondsUntilExpire   => { oid => '.1.3.6.1.4.1.15497.1.1.1.12.1.4' },
};
my $oid_keyExpirationEntry = '.1.3.6.1.4.1.15497.1.1.1.12.1';

my $mapping2 = {
    updateServiceName       => { oid => '.1.3.6.1.4.1.15497.1.1.1.13.1.2' },
    updateFailures          => { oid => '.1.3.6.1.4.1.15497.1.1.1.13.1.4' },
};
my $oid_updateEntry = '.1.3.6.1.4.1.15497.1.1.1.13.1';

my $map_conservation_reason = {
    1 => 'noResourceConservation',
    2 => 'memoryShortage',
    3 => 'queueSpaceShortage',
    4 => 'queueFull'
};
my $map_queue_status = {
    1 => 'queueSpaceAvailable',
    2 => 'queueSpaceShortage',
    3 => 'queueFull',
};

my $mapping3 = {
    queueAvailabilityStatus     => { oid => '.1.3.6.1.4.1.15497.1.1.1.5', map => $map_queue_status },
    resourceConservationReason  => { oid => '.1.3.6.1.4.1.15497.1.1.1.6', map => $map_conservation_reason },
    workQueueMessages           => { oid => '.1.3.6.1.4.1.15497.1.1.1.11' },
    outstandingDNSRequests      => { oid => '.1.3.6.1.4.1.15497.1.1.1.15' },
    pendingDNSRequests          => { oid => '.1.3.6.1.4.1.15497.1.1.1.16' },
    openFilesOrSockets          => { oid => '.1.3.6.1.4.1.15497.1.1.1.19' },
    mailTransferThreads         => { oid => '.1.3.6.1.4.1.15497.1.1.1.20' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result2 = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping3)) ], nothing_quit => 1
    );
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_keyExpirationEntry },
            { oid => $oid_updateEntry },
        ],
    );

    $self->{updates} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_updateEntry}}) {
        next if ($oid !~ /^$mapping2->{updateServiceName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_updateEntry}, instance => $instance);
        
        $self->{updates}->{$instance} = { %$result };
    }

    $self->{keys} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_keyExpirationEntry}}) {
        next if ($oid !~ /^$mapping->{keySecondsUntilExpire}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_keyExpirationEntry}, instance => $instance);
        next if ($result->{keyIsPerpetual} == 1);
        
        $self->{keys}->{$instance} = { 
            display => $result->{keyDescription},
            seconds => $result->{keySecondsUntilExpire},
            msg     => centreon::plugins::misc::change_seconds(value => $result->{keySecondsUntilExpire}),
        };
    }

    my $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result2, instance => 0);
    $self->{global} = {
        queue_status => $result->{queueAvailabilityStatus},
        resource_conservation => $result->{resourceConservationReason},
        msgs_in_work_queue => $result->{workQueueMessages},
        outstandingDNSRequests => $result->{outstandingDNSRequests},
        pendingDNSRequests => $result->{pendingDNSRequests},
        openFilesOrSockets => $result->{openFilesOrSockets},
        mailTransferThreads => $result->{mailTransferThreads},
    };

    $self->{cache_name} = "cisco_ironport_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}
    
1;

__END__

=head1 MODE

Check email security usage.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{queue_status}, %{resource_conservation}

=item B<--warning-status>

Set warning threshold for status (Default: '%{resource_conservation} =~ /memoryShortage|queueSpaceShortage/i || %{queue_status} =~ /queueSpaceShortage/i').
Can used special variables like: %{queue_status}, %{resource_conservation}

=item B<--critical-status>

Set critical threshold for status (Default: '%{resource_conservation} =~ /queueFull/i || %{queue_status} =~ /queueFull/i').
Can used special variables like: %{queue_status}, %{resource_conservation}

=item B<--warning-*> B<--critical-*> 

Warning threshold.
Can be: 'messages-workqueue', 'dns-requests-outstanding', 
'dns-requests-pending', 'fd-opened', 'threads-mail', 
'update-failures', 'time-expiration'.

=back

=cut
    
