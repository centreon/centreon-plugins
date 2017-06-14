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

package apps::varnish::local::mode::threads;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'threads', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{threads} = [
       { label => 'total', set => {
                key_values => [ { name => 'threads' } ],
                output_template => 'Total Threads: %d', output_error_template => "Total Threads: %s",
                perfdatas => [
                    { label => 'total', value => 'threads_absolute', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'created', set => {
                key_values => [ { name => 'threads_created', diff => 1 } ],
                output_template => 'Thread created: %.2f/s', output_error_template => "Thread created: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'created', value => 'threads_created_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'limited', set => {
                key_values => [ { name => 'threads_limited', diff => 1 } ],
                output_template => 'Thread limited: %.2f/s', output_error_template => "Thread limited: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'limited', value => 'threads_limited_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'destroyed', set => {
                key_values => [ { name => 'threads_destroyed', diff => 1 } ],
                output_template => 'Thread destroyed: %.2f/s', output_error_template => "Thread destroyed: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'destroyed', value => 'threads_destroyed_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'failed', set => {
                key_values => [ { name => 'threads_failed', diff => 1 } ],
                output_template => 'Threads fail: %.2f/s', output_error_template => "Threads fail: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'failed', value => 'threads_failed_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'queue', set => {
                key_values => [ { name => 'thread_queue_len' } ],
                output_template => 'Thread queue lenght: %d', output_error_template => "Thread queue lenght: %d",
                perfdatas => [
                    { label => 'queue_lenght', value => 'thread_queue_len_absolute', template => '%d',
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

#   "MAIN.threads_limited": {"type": "MAIN", "value": 0, "flag": "c", "description": "Threads hit max"},
#   "MAIN.threads_created": {"type": "MAIN", "value": 100, "flag": "c", "description": "Threads created"},
#   "MAIN.threads_destroyed": {"type": "MAIN", "value": 0, "flag": "c", "description": "Threads destroyed"},
#   "MAIN.threads_failed": {"type": "MAIN", "value": 0, "flag": "c", "description": "Thread creation failed"},
#   "MAIN.thread_queue_len": {"type": "MAIN", "value": 0, "flag": "g", "description": "Length of session queue"},

    my $json_data = decode_json($stdout);

    $self->{cache_name} = "cache_varnish_" . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? md5_hex($self->{option_results}->{hostname}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    foreach my $counter (keys %{$json_data}) {
        next if ($counter !~ /^([A-Z])+\.thread.*/);
        my $value = $json_data->{$counter}->{value};
        $counter =~ s/^([A-Z])+\.//;
        print "$counter ===> $value \n";
        $self->{threads}->{$counter} = $value;
    }
};


1;

__END__

=head1 MODE

Check Varnish 4 Cache with varnishstat Command

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

Warning Threshold for threads.
Can be:
 (created, destroyed, limited, failed) [per sec]
 (total, queue lenght) [absolute]

=item B<--critical-*>

Warning Threshold for threads.
Can be:
 (created, destroyed, limited, failed) [per sec]
 (total, queue lenght) [absolute]

=back

=cut

