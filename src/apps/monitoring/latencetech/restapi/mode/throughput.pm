#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::monitoring::latencetech::restapi::mode::throughput;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'lifbe-download', nlabel => 'lifbe.download.bandwidth.bps', set => {
            key_values          => [ { name => 'lifbeDownload' }, { name => 'display' } ],
            output_template     => 'LIFBE Download: %s%sps',,
            output_change_bytes => 2,
            perfdatas           => [
                { value                => 'lifbeDownload',
                  template             => '%s',
                  min                  => 0,
                  unit                 => 'bps',
                  label_extra_instance => 1,
                  instance_use         => 'display' },
            ],
        }
        },
        { label => 'lifbe-upload', nlabel => 'lifbe.upload.bandwidth.bps', set => {
            key_values          => [ { name => 'lifbeUpload' }, { name => 'display' } ],
            output_template     => 'LIFBE Upload: %s%sps',,
            output_change_bytes => 2,
            perfdatas           => [
                { value                => 'lifbeUpload',
                  template             => '%s',
                  min                  => 0,
                  unit                 => 'bps',
                  label_extra_instance => 1,
                  instance_use         => 'display' },
            ],
        }
        },
        { label => 'jitter-download', nlabel => 'jitter.download.time.milliseconds', set => {
            key_values      => [ { name => 'jitterDownload' }, { name => 'display' } ],
            output_template => 'Jitter Download Time: %.2fms',
            perfdatas       => [
                { value                => 'jitterDownload',
                  template             => '%.2f',
                  min                  => 0,
                  unit                 => 'ms',
                  label_extra_instance => 1,
                  instance_use         => 'display' },
            ],
        }
        },
        { label => 'jitter-upload', nlabel => 'jitter.upload.time.milliseconds', set => {
            key_values      => [ { name => 'jitterUpload' }, { name => 'display' } ],
            output_template => 'Jitter Upload Time: %.2fms',
            perfdatas       => [
                { value                => 'jitterUpload',
                  template             => '%.2f',
                  min                  => 0,
                  unit                 => 'ms',
                  label_extra_instance => 1,
                  instance_use         => 'display' },
            ],
        }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Agent '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    my $results = $options{custom}->request_api(endpoint => '/lifbe');
    $self->{global}->{display} = $results->{agentID};
    foreach my $kpi (keys %{$results}) {
        if ($kpi eq 'lifbeDownload' || $kpi eq 'lifbeUpload') {
            my $value = centreon::plugins::misc::convert_bytes(value => $results->{$kpi}, unit => 'Mb', network => 'true');
            $self->{global}->{$kpi} = $value;
        } else {
            $self->{global}->{$kpi} = $results->{$kpi};
        }
    }
}

1;

__END__

=head1 MODE

Check agent throughput statistics.

=over 8

=item B<--agent-id>

Set the ID of the agent (mandatory option).

=item B<--warning-lifbe-download>

Warning thresholds for LIFBE (Low Intrusive Fast Bandwidth Estimation) download bandwidth (in bps).

=item B<--critical-lifbe-download>

Critical thresholds for LIFBE (Low Intrusive Fast Bandwidth Estimation) download bandwidth (in bps).

=item B<--warning-lifbe-upload>

Warning thresholds for LIFBE (Low Intrusive Fast Bandwidth Estimation) upload bandwidth (in bps).

=item B<--critical-lifbe-upload>

Critical thresholds for LIFBE (Low Intrusive Fast Bandwidth Estimation) upload bandwidth (in bps).

=item B<--warning-jitter-download>

Warning thresholds for jitter download time (in milliseconds).

=item B<--critical-jitter-download>

Critical thresholds for jitter download time (in milliseconds).

=item B<--warning-jitter-upload>

Warning thresholds for jitter upload time (in milliseconds).

=item B<--critical-jitter-upload>

Critical thresholds for jitter upload time (in milliseconds).

=back

=cut
