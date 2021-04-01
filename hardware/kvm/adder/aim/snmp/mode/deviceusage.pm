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

package hardware::kvm::adder::aim::snmp::mode::deviceusage;

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
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_device_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
        { name => 'device', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok' }
    ];
    
     $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total devices : %s',
                perfdatas => [
                    { label => 'devices_total', value => 'total', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'online', set => {
                key_values => [ { name => 'online' }, { name => 'total' } ],
                output_template => 'Online devices : %s',
                perfdatas => [
                    { label => 'devices_online', value => 'online', template => '%s', min => 0, max => 'total' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{device} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'device_status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_device_output {
    my ($self, %options) = @_;
    
    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => 'not %{status} =~ /online|rebooting|upgrading/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_status = (
    1 => 'offline', 2 => 'online', 3 => 'rebooting', 4 => 'resetting', 
    5 => 'upgrading', 6 => 'unconfigured', 7 => 'backup', 8 => 'unknown',
);
my $oid_deviceName = '.1.3.6.1.4.1.25119.1.1.1.4';
my $mapping = {
    deviceStatus    => { oid => '.1.3.6.1.4.1.25119.1.1.1.20', map => \%map_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_deviceName, nothing_quit => 1);
    $self->{device} = {};
    $self->{global} = { total => 0, online => 0 };
    foreach my $oid (keys %{$snmp_result}) {
        $oid =~ /^$oid_deviceName\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $snmp_result->{$oid} . "'.", debug => 1);
            next;
        }
        
        $self->{device}->{$instance} = { display => $snmp_result->{$oid} };
    }
    
    $options{snmp}->load(oids => [$mapping->{deviceStatus}->{oid}], 
        instances => [keys %{$self->{device}}], instance_regexp => '^(.*)$');
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);
    
    foreach (keys %{$self->{device}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        $self->{device}->{$_}->{device_status} = $result->{deviceStatus};
        $self->{global}->{$result->{deviceStatus}}++ if (defined($self->{global}->{$result->{deviceStatus}}));
        $self->{global}->{total}++;
    }
    
    if (scalar(keys %{$self->{device}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No device found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check device usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total$'

=item B<--filter-name>

Filter by device name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: 'not %{status} =~ /online|rebooting|upgrading/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'online'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'online'.

=back

=cut
