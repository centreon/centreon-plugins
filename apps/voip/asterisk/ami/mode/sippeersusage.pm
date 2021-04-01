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

package apps::voip::asterisk::ami::mode::sippeersusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf('status : %s', $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sip', type => 1, cb_prefix_output => 'prefix_sip_output', message_multiple => 'All SIP peers are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-peers', set => {
                key_values => [ { name => 'total_peers' } ],
                output_template => 'Total Peers: %s',
                perfdatas => [
                    { label => 'total_peers', value => 'total_peers', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'monitor-online-peers', set => {
                key_values => [ { name => 'monitor_online_peers' } ],
                output_template => 'Monitor Online Peers: %s',
                perfdatas => [
                    { label => 'monitor_online_peers', value => 'monitor_online_peers', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'monitor-offline-peers', set => {
                key_values => [ { name => 'monitor_offline_peers' } ],
                output_template => 'Monitor Offline Peers: %s',
                perfdatas => [
                    { label => 'monitor_offline_peers', value => 'monitor_offline_peers', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'unmonitor-online-peers', set => {
                key_values => [ { name => 'unmonitor_online_peers' } ],
                output_template => 'Unmonitor Online Peers: %s',
                perfdatas => [
                    { label => 'unmonitor_online_peers', value => 'unmonitor_online_peers', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'unmonitor-offline-peers', set => {
                key_values => [ { name => 'unmonitor_offline_peers' } ],
                output_template => 'Unmonitor Offline Peers: %s',
                perfdatas => [
                    { label => 'unmonitor_offline_peers', value => 'unmonitor_offline_peers', template => '%s', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{sip} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'name' }, { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '%{status} =~ /LAGGED|UNKNOWN/i' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{status} =~ /UNREACHABLE/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_sip_output {
    my ($self, %options) = @_;
    
    return "Peer '" . $options{instance_value}->{name} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    # Status can be: UNREACHABLE, LAGGED (%d ms), OK (%d ms), UNKNOWN, Unmonitored
    
    #Name/username             Host                                    Dyn Forcerport Comedia    ACL Port     Status      Description                      
    #02l44k/02l44k             10.9.0.61                                D  No         No             5060     Unmonitored                                  
    #0rafkw/0rafkw             10.9.0.28                                D  No         No             5060     Unmonitored  
    #...
    #55 sip peers [Monitored: 0 online, 0 offline Unmonitored: 43 online, 12 offline]
    my $result = $options{custom}->command(cmd => 'sip show peers');
    
    $self->{sip} = {};
    foreach my $line (split /\n/, $result) {
        if ($line =~ /^(.*?)\s+.*(UNREACHABLE|LAGGED|OK|UNKNOWN|Unmonitored)\s/msg) {
            my ($name, $status) = ($1, $2);
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $name !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{sip}->{$name} = {
                name => $name,
                status => $status,
            };
        }
    }
    
    $self->{global} = {
        total_peers =>  $1,
        monitor_online_peers => $2, monitor_offline_peers => $3,
        unmonitor_online_peers => $4, unmonitor_offline_peers => $5,
    } if ($result =~ /(\d+) sip peers \[Monitored: (\d+) online, (\d+) offline Unmonitored: (\d+) online, (\d+) offline]/msi);

    if (scalar(keys %{$self->{sip}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No sip peers found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check SIP peers usage.

=over 8

=item B<--filter-name>

Filter sip peer name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /LAGGED|UNKNOWN/i').
Can used special variables like: %{name}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /UNREACHABLE/i').
Can used special variables like: %{name}, %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'total-peers', 'monitor-online-peers', 'monitor-offline-peers', 
'unmonitor-online-peers', 'unmonitor-offline-peers'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-peers', 'monitor-online-peers', 'monitor-offline-peers', 
'unmonitor-online-peers', 'unmonitor-offline-peers'.

=back

=cut
