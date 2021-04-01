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

package apps::bluemind::local::mode::ips;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_ips_output {
    my ($self, %options) = @_;
    
    return 'IMAP operations tracking ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'bm_ips', type => 0, cb_prefix_output => 'prefix_ips_output' }
    ];
    
    $self->{maps_counters}->{bm_ips} = [
        { label => 'connections-active', nlabel => 'ips.connections.active.count', set => {
                key_values => [ { name => 'active_connections' } ],
                output_template => 'active connections: %s',
                perfdatas => [
                    { value => 'active_connections', template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # bm-ips.activeConnections,meterType=Gauge value=718
    my $result = $options{custom}->execute_command(
        command => 'curl --unix-socket /var/run/bm-metrics/metrics-bm-ips.sock http://127.0.0.1/metrics',
        filter => 'activeConnections'
    );

    $self->{bm_ips} = {};
    foreach (keys %$result) {
        $self->{bm_ips}->{active_connections} = $result->{$_}->{value} if (/bm-ips\.activeConnections/);
    }
}

1;

__END__

=head1 MODE

Check IMAP operations tracking.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'active-connections'.

=back

=cut
