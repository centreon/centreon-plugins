#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

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
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{state} =~ /activated/ and %{alarm} !~ /greenActive/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_vpn_output {
    my ($self, %options) = @_;
    
    return "Trunk '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_alarm = (0 => 'greyDisabled', 1 => 'greenActive', 2 => 'redLosLof', 
3 => 'blueAis', 4 => 'yellowRai', 5 => 'orangeDChannel', 6 => 'purpleLowerLayerDown', 7 => 'darkOrangeNFASAlarm');
my %map_dchannel = (0 => 'dChannelEstablished', 1 => 'dChannelNotEstablished', 10 => 'dChannelNotApplicable');
my %map_deactivate = (0 => 'notAvailable', 1 => 'deActivated', 2 => 'activated');

my $mapping = {
    acTrunkStatusDChannel   => { oid => '.1.3.6.1.4.1.5003.9.10.9.2.1.1.1.6', map => \%map_dchannel },
    acTrunkStatusAlarm      => { oid => '.1.3.6.1.4.1.5003.9.10.9.2.1.1.1.7', map => \%map_alarm },
    acTrunkDeactivate       => { oid => '.1.3.6.1.4.1.5003.9.10.9.1.1.1.1.1.11', map => \%map_deactivate },
    acTrunkName             => { oid => '.1.3.6.1.4.1.5003.9.10.9.1.1.1.1.1.13' },
};
my $oid_acTrunkStatusEntry = '.1.3.6.1.4.1.5003.9.10.9.2.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{trunk} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $mapping->{acTrunkName}->{oid} },
            { oid => $mapping->{acTrunkDeactivate}->{oid} },
            { oid => $oid_acTrunkStatusEntry },
        ], nothing_quit => 1, return_type => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{acTrunkStatusAlarm}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{trunk}->{$instance} = { 
            display => defined($result->{acTrunkName}) && $result->{acTrunkName} ne '' ? $result->{acTrunkName} : $instance, 
            alarm => $result->{acTrunkStatusAlarm},
            state => $result->{acTrunkDeactivate},
            dchannel => $result->{acTrunkStatusDChannel} };
    }
    
    if (scalar(keys %{$self->{trunk}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No trunk found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check vpn status.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{alarm}, %{dchannel}, %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} =~ /activated/ and %{alarm} !~ /greenActive/i').
Can used special variables like: %{display}, %{alarm}, %{dchannel}, %{state}

=back

=cut
