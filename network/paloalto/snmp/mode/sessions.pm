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

package network::paloalto::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'active', set => {
                key_values => [ { name => 'panSessionActive' }, { name => 'panSessionMax' } ],
                closure_custom_calc => $self->can('custom_active_calc'),
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_perfdata => $self->can('custom_active_perfdata'),
                closure_custom_threshold_check => $self->can('custom_active_threshold'),
               
            }
        },
        { label => 'active-ssl-proxy', set => {
                key_values => [ { name => 'panSessionSslProxyUtilization' } ],
                output_template => 'Active SSL Proxy : %.2f %%',
                perfdatas => [
                    { label => 'active_ssl_proxy', value => 'panSessionSslProxyUtilization_absolute', template => '%.2f', unit => '%',
                      min => 0, max => 100 },
                ],
            }
        },
        { label => 'active-tcp', set => {
                key_values => [ { name => 'panSessionActiveTcp' } ],
                output_template => 'Active TCP : %s',
                perfdatas => [
                    { label => 'active_tcp', value => 'panSessionActiveTcp_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'active-udp', set => {
                key_values => [ { name => 'panSessionActiveUdp' } ],
                output_template => 'Active UDP : %s',
                perfdatas => [
                    { label => 'active_udp', value => 'panSessionActiveUdp_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'active-icmp', set => {
                key_values => [ { name => 'panSessionActiveICMP' } ],
                output_template => 'Active ICMP : %s',
                perfdatas => [
                    { label => 'active_icmp', value => 'panSessionActiveICMP_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Sessions ";
}

sub custom_active_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'active';
    my %total_options = ();
    if ($self->{result_values}->{panSessionMax} != 0) {
        $total_options{total} = $self->{result_values}->{panSessionMax};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label,
                                  value => $self->{result_values}->{panSessionActive},
                                  warning => defined($total_options{total}) ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options) : undef,
                                  critical => defined($total_options{total}) ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options) : undef,
                                  min => 0, max => $self->{result_values}->{panSessionMax});
}

sub custom_active_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value) = ('ok');
    if ($self->{result_values}->{panSessionMax} != 0) {
        $threshold_value = $self->{result_values}->{active_prct};
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => 
        [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]) if (defined($threshold_value));
    return $exit;
}

sub custom_active_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Active : %s (%s)",
                      $self->{result_values}->{panSessionActive},
                      $self->{result_values}->{panSessionMax} != 0 ? $self->{result_values}->{active_prct} . " %" : 
                      '-');
    return $msg;
}

sub custom_active_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{panSessionActive} = $options{new_datas}->{$self->{instance} . '_panSessionActive'};
    $self->{result_values}->{panSessionMax} = $options{new_datas}->{$self->{instance} . '_panSessionMax'};
    $self->{result_values}->{active_prct} = 0;
    if ($self->{result_values}->{panSessionMax} != 0) {
        $self->{result_values}->{active_prct} = $self->{result_values}->{panSessionActive} * 100 / $self->{result_values}->{panSessionMax};
    }
    return 0;
}

my $mapping = {
    panSessionMax                   => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.2' },
    panSessionActive                => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.3' },
    panSessionActiveTcp             => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.4' },
    panSessionActiveUdp             => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.5' },
    panSessionActiveICMP            => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.6' },
    #panSessionActiveSslProxy        => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.7' }, Cannot get the max if 0...
    panSessionSslProxyUtilization   => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.8' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_panSession = '.1.3.6.1.4.1.25461.2.1.2.3';
    $self->{results} = $options{snmp}->get_table(oid => $oid_panSession,
                                                nothing_quit => 1);
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => '0');
    $self->{global}->{panSessionMax} = 0 if (!defined($self->{global}->{panSessionMax}));
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'active' (%), 'active-tcp', 'active-udp', 'active-icmp', 'active-ssl-proxy' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'active' (%), 'active-tcp', 'active-udp', 'active-icmp', 'active-ssl-proxy' (%).

=back

=cut
