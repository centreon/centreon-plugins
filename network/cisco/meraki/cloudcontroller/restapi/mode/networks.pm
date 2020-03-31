#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::meraki::cloudcontroller::restapi::mode::networks;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'networks', type => 1, cb_prefix_output => 'prefix_network_output', message_multiple => 'All networks are ok' }
    ];

    $self->{maps_counters}->{networks} = [
        { label => 'connections-success', nlabel => 'network.connections.success.count', set => {
                key_values => [ { name => 'assoc' }, { name => 'display' } ],
                output_template => 'connections success: %s',
                perfdatas => [
                    { value => 'assoc_absolute',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' }
                ]
            }
        },
        { label => 'connections-auth', nlabel => 'network.connections.auth.count', display_ok => 0, set => {
                key_values => [ { name => 'auth' }, { name => 'display' } ],
                output_template => 'connections auth: %s',
                perfdatas => [
                    { value => 'auth_absolute',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' }
                ]
            }
        },
        { label => 'connections-assoc', nlabel => 'network.connections.assoc.count', display_ok => 0, set => {
                key_values => [ { name => 'assoc' }, { name => 'display' } ],
                output_template => 'connections assoc: %s',
                perfdatas => [
                    { value => 'assoc_absolute',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' }
                ]
            }
        },
        { label => 'connections-dhcp', nlabel => 'network.connections.dhcp.count', display_ok => 0, set => {
                key_values => [ { name => 'dhcp' }, { name => 'display' } ],
                output_template => 'connections dhcp: %s',
                perfdatas => [
                    { value => 'dhcp_absolute',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' }
                ]
            }
        },
        { label => 'connections-dns', nlabel => 'network.connections.dns.count', display_ok => 0, set => {
                key_values => [ { name => 'dns' }, { name => 'display' } ],
                output_template => 'connections dns: %s',
                perfdatas => [
                    { value => 'dns_absolute',
                      template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display_absolute' }
                ]
            }
        }
    ];
}

sub prefix_network_output {
    my ($self, %options) = @_;
    
    return "Network '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'meraki_' . $self->{mode} . '_' . $options{custom}->get_token()  . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
    my $last_timestamp = $self->read_statefile_key(key => 'last_timestamp');
    my $timespan = 300;
    $timespan = time() - $last_timestamp if (defined($last_timestamp));

    my $cache_networks = $options{custom}->get_cache_networks();
    my $connections = $options{custom}->get_networks_connection_stats(timespan => $timespan, filter_name => $self->{option_results}->{filter_name});
    my $clients = $options{custom}->get_networks_clients(timespan => $timespan, filter_name => $self->{option_results}->{filter_name});

    $self->{networks} = {};
    foreach my $id (keys %$connections) {
        $self->{networks}->{$id} = {
            display => $cache_networks->{$id}->{name},
            assoc => defined($connections->{$id}->{assoc}) ? $connections->{$id}->{assoc} : 0,
            auth => defined($connections->{$id}->{assoc}) ? $connections->{$id}->{auth} : 0,
            dhcp => defined($connections->{$id}->{assoc}) ? $connections->{$id}->{assoc} : 0,
            dns => defined($connections->{$id}->{assoc}) ? $connections->{$id}->{dhcp} : 0,
            success => defined($connections->{$id}->{assoc}) ? $connections->{$id}->{success} : 0
        };
        
    }

    if (scalar(keys %{$self->{networks}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No networks found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check networks.

=over 8

=item B<--filter-name>

Filter network name (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'volume-data-read-bytespersecond', 'volume-data-written-bytespersecond',
'volume-reads-count', 'volume-writes-count',
'volume-data-transfer-bytespersecond', 'volume-iops-ops',
'volume-cache-write-usage-percentage', 'volume-cache-write-hits-count',
'volume-cache-write-misses-count', 'volume-cache-read-hits-count',
'volume-cache-read-misses-count'.

=back

=cut
