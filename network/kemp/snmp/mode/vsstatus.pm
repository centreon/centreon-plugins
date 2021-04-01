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

package network::kemp::snmp::mode::vsstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vs', type => 1, cb_prefix_output => 'prefix_vs_output', message_multiple => 'All virtual servers are ok' }
    ];
    
    $self->{maps_counters}->{vs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'active', set => {
                key_values => [ { name => 'vSActivConns' }, { name => 'display' } ],
                output_template => 'Active connections : %s',
                perfdatas => [
                    { label => 'active', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'in-traffic', set => {
                key_values => [ { name => 'vSInBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'out-traffic', set => {
                key_values => [ { name => 'vSOutBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',  min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
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
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /inService|disabled|redirect/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_vs_output {
    my ($self, %options) = @_;
    
    return "Virtual server '" . $options{instance_value}->{display} . "' ";
}

my %map_state = (
    1 => 'inService',
    2 => 'outOfService',
    4 => 'disabled',
    5 => 'sorry',
    6 => 'redirect',
    7 => 'errormsg',
);
my $mapping = {
    vSname          => { oid => '.1.3.6.1.4.1.12196.13.1.1.13' },
    vSstate         => { oid => '.1.3.6.1.4.1.12196.13.1.1.14', map => \%map_state },
    vSInBytes       => { oid => '.1.3.6.1.4.1.12196.13.1.1.19' },
    vSOutBytes      => { oid => '.1.3.6.1.4.1.12196.13.1.1.20' },
    vSActivConns    => { oid => '.1.3.6.1.4.1.12196.13.1.1.21' },
};

my $oid_vsEntry = '.1.3.6.1.4.1.12196.13.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vs} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_vsEntry,
                                                nothing_quit => 1);


    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vSstate}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vSname} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{vSname} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vs}->{$instance} = { display => $result->{vSname}, 
                                     status => $result->{vSstate}, 
                                     vSInBytes => defined($result->{vSInBytes}) ? $result->{vSInBytes} * 8 : undef, 
                                     vSOutBytes => defined($result->{vSOutBytes}) ? $result->{vSOutBytes} * 8 : undef, 
                                     vSActivConns => $result->{vSActivConns} };
    }
    
    if (scalar(keys %{$self->{vs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual server found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "kemp_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual server status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter virtual server name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /inService|disabled|redirect/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'active', 'in-traffic' (b/s), 'out-traffic' (b/s).

=item B<--critical-*>

Threshold critical.
Can be: 'active', 'in-traffic' (b/s), 'out-traffic' (b/s).

=back

=cut
