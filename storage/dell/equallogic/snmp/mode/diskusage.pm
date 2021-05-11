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

package storage::dell::equallogic::snmp::mode::diskusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output { 
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status} . ' [smart health: ' . $self->{result_values}->{health} . ']';
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return "Disk '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'disk', type => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disk usages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{disk} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /on-line|spare|off-line/i', set => {
                key_values => [ { name => 'health' }, { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'read', set => {
                key_values => [ { name => 'bytes_read', per_second => 1 }, { name => 'display' } ],
                output_template => 'read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'read_iops', template => '%.2f',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write', set => {
                key_values => [ { name => 'bytes_written', per_second => 1 }, { name => 'display' } ],
                output_template => 'write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'write', template => '%.2f',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'busy-time', set => {
                key_values => [ { name => 'busy_time', diff => 1 }, { name => 'display' } ],
                output_template => 'time busy: %s sec',
                perfdatas => [
                    { label => 'busy_time', template => '%s',
                      unit => 's', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $map_disk_status = {
    1 => 'on-line', 2 => 'spare', 3 => 'failed', 4 => 'off-line',
    5 => 'alt-sig', 6 => 'too-small', 7 => 'history-of-failures',
    8 => 'unsupported-version', 9 => 'unhealthy', 10 => 'replacement',
    11 => 'encrypted', 12 => 'notApproved', 13 => 'preempt-failed'
};

my $map_disk_health = {
    0 => 'smart-status-not-available',
    1 => 'smart-ok',
    2 => 'smart-tripped'
};

my $mapping = {
    health        => { oid => '.1.3.6.1.4.1.12740.3.1.1.1.17', map => $map_disk_health }, # eqlDiskHealth
    bytes_read    => { oid => '.1.3.6.1.4.1.12740.3.1.2.1.2' }, # eqlDiskStatusBytesRead [MB]
    bytes_written => { oid => '.1.3.6.1.4.1.12740.3.1.2.1.3' }, # eqlDiskStatusBytesWritten [MB]
    busy_time     => { oid => '.1.3.6.1.4.1.12740.3.1.2.1.4' }, # eqlDiskStatusBusyTime [seconds]
};

sub manage_selection {
    my ($self, %options) = @_;
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $oid_eqlMemberName = '.1.3.6.1.4.1.12740.2.1.1.1.9';
    my $oid_eqlDiskStatus = '.1.3.6.1.4.1.12740.3.1.1.1.8';
    
    $self->{disk} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [{ oid => $oid_eqlMemberName }, { oid => $oid_eqlDiskStatus }], return_type => 1, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_eqlDiskStatus\.(\d+)\.(\d+)\.(\d+)$/);
        my $instance = $1 . '.' . $2 . '.' . $3;
        my $array_name = $snmp_result->{$oid_eqlMemberName . '.' . $1 . '.' . $2};
        my $name = $array_name . '.' . $3;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping disk '" . $name . "'.", debug => 1);
            next;
        }

        $self->{disk}->{$instance} = { display => $name, status => $map_disk_status->{ $snmp_result->{$oid} } };
    }

    if (scalar(keys %{$self->{disk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [keys %{$self->{disk}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{disk}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $result->{bytes_read} *= 1024 * 1024;
        $result->{bytes_written} *= 1024 * 1024;
        $result->{health} = 'n/a' if (!defined($result->{health}));
        
        $self->{disk}->{$_} = { %{$self->{disk}->{$_}}, %$result };
    }
    
    $self->{cache_name} = 'dell_equallogic_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check disk usage.

=over 8

=item B<--filter-name>

Filter disk name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{health}, %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{health}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /on-line|spare|off-line/i').
Can used special variables like: %{health}, %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be:  'busy-time' (s), 'read-iops' (iops), 'write-iops' (iops).

=back

=cut
