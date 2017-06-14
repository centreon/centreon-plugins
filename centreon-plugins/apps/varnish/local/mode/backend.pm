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

package apps::varnish::local::mode::backend;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'backend', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{backend} = [
        { label => 'conn', set => {
                key_values => [ { name => 'backend_conn', diff => 1 } ],
                output_template => 'Backend con: %.2f/s', output_error_template => "Backend con: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_conn', value => 'backend_conn_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'unhealthy', set => {
                key_values => [ { name => 'backend_unhealthy', diff => 1 } ],
                output_template => 'Backend unhealthy: %.2f/s', output_error_template => "Backend unhealthy: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_unhealthy', value => 'backend_unhealthy_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'busy', set => {
                key_values => [ { name => 'backend_busy', diff => 1 } ],
                output_template => 'Backend busy: %.2f/s', output_error_template => "Backend busy: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_miss', value => 'backend_miss_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'fail', set => {
                key_values => [ { name => 'backend_fail', diff => 1 } ],
                output_template => 'Backend fail: %.2f/s', output_error_template => "Backend fail: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_fail', value => 'backend_fail_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'reuse', set => {
                key_values => [ { name => 'backend_reuse', diff => 1 } ],
                output_template => 'Backend reuse: %.2f/s', output_error_template => "Backend reuse: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_reuse', value => 'backend_reuse_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'recycle', set => {
                key_values => [ { name => 'backend_recycle', diff => 1 } ],
                output_template => 'Backend recycle: %.2f/s', output_error_template => "Backend recycle: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_recycle', value => 'backend_recycle_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'retry', set => {
                key_values => [ { name => 'backend_retry', diff => 1 } ],
                output_template => 'Backend retry: %.2f/s', output_error_template => "Backend retry: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_retry', value => 'backend_retry_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'recycle', set => {
                key_values => [ { name => 'backend_recycle', diff => 1 } ],
                output_template => 'Backend recycle: %.2f/s', output_error_template => "Backend recycle: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_recycle', value => 'backend_recycle_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'request', set => {
                key_values => [ { name => 'backend_req', diff => 1 } ],
                output_template => 'Backend requests: %.2f/s', output_error_template => "Backend requests: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'backend_req', value => 'backend_req_per_second', template => '%.2f',
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

#   "MAIN.backend_hit": {"type": "MAIN", "value": 18437, "flag": "a", "description": "Cache hits"},
#   "MAIN.backend_hitpass": {"type": "MAIN", "value": 3488, "flag": "a", "description": "Cache hits for pass"},
#   "MAIN.backend_miss": {"type": "MAIN", "value": 5782, "flag": "a", "description": "Cache misses"},
    my $json_data = decode_json($stdout);

    $self->{cache_name} = "cache_varnish_" . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? md5_hex($self->{option_results}->{hostname}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    foreach my $counter (keys %{$json_data}) {
        next if ($counter !~ /backend/);
        my $value = $json_data->{$counter}->{value};
        $counter =~ s/^([A-Z])+\.//;
        $self->{backend}->{$counter} = $value;
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

Parameter for Binary File (Default: ' -1 ')

=item B<--warning-*>

Warning Threshold for:
conn      => Backend conn. success,
unhealthy => Backend conn. not attempted,
busy      => Backend conn. too many,
fail      => Backend conn. failures,
reuse     => Backend conn. reuses,
toolate   => Backend conn. was closed,
recycle   => Backend conn. recycles,
retry     => Backend conn. retry,
request   => Backend requests made

=item B<--critical-*>

Critical Threshold for:
conn      => Backend conn. success,
unhealthy => Backend conn. not attempted,
busy      => Backend conn. too many,
fail      => Backend conn. failures,
reuse     => Backend conn. reuses,
toolate   => Backend conn. was closed,
recycle   => Backend conn. recycles,
retry     => Backend conn. retry,
request   => Backend requests made

=back

=cut
