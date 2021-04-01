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

package network::paloalto::snmp::mode::gpusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_tunnel_output {
    my ($self, %options) = @_;

    return sprintf(
        'tunnels total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $self->{result_values}->{total},
        $self->{result_values}->{used},
        $self->{result_values}->{prct_used},
        $self->{result_values}->{free},
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'tunnel', type => 0 }
    ];
    
    $self->{maps_counters}->{tunnel} = [
        { label => 'tunnels-usage', nlabel => 'globalprotect.tunnels.usage.count', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_tunnel_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'tunnels-usage-free', display_ok => 0, nlabel => 'globalprotect.tunnels.free.count', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_tunnel_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', cast_int => 1 }
                ]
            }
        },
        { label => 'tunnels-usage-prct', display_ok => 0, nlabel => 'globalprotect.tunnels.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_tunnel_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
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

    my $oid_panGPGWUtilizationMaxTunnels = '.1.3.6.1.4.1.25461.2.1.2.5.1.2.0';
    my $oid_panGPGWUtilizationActiveTunnels = '.1.3.6.1.4.1.25461.2.1.2.5.1.3.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_panGPGWUtilizationMaxTunnels, $oid_panGPGWUtilizationActiveTunnels],
        nothing_quit => 1
    );

    my ($used, $total) = ($snmp_result->{$oid_panGPGWUtilizationActiveTunnels}, $snmp_result->{$oid_panGPGWUtilizationMaxTunnels});

    $self->{tunnel} = {
        free => $total - $used,
        used => $used,
        prct_used => $used * 100 / $total,
        prct_free => 100 - ($used * 100 / $total),
        total => $total
    };
}

1;

__END__

=head1 MODE

Check global protect usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tunnels-usage', 'tunnels-usage-free', 'tunnels-usage-prct' (%).

=back

=cut
