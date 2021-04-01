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

package storage::netapp::ontap::snmp::mode::snapvaultusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status} . ' [state : ' . $self->{result_values}->{state} . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_svStatus'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_svState'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'snapvault', type => 1, cb_prefix_output => 'prefix_snapvault_output', message_multiple => 'All snapvault usages are ok', skipped_code => { -10 => 1, -11 => 1 } }
    ];

    $self->{maps_counters}->{snapvault} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'svState' }, { name => 'svStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'lag', set => {
                key_values => [ { name => 'svLag' }, { name => 'display' } ],
                output_template => 'lag : %s seconds',
                perfdatas => [
                    { label => 'lag', template => '%s', min => 0, unit => 's',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'transfer-traffic', set => {
                key_values => [ { name => 'svTotalTransMBs', per_second => 1 }, { name => 'display' } ],
                output_template => 'transfer traffic : %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'transfer_traffic', template => '%.2f',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'transfer-succeed', display_ok => 0, set => {
                key_values => [ { name => 'svTotalSuccesses' }, { name => 'display' } ],
                output_template => 'transfer succeed : %s',
                perfdatas => [
                    { label => 'transfer_succeed', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'transfer-failed', display_ok => 0, set => {
                key_values => [ { name => 'svTotalFailures' }, { name => 'display' } ],
                output_template => 'transfer failed : %s',
                perfdatas => [
                    { label => 'transfer_failed', template => '%s', min => 0,
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_snapvault_output {
    my ($self, %options) = @_;

    return "Snapvault '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_status = {
    1 => 'idle', 2 => 'transferring', 3 => 'pending',
    4 => 'aborting', 6 => 'quiescing', 7 => 'resyncing',
    12 => 'paused',
};

my $map_state = {
    1 => 'uninitialized', 2 => 'snapvaulted',
    3 => 'brokenOff', 4 => 'quiesced',
    5 => 'source', 6 => 'unknown', 7 => 'restoring',
};

my $mapping = {
    svStatus            => { oid => '.1.3.6.1.4.1.789.1.19.11.1.4', map => $map_status }, 
    svState             => { oid => '.1.3.6.1.4.1.789.1.19.11.1.5', map => $map_state },
    svLag               => { oid => '.1.3.6.1.4.1.789.1.19.11.1.6' }, # timeticks
    svTotalSuccesses    => { oid => '.1.3.6.1.4.1.789.1.19.11.1.7' },
    svTotalFailures     => { oid => '.1.3.6.1.4.1.789.1.19.11.1.9' },
    svTotalTransMBs     => { oid => '.1.3.6.1.4.1.789.1.19.11.1.11' },
};

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_svOn = '.1.3.6.1.4.1.789.1.19.1.0';

    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_svOn]);
    if (!defined($snmp_result->{$oid_svOn}) || $snmp_result->{$oid_svOn} != 2) {
        $self->{output}->add_option_msg(short_msg => "snapvault is not turned on.");
        $self->{output}->option_exit();
    }
    
    my $oid_svSrc = '.1.3.6.1.4.1.789.1.19.11.1.2';
    my $oid_svDst = '.1.3.6.1.4.1.789.1.19.11.1.3';
    
    $self->{snapvault} = {};
    $snmp_result = $options{snmp}->get_multiple_table(oids => [{ oid => $oid_svSrc }, { oid => $oid_svDst }], return_type => 1, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$oid_svSrc\.(.*)$/);
        my $instance = $1;
        my $name = $snmp_result->{$oid_svSrc . '.' . $instance} . '.' . $snmp_result->{$oid_svDst . '.' . $instance};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping snapvault '" . $name . "'.", debug => 1);
            next;
        }

        $self->{snapvault}->{$instance} = { display => $name };
    }

    if (scalar(keys %{$self->{snapvault}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
    
    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [keys %{$self->{snapvault}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{snapvault}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $result->{svTotalTransMBs} *= 1024 * 1024;
        $result->{svLag} = int($result->{svLag} / 100);
        
        $self->{snapvault}->{$_} = { %{$self->{snapvault}->{$_}}, %$result };
    }
    
    $self->{cache_name} = "netapp_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check snapvault usage.

=over 8

=item B<--filter-name>

Filter snapvault name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{state}, %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be:  'lag' (s), 'transfer-traffic' (B/s), 'transfer-succeed',
'transfer-failed'.

=back

=cut
