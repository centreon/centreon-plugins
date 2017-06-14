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

package apps::varnish::local::mode::shm;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'shm', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{shm} = [
        { label => 'records', set => {
                key_values => [ { name => 'shm_records', diff => 1 } ],
                output_template => 'SHM Records: %.2f/s', output_error_template => "SHM Records: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'shm_records', value => 'shm_records_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'writes', set => {
                key_values => [ { name => 'shm_writes', diff => 1 } ],
                output_template => 'SHM Writes: %.2f/s', output_error_template => "SHM Writes: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'shm_writes', value => 'shm_writes_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'flushes', set => {
                key_values => [ { name => 'shm_flushes', diff => 1 } ],
                output_template => 'SHM Flushes: %.2f/s', output_error_template => "SHM Flushes: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'shm_flushes', value => 'shm_flushes_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'cont', set => {
                key_values => [ { name => 'shm_cont', diff => 1 } ],
                output_template => 'SHM Contention: %.2f/s', output_error_template => "SHM Contention: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'shm_cont', value => 'shm_cont_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'cycles', set => {
                key_values => [ { name => 'shm_cycles', diff => 1 } ],
                output_template => 'SHM Cycles: %.2f/s', output_error_template => "SHM Cycles: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'shm_cycles', value => 'shm_cycles_per_second', template => '%.2f',
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

#   "MAIN.shm_records": {"type": "MAIN", "value": 6992776, "flag": "a", "description": "SHM records"},
#   "MAIN.shm_writes": {"type": "MAIN", "value": 3947244, "flag": "a", "description": "SHM writes"},
#   "MAIN.shm_flushes": {"type": "MAIN", "value": 12354, "flag": "a", "description": "SHM flushes due to overflow"},
#   "MAIN.shm_cont": {"type": "MAIN", "value": 564, "flag": "a", "description": "SHM MTX contention"},
#   "MAIN.shm_cycles": {"type": "MAIN", "value": 3, "flag": "a", "description": "SHM cycles through buffer"},

    my $json_data = decode_json($stdout);

    $self->{cache_name} = "cache_varnish_" . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? md5_hex($self->{option_results}->{hostname}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    foreach my $counter (keys %{$json_data}) {
        next if ($counter !~ /shm/);
        my $value = $json_data->{$counter}->{value};
        $counter =~ s/^([A-Z])+\.//;
        $self->{shm}->{$counter} = $value;
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

Warning Threshold for:
records => SHM records,
writes  => SHM writes,
flushes => SHM flushes due to overflow,
cont    => SHM MTX contention,
cycles  => SHM cycles through buffer

=item B<--critical-*>

Critical Threshold for:
records => SHM records,
writes  => SHM writes,
flushes => SHM flushes due to overflow,
cont    => SHM MTX contention,
cycles  => SHM cycles through buffer

=back

=cut
