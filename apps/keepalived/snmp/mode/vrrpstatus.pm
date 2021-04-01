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

package apps::keepalived::snmp::mode::vrrpstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("state : %s [last state : %s, wanted state : '%s']", 
        $self->{result_values}->{instanceState}, $self->{result_values}->{instanceStateLast}, $self->{result_values}->{instanceWantedState});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{instanceWantedState} = $options{new_datas}->{$self->{instance} . '_instance_wanted_state'};
    $self->{result_values}->{instanceStateLast} = $options{old_datas}->{$self->{instance} . '_instance_state'};
    $self->{result_values}->{instanceState} = $options{new_datas}->{$self->{instance} . '_instance_state'};
    $self->{result_values}->{instancePrimaryInterface} = $options{new_datas}->{$self->{instance} . '_instance_primary_interface'};
    if (!defined($options{old_datas}->{$self->{instance} . '_instance_state'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vrrp', type => 1, cb_prefix_output => 'prefix_vrrp_output', message_multiple => 'All VRRP instances are ok' },
    ];
    
    $self->{maps_counters}->{vrrp} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'instance_primary_interface' }, { name => 'instance_wanted_state' }, { name => 'instance_state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_vrrp_output {
    my ($self, %options) = @_;

    return "VRRP '" . $options{instance_value}->{instance_primary_interface} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{instanceState} ne %{instanceWantedState} or %{instanceState} ne %{instanceStateLast}' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_instance_state = (0 => 'init', 1 => 'backup', 2 => 'master', 3 => 'fault', 4 => 'unknown');
my %map_instance_wanted_state = (0 => 'init', 1 => 'backup', 2 => 'master', 3 => 'fault', 4 => 'unknown');
my $mapping = {
    vrrpInstanceState            => { oid => '.1.3.6.1.4.1.9586.100.5.2.3.1.4', map => \%map_instance_state },
    vrrpInstanceWantedState      => { oid => '.1.3.6.1.4.1.9586.100.5.2.3.1.6', map => \%map_instance_wanted_state },
    vrrpInstancePrimaryInterface => { oid => '.1.3.6.1.4.1.9586.100.5.2.3.1.10' },
};

my $oid_vrrpInstanceEntry = '.1.3.6.1.4.1.9586.100.5.2.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vrrp} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_vrrpInstanceEntry,
        end => $mapping->{vrrpInstancePrimaryInterface}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vrrpInstanceState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        $self->{vrrp}->{$instance} = { 
            instance_primary_interface => $result->{vrrpInstancePrimaryInterface},
            instance_wanted_state => $result->{vrrpInstanceWantedState},
            instance_state => $result->{vrrpInstanceState},
        };
    }
    
    $self->{cache_name} = "keepalived_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check VRRP instances status.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{instanceWantedState}, %{instanceStateLast}, %{instanceState}, %{instancePrimaryInterface}

=item B<--critical-status>

Set critical threshold for status (Default: '%{instanceState} ne %{instanceWantedState} or %{instanceState} ne %{instanceStateLast}').
Can used special variables like: %{instanceWantedState}, %{instanceStateLast}, %{instanceState}, %{instancePrimaryInterface}

=back

=cut
