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

package apps::varnish::local::mode::clients;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clients', type => 0, skipped_code => { -10 => 1 } },
    ];
    $self->{maps_counters}->{clients} = [
        { label => 'request', set => {
                key_values => [ { name => 'client_req' , diff => 1 } ],
                output_template => 'Client request (Total): %.2f', output_error_template => "Client request: %s",
                per_second => 1,
                perfdatas => [
                    { label => 'client_req', value => 'client_req_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'request-400', set => {
                key_values => [ { name => 'client_req_400' , diff => 1 } ],
                output_template => 'Client request (HTTP/400): %.2f', output_error_template => "Client request (HTTP/400): %s",
                per_second => 1,
                perfdatas => [
                    { label => 'client_req_400', value => 'client_req_400_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'request-411', set => {
                key_values => [ { name => 'client_req_411' , diff => 1 } ],
                output_template => 'Client request (HTTP/411): %.2f', output_error_template => "Client request (HTTP/411): %s",
                per_second => 1,
                perfdatas => [
                    { label => 'client_req_411', value => 'client_req_411_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'request-413', set => {
                key_values => [ { name => 'client_req_413' , diff => 1 } ],
                output_template => 'Client request (HTTP/413): %.2f', output_error_template => "Client request (HTTP/413): %s",
                per_second => 1,
                perfdatas => [
                    { label => 'client_req_413', value => 'client_req_413_per_second', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'request-417', set => {
                key_values => [ { name => 'client_req_417' , diff => 1 } ],
                output_template => 'Client request (HTTP/417): %.2f', output_error_template => "Client request (HTTP/417): %s",
                per_second => 1,
                perfdatas => [
                    { label => 'client_req_417', value => 'client_req_417_per_second', template => '%.2f',
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

#   "MAIN.client_req_400": {"type": "MAIN", "value": 0, "flag": "a", "description": "Client requests received, subject to 400 errors"},
#   "MAIN.client_req_411": {"type": "MAIN", "value": 0, "flag": "a", "description": "Client requests received, subject to 411 errors"},
#   "MAIN.client_req_413": {"type": "MAIN", "value": 0, "flag": "a", "description": "Client requests received, subject to 413 errors"},
#   "MAIN.client_req_417": {"type": "MAIN", "value": 0, "flag": "a", "description": "Client requests received, subject to 417 errors"},
#   "MAIN.client_req": {"type": "MAIN", "value": 13597, "flag": "a", "description": "Good client requests received"},

    my $json_data = decode_json($stdout);

    $self->{cache_name} = "cache_varnish_" . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? md5_hex($self->{option_results}->{hostname}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    foreach my $counter (keys %{$json_data}) {
        next if ($counter !~ /^([A-Z])+\.client_.*/);
        my $value = $json_data->{$counter}->{value};
        $counter =~ s/^([A-Z])+\.//;
        $self->{clients}->{$counter} = $value;
    }
};


1;

__END__

=head1 MODE

Check client requests with varnishstat command (Varnish v4 required)

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
Warning threshold per second.
Can be: (request,request-400,request-411,request-413,request-417)

=item B<--critical-*>
Critical threshold per second :
Can be: (request,request-400,request-411,request-413,request-417)

=back

=cut
