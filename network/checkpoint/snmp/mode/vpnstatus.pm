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

package network::checkpoint::snmp::mode::vpnstatus;

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
    
    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vpn', type => 1, cb_prefix_output => 'prefix_vpn_output', message_multiple => 'All vpn are ok' }
    ];
    
    $self->{maps_counters}->{vpn} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'type' }, { name => 'status' }, { name => 'display' } ],
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
                                  "filter-name:s"           => { name => 'filter_name' },
                                  "warning-status:s"        => { name => 'warning_status', default => '' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{type} eq "permanent" and %{status} =~ /down/i' },
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
    
    return "VPN '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %map_type = (1 => 'regular', 2 => 'permanent');
my %map_state = (3 => 'active', 4 => 'destroy', 129 => 'idle', 130 => 'phase1',
    131 => 'down', 132 => 'init'
);

my $mapping = {
    tunnelPeerObjName   => { oid => '.1.3.6.1.4.1.2620.500.9002.1.2' },
    tunnelState         => { oid => '.1.3.6.1.4.1.2620.500.9002.1.3', map => \%map_state },
    tunnelType          => { oid => '.1.3.6.1.4.1.2620.500.9002.1.11', map => \%map_type },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vs} = {};
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $mapping->{tunnelPeerObjName}->{oid} },
            { oid => $mapping->{tunnelState}->{oid} },
            { oid => $mapping->{tunnelType}->{oid} },
        ], nothing_quit => 1, return_type => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{tunnelState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{tunnelPeerObjName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{tunnelPeerObjName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vpn}->{$instance} = { display => $result->{tunnelPeerObjName}, 
                                      status => $result->{tunnelState},
                                      type => $result->{tunnelType} };
    }
    
    if (scalar(keys %{$self->{vpn}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No vpn found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check vpn status.

=over 8

=item B<--filter-name>

Filter vpn name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{type}, %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{type} eq "permanent" and %{status} =~ /down/i').
Can used special variables like: %{type}, %{status}, %{display}

=back

=cut
