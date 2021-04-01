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

package apps::centreon::map::jmx::mode::brokerstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Packets Delta: %d [%d/%d]",
        $self->{result_values}->{diff_packets},
        $self->{result_values}->{processed_packets},
        $self->{result_values}->{received_packets});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{received_packets} = $options{new_datas}->{$self->{instance} . '_ReceivedPackets'};
    $self->{result_values}->{processed_packets} = $options{new_datas}->{$self->{instance} . '_ProcessedPackets'};
    $self->{result_values}->{diff_packets} = $self->{result_values}->{received_packets} - $self->{result_values}->{processed_packets};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'ReceivedPackets', diff => 1 }, { name => 'ProcessedPackets', diff => 1 } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'received-packets-rate', set => {
                key_values => [ { name => 'ReceivedPackets', per_second => 1 } ],
                output_template => 'Received Packets: %.2f/s',
                perfdatas => [
                    { label => 'received_packets_rate', template => '%.2f',
                      min => 0, unit => 'packets/s' }
                ]
            }
        },
        { label => 'processed-packets-rate', set => {
                key_values => [ { name => 'ProcessedPackets', per_second => 1 } ],
                output_template => 'Processed Packets: %.2f/s',
                perfdatas => [
                    { label => 'processed_packets_rate', template => '%.2f',
                      min => 0, unit => 'packets/s' },
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
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{processed_packets} < %{received_packets}' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $mbean_broker = "com.centreon.studio.map:type=broker,name=statistics";

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "centreon_map_" . md5_hex($options{custom}->{url}) . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{request} = [
        { mbean => $mbean_broker }
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 0);

    $self->{global} = {};

    $self->{global} = {
        ReceivedPackets => $result->{$mbean_broker}->{ReceivedPackets},
        ProcessedPackets => $result->{$mbean_broker}->{ProcessedPackets},
    };
}

1;

__END__

=head1 MODE

Check broker packets rate received and processed.

Example:

perl centreon_plugins.pl --plugin=apps::centreon::map::jmx::plugin --custommode=jolokia
--url=http://10.30.2.22:8080/jolokia-war --mode=broker-stats

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='session')

=item B<--warning-status>

Set warning threshold for status. (Default: '').
Can use special variables like: %{processed_packets}, %{received_packets}, %{diff_packets}.

=item B<--critical-status>

Set critical threshold for status. (Default: '%{processed_packets} < %{received_packets}').
Can use special variables like: %{processed_packets}, %{received_packets}, %{diff_packets}.

=item B<--warning-*>

Threshold warning.
Can be: 'received-packets-rate', 'processed-packets-rate'.

=item B<--critical-*>

Threshold critical.
Can be: 'received-packets-rate', 'processed-packets-rate'.

=back

=cut

