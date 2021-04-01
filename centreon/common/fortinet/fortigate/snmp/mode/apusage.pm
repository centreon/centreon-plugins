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

package centreon::common::fortinet::fortigate::snmp::mode::apusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status} . ' [admin: ' . $self->{result_values}->{admin} . ']';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All access points are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{ap} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'admin' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'in-traffic', nlabel => 'accesspoint.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'in', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'traffic in: %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'out-traffic', nlabel => 'accesspoint.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'out', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'traffic out: %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'clients', nlabel => 'accesspoint.clients.current.count', set => {
                key_values => [ { name => 'clients' }, { name => 'display' } ],
                output_template => 'current client connections: %s',
                perfdatas => [
                    { label => 'clients', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'cpu', nlabel => 'accesspoint.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu' }, { name => 'display' } ],
                output_template => 'cpu usage: %.2f %%',
                perfdatas => [
                    { label => 'cpu', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'memory', nlabel => 'accesspoint.memory.usage.bytes', set => {
                key_values => [ { name => 'memory' }, { name => 'display' } ],
                output_template => 'memory usage: %.2f %%',
                perfdatas => [
                    { label => 'memory', template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "Access point '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{admin} eq "enable" and %{status} !~ /online/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my %map_ap_admin = (
    0 => 'other', 1 => 'discovered', 2 => 'disable', 3 => 'enable',
);

my %map_ap_connect_status = (
    0 => 'other', 1 => 'offLine', 2 => 'onLine', 3 => 'downloadingImage', 4 => 'connectedImage',
);

my $mapping = {
    fgWcWtpConfigWtpAdmin   => { oid => '.1.3.6.1.4.1.12356.101.14.4.3.1.2', map => \%map_ap_admin },
    fgWcWtpConfigWtpName    => { oid => '.1.3.6.1.4.1.12356.101.14.4.3.1.3' }
};

my $mapping2 = {
    fgWcWtpSessionConnectionState   => { oid => '.1.3.6.1.4.1.12356.101.14.4.4.1.7', map => \%map_ap_connect_status  },
    fgWcWtpSessionWtpStationCount   => { oid => '.1.3.6.1.4.1.12356.101.14.4.4.1.17'},
    fgWcWtpSessionWtpByteRxCount    => { oid => '.1.3.6.1.4.1.12356.101.14.4.4.1.18' },
    fgWcWtpSessionWtpByteTxCount    => { oid => '.1.3.6.1.4.1.12356.101.14.4.4.1.19' },
    fgWcWtpSessionWtpCpuUsage       => { oid => '.1.3.6.1.4.1.12356.101.14.4.4.1.20' },
    fgWcWtpSessionWtpMemoryUsage    => { oid => '.1.3.6.1.4.1.12356.101.14.4.4.1.21' }
};
my $oid_fgWcWtpConfigEntry = '.1.3.6.1.4.1.12356.101.14.4.3.1';

sub manage_selection {
    my ($self, %options) = @_;
 
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_fgWcWtpConfigEntry, 
        start => $mapping->{fgWcWtpConfigWtpAdmin}->{oid},
        end => $mapping->{fgWcWtpConfigWtpName}->{oid},
        nothing_quit => 1
    );

    $self->{ap} = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{fgWcWtpConfigWtpName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{fgWcWtpConfigWtpName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping access point '" . $result->{fgWcWtpConfigWtpName} . "'.", debug => 1);
            next;
        }

        $self->{ap}->{$instance} = {
            display => $result->{fgWcWtpConfigWtpName},
            admin => $result->{fgWcWtpConfigWtpAdmin},
            status => 'n/a',
        };
    }

    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No access point found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [
            $mapping2->{fgWcWtpSessionConnectionState}->{oid}, $mapping2->{fgWcWtpSessionWtpStationCount}->{oid},
            $mapping2->{fgWcWtpSessionWtpByteRxCount}->{oid}, $mapping2->{fgWcWtpSessionWtpByteTxCount}->{oid},
            $mapping2->{fgWcWtpSessionWtpCpuUsage}->{oid}, $mapping2->{fgWcWtpSessionWtpMemoryUsage}->{oid},
        ], 
        instances => [keys %{$self->{ap}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{ap}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);        

        $self->{ap}->{$_}->{status} = $result->{fgWcWtpSessionConnectionState};
        $self->{ap}->{$_}->{in} = defined($result->{fgWcWtpSessionWtpByteRxCount}) ? ($result->{fgWcWtpSessionWtpByteRxCount} * 8) : undef;
        $self->{ap}->{$_}->{out} = defined($result->{fgWcWtpSessionWtpByteTxCount}) ? ($result->{fgWcWtpSessionWtpByteTxCount} * 8) : undef;
        $self->{ap}->{$_}->{clients} = $result->{fgWcWtpSessionWtpStationCount};
        $self->{ap}->{$_}->{cpu} = $result->{fgWcWtpSessionWtpCpuUsage};
        $self->{ap}->{$_}->{memory} = $result->{fgWcWtpSessionWtpMemoryUsage};
    }

    $self->{cache_name} = 'fortigate_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check access point usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'in-traffic', 'out-traffic', 'cpu' (%), 'memory' (%),
'clients'.

=item B<--critical-*>

Threshold critical.
Can be: 'in-traffic', 'out-traffic', 'cpu' (%), 'memory' (%),
'clients'.

=item B<--filter-name>

Filter by access point name (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{admin}, %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{admin}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admin} eq "enable" and %{status} !~ /online/i'').
Can used special variables like: %{admin}, %{status}, %{display}

=back

=cut
