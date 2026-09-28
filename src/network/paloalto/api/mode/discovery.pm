#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

use centreon::plugins::misc qw/json_encode is_excluded/;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "prettify"             => { name => 'prettify' },
        'connected-only'       => { name => 'connected_only' },
        'include-serial:s'     => { name => 'include_serial', default => '' },
        'exclude-serial:s'     => { name => 'exclude_serial', default => '' },
        'include-model:s'      => { name => 'include_model', default => '' },
        'exclude-model:s'      => { name => 'exclude_model', default => '' },
        'include-ip-address:s' => { name => 'include_ip_address', default => '' },
        'exclude-ip-address:s' => { name => 'exclude_ip_address', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{output}->option_exit( short_msg => "The --target parameter is not allowed in this mode." )
        if $options{custom}->{target};

    my $filter = $self->{option_results}->{connected_only} ? 'connected' : 'all';
    my $result = $self->{instances} = $options{custom}->request_api(
        type => 'op',
        cmd => "<show><devices><$filter></$filter></devices></show>",
        ForceArray => [ 'entry' ]
    );

    $self->{devices} = [ ];

    return unless $result && ref $result->{devices}->{entry} eq 'ARRAY';

    foreach my $device (@{$result->{devices}->{entry}}) {
        next unless $device->{serial};

        my $item = {
            Serial => $device->{serial},
            HostName => $device->{hostname} // '',
            Connected => $device->{connected} // '',
            Model => $device->{model} // '',
            IpAddress => $device->{'ip-address'} // '',
        };

        next if is_excluded($item->{Serial}, $self->{option_results}->{include_serial}, $self->{option_results}->{exclude_serial}, output => $self->{output}) ||
                is_excluded($item->{Model}, $self->{option_results}->{include_model}, $self->{option_results}->{exclude_model}, output => $self->{output}) ||
                is_excluded($item->{IpAddress}, $self->{option_results}->{include_ip_address}, $self->{option_results}->{exclude_ip_address}, output => $self->{output});

        push @{$self->{devices}}, $item;
    }
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;

    $disco_stats->{start_time} = time();

    $self->manage_selection(%options);

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @{$self->{devices}};
    $disco_stats->{results} = $self->{devices};

    my $encoded_data = json_encode($disco_stats,
                                   prettify => $self->{option_results}->{prettify},
                                   errstr => '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}');

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}
1;

__END__

=head1 MODE

Discover firewalls managed by Panorama.

=over 8

=item B<--connected-only>

Display only connected firewalls.

=item B<--include-serial>

Filter firewall by serial number (can be a regex).

=item B<--exclude-serial>

Exclude firewall by serial number (can be a regex).

=item B<--include-model>

Filter firewall by model (can be a regex).

=item B<--exclude-model>

Exclude firewall by model (can be a regex).

=item B<--include-ip-address>

Filter firewall by IP address (can be a regex).

=item B<--exclude-ip-address>

Exclude firewall IP by address (can be a regex).

=item B<--prettify>

Prettify JSON output.

=back

=cut
