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

package database::informix::snmp::mode::lockstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_instances_output', message_multiple => 'All instances are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'lock-dead', set => {
                key_values => [ { name => 'onServerDeadLocks', diff => 1 }, { name => 'display' } ],
                output_template => 'Deadlocks %d',
                perfdatas => [
                    { label => 'lock_dead', value => 'onServerDeadLocks', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'lock-wait', set => {
                key_values => [ { name => 'onServerLockWaits', diff => 1 }, { name => 'display' } ],
                output_template => 'Lock Waits %d',
                perfdatas => [
                    { label => 'lock_wait', value => 'onServerLockWaits', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'lock-request', set => {
                key_values => [ { name => 'onServerLockRequests', diff => 1 }, { name => 'display' } ],
                output_template => 'Lock Requests %d',
                perfdatas => [
                    { label => 'lock_request', value => 'onServerLockRequests', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'lock-timeout', set => {
                key_values => [ { name => 'onServerLockTimeouts', diff => 1 }, { name => 'display' } ],
                output_template => 'Lock Timeouts %d',
                perfdatas => [
                    { label => 'lock_timeout', value => 'onServerLockTimeouts', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_instances_output {
    my ($self, %options) = @_;
    
    return "Instance '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
    });
    
    return $self;
}

my $mapping = {
    onServerLockRequests    => { oid => '.1.3.6.1.4.1.893.1.1.1.1.1.11' },
    onServerLockWaits       => { oid => '.1.3.6.1.4.1.893.1.1.1.1.1.12' },
    onServerDeadLocks       => { oid => '.1.3.6.1.4.1.893.1.1.1.1.1.16' },
    onServerLockTimeouts    => { oid => '.1.3.6.1.4.1.893.1.1.1.1.1.17' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_applName = '.1.3.6.1.2.1.27.1.1.2';
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $oid_applName },
            { oid => $mapping->{onServerLockWaits}->{oid} },
            { oid => $mapping->{onServerLockRequests}->{oid} },
            { oid => $mapping->{onServerDeadLocks}->{oid} },
            { oid => $mapping->{onServerLockTimeouts}->{oid} },
        ], return_type => 1, nothing_quit => 1
    );

    $self->{global} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{onServerLockRequests}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        my $name = 'default';
        $name = $snmp_result->{$oid_applName . '.' . $instance} 
            if (defined($snmp_result->{$oid_applName . '.' . $instance}));
        
        $self->{global}->{$name} = { 
            display => $name, 
            %$result
        };
    }
    
    $self->{cache_name} = "informix_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check instance locks.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'lock-dead', 'lock-wait', 'lock-request', 'lock-timeout'.

=item B<--critical-*>

Threshold critical.
Can be: 'lock-dead', 'lock-wait', 'lock-request', 'lock-timeout'.

=back

=cut
