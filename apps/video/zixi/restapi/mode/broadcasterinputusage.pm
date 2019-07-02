#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::video::zixi::restapi::mode::broadcasterinputusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'status : ' . $self->{result_values}->{status} . ' [error: ' . $self->{result_values}->{error} . ']';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{source} = $options{new_datas}->{$self->{instance} . '_source'};
    $self->{result_values}->{error} = $options{new_datas}->{$self->{instance} . '_error'};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'input', type => 1, cb_prefix_output => 'prefix_input_output', message_multiple => 'All inputs are ok', skipped_code => { -11 => 1 } },
    ];
    
    $self->{maps_counters}->{input} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'source' }, { name => 'error' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
         { label => 'traffic-in', set => {
                key_values => [ { name => 'traffic_in', diff => 1 }, { name => 'source' } ],
                per_second => 1, output_change_bytes => 2,
                output_template => 'Traffic In : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', value => 'traffic_in_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'source_absolute' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'traffic_out', diff => 1 }, { name => 'source' } ],
                per_second => 1, output_change_bytes => 2,
                output_template => 'Traffic Out : %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', value => 'traffic_out_per_second', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'source_absolute' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-source:s"         => { name => 'filter_source' },
                                  "warning-status:s"        => { name => 'warning_status' },
                                  "critical-status:s"       => { name => 'critical_status', default => '%{status} !~ /Connecting|Connected/i || %{error} !~ /none/i' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_input_output {
    my ($self, %options) = @_;
    
    return "Input '" . $options{instance_value}->{source} . "' ";
}

my %mapping_input_status = (0 => 'none', 1 => 'unknown',
    2 => 'resolve error', 3 => 'timeout', 4 => 'network error', 5 => 'protocol error',
    6 => 'server is full', 7 => 'connection rejected', 8 => 'authentication error', 9 => 'license error',
    10 => 'end of file', 11 => 'flood error', 12 => 'redirect', 13 => 'stopped',
    14 => 'limit', 15 => 'not found', 16 => 'not supported', 17 => 'local file system error',
    18 => 'remote file system error', 19 => 'stream replaced', 20 => 'p2p abort',
    21 => 'compression error', 22 => 'source collision error', 23 => 'adaptive',
    24 => 'tcp connection error', 25 => 'rtmp connection error', 26 => 'rtmp handshake error',
    27 => 'tcp connection closed', 28 => 'rtmp stream error', 29 => 'rtmp publish error',
    30 => 'rtmp stream closed', 31 => 'rtmp play error', 32 => 'rtmp protocol error',
    33 => 'rtmp analyze timeout', 34 => 'busy', 35 => 'encryption error',
    36 => 'transcoder error', 37 => 'error in invocation a transcoder subprocess',
    38 => 'error communicating with a transcoder subprocess', 39 => 'error in RTMP Akamai authentication',
    40 => 'maximum outputs for the source reached', 41 => 'generic error',
    42 => 'zero bitrate warning', 43 => 'low bitrate warning', 44 => 'multicast join failed',
);

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{input} = {};
    my $result = $options{custom}->get(path => '/zixi/streams.json?complete=1');

    foreach my $entry (@{$result->{streams}}) {        
        if (defined($self->{option_results}->{filter_source}) && $self->{option_results}->{filter_source} ne '' &&
            $entry->{source} !~ /$self->{option_results}->{filter_source}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $entry->{source} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{input}->{$entry->{id}} = { 
            source => $entry->{source},
            status => $entry->{status},
            error => $mapping_input_status{$entry->{error_code}},
            traffic_in => $entry->{stats}->{net_recv}->{bytes} * 8,
            traffic_out => $entry->{stats}->{net_send}->{bytes} * 8,
        };
    }
    
    if (scalar(keys %{$self->{input}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No input found.");
        $self->{output}->option_exit();
    }
    
    $self->{cache_name} = "zixi_" . $self->{mode} . '_' . $options{custom}->{hostname} . '_' . $options{custom}->{port} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check input usage.

=over 8

=item B<--filter-source>

Filter source (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-*>

Threshold warning.
Can be: 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'traffic-in', 'traffic-out'.

=item B<--warning-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{source}, %{status}, %{error}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /Connecting|Connected/i || %{error} !~ /none/i').
Can used special variables like: %{source}, %{status}, %{error}.

=back

=cut
