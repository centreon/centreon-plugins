#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::varnish::local::mode::sessions;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sessions', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{sessions} = [
        { label => 'accepted', set => {
                key_values => [ { name => 'sess_conn', diff => 1 } ],
                output_template => 'Session accepted: %.2f/s', output_error_template => "Session accepted: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_conn', value => 'sess_conn_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'dropped', set => {
                key_values => [ { name => 'sess_drop', diff => 1 } ],
                output_template => 'Session dropped: %.2f/s', output_error_template => "Session dropped: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_drop', value => 'sess_drop_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'failed', set => {
                key_values => [ { name => 'sess_fail', diff => 1 } ],
                output_template => 'Session fail: %.2f/s', output_error_template => "Session fail: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_fail', value => 'sess_fail_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'pipeoverflow', set => {
                key_values => [ { name => 'sess_pipe_overflow', diff => 1 } ],
                output_template => 'Sessions pipe overflow: %.2f/s', output_error_template => "Sessions pipe overflow: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_pipe_overflow', value => 'sess_pipe_overflow_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'queued', set => {
                key_values => [ { name => 'sess_queued' , diff => 1 } ],
                output_template => 'Session queued: %.2f/s', output_error_template => "Session queued: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_queued', value => 'sess_queued_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'dropped', set => {
                key_values => [ { name => 'sess_dropped' , diff => 1 } ],
                output_template => 'Session dropped: %.2f/s', output_error_template => "Session dropped: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_dropped', value => 'sess_dropped_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'readahead', set => {
                key_values => [ { name => 'sess_readahead' , diff => 1 } ],
                output_template => 'Session readahead: %.2f/s', output_error_template => "Session readahead: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_readahead', value => 'sess_readahead_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'closed', set => {
                key_values => [ { name => 'sess_closed' , diff => 1 } ],
                output_template => 'Session closed: %.2f/s', output_error_template => "Session closed: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_closed', value => 'sess_closed_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'herd', set => {
                key_values => [ { name => 'sess_herd' , diff => 1 } ],
                output_template => 'Session herd: %.2f/s', output_error_template => "Session herd: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_herd', value => 'sess_herd_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'linger', set => {
                key_values => [ { name => 'sess_linger' , diff => 1 } ],
                output_template => 'Session linger: %.2f/s', output_error_template => "Session linger: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_linger', value => 'sess_linger_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'pipeline', set => {
                key_values => [ { name => 'sess_pipeline' , diff => 1 } ],
                output_template => 'Session pipeline: %.2f/s', output_error_template => "Session pipeline: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'sess_pipeline', value => 'sess_pipeline_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
    ],
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
    {
        "hostname:s"         => { name => 'hostname' },
        "remote"             => { name => 'remote' },
        "ssh-option:s@"      => { name => 'ssh_option' },
        "ssh-path:s"         => { name => 'ssh_path' },
        "ssh-command:s"      => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"          => { name => 'timeout', default => 30 },
        "sudo"               => { name => 'sudo' },
        "command:s"          => { name => 'command', default => 'varnishstat' },
        "command-path:s"     => { name => 'command_path', default => '/usr/bin' },
        "command-options:s"  => { name => 'command_options', default => ' -1 -j 2>&1' },
    });

    return $self;
};

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});

#   "MAIN.sess_conn": {"type": "MAIN", "value": 13598, "flag": "c", "description": "Sessions accepted"},
#   "MAIN.sess_drop": {"type": "MAIN", "value": 0, "flag": "c", "description": "Sessions dropped"},
#   "MAIN.sess_fail": {"type": "MAIN", "value": 0, "flag": "c", "description": "Session accept failures"},
#   "MAIN.sess_pipe_overflow": {"type": "MAIN", "value": 0, "flag": "c", "description": "Session pipe overflow"},
#   "MAIN.sess_queued": {"type": "MAIN", "value": 0, "flag": "c", "description": "Sessions queued for thread"},
#   "MAIN.sess_dropped": {"type": "MAIN", "value": 0, "flag": "c", "description": "Sessions dropped for thread"},
#   "MAIN.sess_closed": {"type": "MAIN", "value": 13211, "flag": "a", "description": "Session Closed"},
#   "MAIN.sess_pipeline": {"type": "MAIN", "value": 0, "flag": "a", "description": "Session Pipeline"},
#   "MAIN.sess_readahead": {"type": "MAIN", "value": 0, "flag": "a", "description": "Session Read Ahead"},
#   "MAIN.sess_herd": {"type": "MAIN", "value": 26, "flag": "a", "description": "Session herd"},

    my $json_data = decode_json($stdout);

    $self->{cache_name} = "cache_varnish_" . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? md5_hex($self->{option_results}->{hostname}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    foreach my $counter (keys %{$json_data}) {
        next if ($counter !~ /^([A-Z])+\.sess_.*/);
        my $value = $json_data->{$counter}->{value};
        $counter =~ s/^([A-Z])+\.//;
        $self->{sessions}->{$counter} = $value;
    }
};


1;

__END__

=head1 MODE

Check Varnish Cache with varnishstat Command

=over 8

=item B<--remote>

If you dont run this script locally, if you wanna use it remote, you can run it remotely with 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--command>

Varnishstat Binary Filename (Default: varnishstat)

=item B<--command-path>

Directory Path to Varnishstat Binary File (Default: /usr/bin)

=item B<--command-options>

Parameter for Binary File (Default: ' -1 -j 2>&1')

=item B<--warning-*>
Warning Threshold per second.
Can be (accepted,closed,queued,failed,pipeline,readahead,linger,herd,dropped,pipeoverflow)

=item B<--critical-*>
Critical Threshold per second for:
Can be (accepted,closed,queued,failed,pipeline,readahead,linger,herd,dropped,pipeoverflow)

=back

=cut
