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

package network::audiocodes::snmp::mode::trunkstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'alarm status : ' . $self->{result_values}->{alarm} . ' [state: ' . $self->{result_values}->{state} . ']';
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{alarm} = $options{new_datas}->{$self->{instance} . '_alarm'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{dchannel} = $options{new_datas}->{$self->{instance} . '_dchannel'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'trunk', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All trunks are ok' }
    ];
    
    $self->{maps_counters}->{trunk} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'display' }, { name => 'dchannel' }, { name => 'alarm' }, { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'avg-calls', set => {
                key_values => [ { name => 'acPMTrunkUtilizationAverage' }, { name => 'display' } ],
                output_template => 'Average calls : %s',
                perfdatas => [
                    { label => 'avg_calls', value => 'acPMTrunkUtilizationAverage', template => '%d',
                      min => 0, unit => 'calls', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'max-calls', set => {
                key_values => [ { name => 'acPMTrunkUtilizationMax' }, { name => 'display' } ],
                output_template => 'Max calls : %s',
                perfdatas => [
                    { label => 'max_calls', value => 'acPMTrunkUtilizationMax', template => '%d',
                      min => 0, unit => 'calls', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'count-calls', set => {
                key_values => [ { name => 'acPMTrunkUtilizationTotal', diff => 1 }, { name => 'display' } ],
                output_template => 'Count calls : %s',
                perfdatas => [
                    { label => 'count_calls', value => 'acPMTrunkUtilizationTotal', template => '%d',
                      min => 0, unit => 'calls', label_extra_instance => 1, instance_use => 'display' },
                ],
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
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{state} =~ /activated/ and %{alarm} !~ /greenActive/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_vpn_output {
    my ($self, %options) = @_;
    
    return "Trunk '" . $options{instance_value}->{display} . "' ";
}

my %map_alarm = (0 => 'greyDisabled', 1 => 'greenActive', 2 => 'redLosLof', 
3 => 'blueAis', 4 => 'yellowRai', 5 => 'orangeDChannel', 6 => 'purpleLowerLayerDown', 7 => 'darkOrangeNFASAlarm');
my %map_dchannel = (0 => 'dChannelEstablished', 1 => 'dChannelNotEstablished', 10 => 'dChannelNotApplicable');
my %map_deactivate = (0 => 'notAvailable', 1 => 'deActivated', 2 => 'activated');

my $mapping = {
    status => {
        acTrunkStatusDChannel   => { oid => '.1.3.6.1.4.1.5003.9.10.9.2.1.1.1.6', map => \%map_dchannel },
        acTrunkStatusAlarm      => { oid => '.1.3.6.1.4.1.5003.9.10.9.2.1.1.1.7', map => \%map_alarm },
        acTrunkDeactivate       => { oid => '.1.3.6.1.4.1.5003.9.10.9.1.1.1.1.1.11', map => \%map_deactivate },
        acTrunkName             => { oid => '.1.3.6.1.4.1.5003.9.10.9.1.1.1.1.1.13' },
    },
    usage => {
        acPMTrunkUtilizationAverage => { oid => '.1.3.6.1.4.1.5003.10.10.2.21.1.4' },
        acPMTrunkUtilizationMax     => { oid => '.1.3.6.1.4.1.5003.10.10.2.21.1.5' },
        acPMTrunkUtilizationTotal   => { oid => '.1.3.6.1.4.1.5003.10.10.2.21.1.12' },
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{trunk} = {};
    my $oids = [];
    foreach (keys %{$mapping}) {
        foreach my $name (keys %{$mapping->{$_}}) {
            push @{$oids}, { oid => $mapping->{$_}->{$name}->{oid} };
        }
    }
    my $snmp_result = $options{snmp}->get_multiple_table(oids => $oids, nothing_quit => 1);

    my $datas = { status => {}, usage => {} };
    foreach (keys %{$mapping}) {
        foreach my $name (keys %{$mapping->{$_}}) {
            $datas->{$_} = { %{$datas->{$_}}, %{$snmp_result->{ $mapping->{$_}->{$name}->{oid} }} };
        }
    }
    foreach (keys %{$snmp_result->{ $mapping->{status}->{acTrunkStatusAlarm}->{oid} }}) {
        /\.(\d+)$/;
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping->{status}, results => $datas->{status}, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping->{usage}, results => $datas->{usage}, instance => $instance . '.0');
        
        my $display = defined($result->{acTrunkName}) && $result->{acTrunkName} ne '' ? $result->{acTrunkName} : $instance;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $display !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $display . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{trunk}->{$instance} = { 
            display => $display, 
            alarm => $result->{acTrunkStatusAlarm},
            state => $result->{acTrunkDeactivate},
            dchannel => $result->{acTrunkStatusDChannel},
            %$result2 };
    }
    
    if (scalar(keys %{$self->{trunk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No trunk found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "audiocodes_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check trunk status.

=over 8

=item B<--filter-name>

Filter by name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{alarm}, %{dchannel}, %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /activated/ and %{alarm} !~ /greenActive/i').
Can used special variables like: %{display}, %{alarm}, %{dchannel}, %{state}

=item B<--warning-*>

Threshold warning.
Can be: 'avg-calls', 'max-calls', 'count-calls'.

=item B<--critical-*>

Threshold critical.
Can be: 'avg-calls', 'max-calls', 'count-calls'.


=back

=cut
