#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package hardware::server::cisco::ucs::redfish::mode::networkinterfaces;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ports',  type => 1, cb_prefix_output => 'prefix_output',
          message_multiple => 'All network ports are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total',   nlabel => 'networkports.total.count',   set => {
            key_values      => [ { name => 'total' } ],
            output_template => 'Total ports: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'up',      nlabel => 'networkports.up.count',      set => {
            key_values      => [ { name => 'up' } ],
            output_template => 'Up: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'down',    nlabel => 'networkports.down.count',    set => {
            key_values      => [ { name => 'down' } ],
            output_template => 'Down: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
        { label => 'nolink',  nlabel => 'networkports.nolink.count',  set => {
            key_values      => [ { name => 'nolink' } ],
            output_template => 'No link: %d',
            perfdatas       => [ { template => '%d', min => 0 } ],
        }},
    ];

    $self->{maps_counters}->{ports} = [
        { label => 'status', type => 2,
          set => {
            key_values => [
                { name => 'display' }, { name => 'link_status' },
                { name => 'speed_mbps' }, { name => 'system' }, { name => 'mac' },
            ],
            output_template => "port '%s' [system: %s] [speed: %s Mbps] link status is '%s'",
            output_use      => ['display', 'system', 'speed_mbps', 'link_status'],
            closure_custom_perfdata        => sub { return 0; },
            closure_custom_threshold_check => \&_threshold_check,
          }
        },
    ];
}

sub _threshold_check {
    my ($self, %options) = @_;
    my $link = $self->{result_values}->{link_status};

    if (defined($self->{instance_mode}->{option_results}->{critical_status})
        && $self->{instance_mode}->{option_results}->{critical_status} ne ''
        && $link =~ /$self->{instance_mode}->{option_results}->{critical_status}/) {
        return 'CRITICAL';
    }
    if (defined($self->{instance_mode}->{option_results}->{warning_status})
        && $self->{instance_mode}->{option_results}->{warning_status} ne ''
        && $link =~ /$self->{instance_mode}->{option_results}->{warning_status}/) {
        return 'WARNING';
    }
    return 'OK';
}

sub prefix_output {
    my ($self, %options) = @_;
    return "Port '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-port:s'      => { name => 'filter_port' },
        'filter-system:s'    => { name => 'filter_system' },
        'warning-status:s'   => { name => 'warning_status',  default => '' },
        'critical-status:s'  => { name => 'critical_status', default => '^(?!Up)' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $api_path = $options{custom}->{api_path};

    $self->{global} = { total => 0, up => 0, down => 0, nolink => 0 };
    $self->{ports}  = {};

    my $systems = $options{custom}->get_collection(endpoint => '/Systems');

    for my $system (@{$systems}) {
        my $system_id = $system->{'Id'} // 'unknown';

        next if defined($self->{option_results}->{filter_system})
            && $self->{option_results}->{filter_system} ne ''
            && $system_id !~ /$self->{option_results}->{filter_system}/;

        my $ni_url = $system->{NetworkInterfaces}->{'@odata.id'} // '';
        next if $ni_url eq '';
        $ni_url =~ s{^\Q$api_path\E}{};

        my $ni_collection = $options{custom}->get_collection(endpoint => $ni_url);

        for my $ni (@{$ni_collection}) {
            my $ni_id = $ni->{'Id'} // 'unknown';

            # Navigate to NetworkPorts
            my $ports_url = '';
            if (defined($ni->{Links}->{NetworkPorts})) {
                $ports_url = $ni->{Links}->{NetworkPorts}->{'@odata.id'} // '';
            } elsif (defined($ni->{NetworkPorts})) {
                $ports_url = $ni->{NetworkPorts}->{'@odata.id'} // '';
            }

            if ($ports_url ne '') {
                $ports_url =~ s{^\Q$api_path\E}{};
                my $port_collection = $options{custom}->get_collection(endpoint => $ports_url);

                for my $port (@{$port_collection}) {
                    my $port_id   = $port->{'Id'}                    // 'unknown';
                    my $link_stat = $port->{'LinkStatus'}             // 'NoLink';
                    my $speed     = $port->{'CurrentLinkSpeedMbps'}   // 0;
                    my @macs      = @{$port->{'AssociatedNetworkAddresses'} // []};
                    my $mac       = join(',', @macs);

                    my $display = "${system_id}/${ni_id}/${port_id}";

                    next if defined($self->{option_results}->{filter_port})
                        && $self->{option_results}->{filter_port} ne ''
                        && $display !~ /$self->{option_results}->{filter_port}/;

                    $self->{global}->{total}++;
                    if    ($link_stat =~ /^Up$/i)     { $self->{global}->{up}++; }
                    elsif ($link_stat =~ /^Down$/i)   { $self->{global}->{down}++; }
                    else                              { $self->{global}->{nolink}++; }

                    $self->{ports}->{$display} = {
                        display     => $display,
                        link_status => $link_stat,
                        speed_mbps  => $speed,
                        system      => $system_id,
                        mac         => $mac,
                    };
                }
            }
        }
    }

    if (scalar(keys %{$self->{ports}}) == 0) {
        $self->{output}->add_option_msg(
            short_msg => 'No network ports found (check --filter-system or NetworkInterfaces availability).'
        );
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Cisco UCS network port status via Redfish API (Systems/NetworkInterfaces/NetworkPorts).

=over 8

=item B<--filter-port>

Filter ports by display name (regexp). Format is system/nic/port.
Example: --filter-port='Server1/NIC1'

=item B<--filter-system>

Filter by system ID (regexp). Example: --filter-system='FCH'

=item B<--warning-status>

Warning threshold on link status (regexp). Example: --warning-status='^Down$'

=item B<--critical-status>

Critical threshold on link status (regexp). Default: '^(?!Up)' (anything not 'Up').

=back

=cut
