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

package cloud::cadvisor::restapi::mode::traffic;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use DateTime;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'containers_traffic', type => 1, cb_prefix_output => 'prefix_containers_traffic_output', message_multiple => 'All container traffics are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{containers_traffic} = [
        { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in' }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In: %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', value => 'traffic_in_absolute', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out' }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out: %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', value => 'traffic_out_absolute', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "container-id:s"              => { name => 'container_id' },
        "container-name:s"            => { name => 'container_name' },
        "filter-name:s"               => { name => 'filter_name' },
        "use-name"                    => { name => 'use_name' },
    });
   
    return $self;
}

sub prefix_containers_traffic_output {
    my ($self, %options) = @_;
    
    return "Container '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{containers} = {};
    $self->{containers_traffic} = {};
    $self->{containers_diskio} = {};
    my $result = $options{custom}->api_get_containers(
        container_id => $self->{option_results}->{container_id}, 
        container_name => $self->{option_results}->{container_name}
    );
    my $machine_stats = $options{custom}->api_get_machine_stats();

    foreach my $container_id (keys %{$result}) {
        next if (!defined($result->{$container_id}->{Stats})); 
        my $name = $result->{$container_id}->{Name};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        my $first_index = 0;
        my $first_stat = $result->{$container_id}->{Stats}[$first_index];
        my $first_ts = $first_stat->{timestamp};
        my $first_dt = $self->parse_date(date => $first_ts);

        my $last_index = scalar @{$result->{$container_id}->{Stats}} - 1;
        my $last_stat = $result->{$container_id}->{Stats}[$last_index];
        my $last_ts = $last_stat->{timestamp};
        my $last_dt = $self->parse_date(date => $last_ts);

        my $diff_ts = $last_dt - $first_dt;

        $self->{containers}->{$container_id} = {
            node_name           => $result->{$container_id}->{NodeName},
            display             => defined($self->{option_results}->{use_name}) ? $name : $container_id,
            name                => $name,
        };

        my $name = defined($self->{option_results}->{use_name}) ? $name : $container_id;
        if (defined($first_stat->{network}->{interfaces})) {
            foreach my $interface_index (0..(scalar(@{$first_stat->{network}->{interfaces}}) - 1)) {
                $self->{containers_traffic}->{$name} = {
                    display => $name . '.' . $first_stat->{network}->{interfaces}->[$interface_index]->{name},
                    traffic_in => ($last_stat->{network}->{interfaces}->[$interface_index]->{rx_packets} - $first_stat->{network}->{interfaces}->[$interface_index]->{rx_packets}) / $diff_ts * 8,
                    traffic_out => ($last_stat->{network}->{interfaces}->[$interface_index]->{tx_packets} - $first_stat->{network}->{interfaces}->[$interface_index]->{tx_packets}) / $diff_ts * 8,
                };
            }
        } elsif (defined($first_stat->{network}->{rx_packets})) {
            $self->{containers_traffic}->{$name} = {
                display => $name . '.default',
                traffic_in => ($last_stat->{network}->{rx_packets} - $first_stat->{network}->{rx_packets}) / $diff_ts * 8,
                traffic_out => ($last_stat->{network}->{tx_packets} - $first_stat->{network}->{tx_packets}) / $diff_ts * 8,
            };
        }
    }
    
    if (scalar(keys %{$self->{containers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No containers found.");
        $self->{output}->option_exit();
    }
    
    my $hostnames = $options{custom}->get_hostnames();
}

sub parse_date {
    my ($self, %options) = @_;

    if ($options{date} !~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\.(\d*)([^\d]+)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong time found '" . $options{date} . "'.");
        $self->{output}->option_exit();
    }
    my $dt = DateTime->new(
        year => $1, month => $2, day => $3, 
        hour => $4, minute => $5, second => $6, 
        time_zone => $8
    );
    # return epoch time with nanoseconds
    return $dt->epoch.".".$7;
}

1;

__END__

=head1 MODE

Check container traffic usage.

=over 8

=item B<--container-id>

Exact container ID.

=item B<--container-name>

Exact container name (if multiple names: names separated by ':').

=item B<--use-name>

Use docker name for perfdata and display.

=item B<--filter-name>

Filter by container name (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^traffic-in$'

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out'.

=back

=cut
