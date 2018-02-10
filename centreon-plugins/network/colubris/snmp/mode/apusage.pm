#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package network::colubris::snmp::mode::apusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        if (defined($instance_mode->{option_results}->{critical_ap_status}) && $instance_mode->{option_results}->{critical_ap_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_ap_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_ap_status}) && $instance_mode->{option_results}->{warning_ap_status} ne '' &&
                 eval "$instance_mode->{option_results}->{warning_ap_status}") {
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

    my $msg = 'Operational State : ' . $self->{result_values}->{state};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All access points are OK' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total-ap', set => {
                key_values => [ { name => 'total_ap' } ],
                output_template => 'Total AP : %s',
                perfdatas => [
                    { label => 'total_ap', value => 'total_ap_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'total-users', set => {
                key_values => [ { name => 'total_users' } ],
                output_template => 'Total Users : %s',
                perfdatas => [
                    { label => 'total_users', value => 'total_users_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{ap} = [
        { label => 'ap-status', threshold => 0,  set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
        { label => 'ap-users', set => {
                key_values => [ { name => 'users' }, { name => 'display' } ],
                output_template => 'Current Users: %s',
                perfdatas => [
                    { label => 'ap_users', value => 'users_absolute', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "AP '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-name:s"         => { name => 'filter_name' },
                                "warning-ap-status:s"   => { name => 'warning_ap_status', default => '' },
                                "critical-ap-status:s"  => { name => 'critical_ap_status', default => '%{state} eq "disconnected"' },
                                });
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_ap_status', 'critical_ap_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros();
    $instance_mode = $self;
}

my %map_device_state = (
    1 => 'disconnected', 2 => 'authorized', 3 => 'join', 4 => 'firmware',
    5 => 'security', 6 => 'configuration', 7 => 'running'
);

my $mapping = {
    coDevDisState       => { oid => '.1.3.6.1.4.1.8744.5.23.1.2.1.1.5', map => \%map_device_state },
    coDevDisSystemName  => { oid => '.1.3.6.1.4.1.8744.5.23.1.2.1.1.6' },
};

my $mapping2 = {
    coDevWirCliStaMACAddress    => { oid => '.1.3.6.1.4.1.8744.5.25.1.7.1.1.2' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "colubris_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
    
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
            { oid => $mapping->{coDevDisState}->{oid} },
            { oid => $mapping->{coDevDisSystemName}->{oid} },
            { oid => $mapping2->{coDevWirCliStaMACAddress}->{oid} },
        ], nothing_quit => 1, return_type => 1);

    $self->{ap} = {};
    $self->{global} = { total_ap => 0, total_users => 0 };
    foreach my $oid (sort keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{coDevDisSystemName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{coDevDisSystemName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{coDevDisSystemName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{global}->{total_ap}++;
        $self->{ap}->{$instance} = {
            display => $result->{coDevDisSystemName},
            state => $result->{coDevDisState},
            users => 0,
        };
    }
    
    foreach my $oid (sort keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping2->{coDevWirCliStaMACAddress}->{oid}\.(.*?)\./);
        my $instance = $1;
        
        next if (!defined($self->{ap}->{$instance}));
        
        $self->{global}->{total_users}++;
        $self->{ap}->{$instance}->{users}++;
    }
    
    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No access point found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP status and users connected.

=over 8

=item B<--filter-name>

Filter ap name with regexp.

=item B<--warning-*>

Threshold warning.
Can be: 'total-ap', 'total-users', 'ap-users'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-ap', 'total-users', 'ap-users'.

=item B<--warning-ap-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{display}

=item B<--critical-ap-status>

Set critical threshold for status (Default: '%{state} eq "disconnected"').
Can used special variables like: %{state}, %{display}

=back

=cut
