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

package apps::virtualization::vates::host::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(json_encode is_excluded is_not_empty is_empty);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'              => { name => 'prettify' },
        'filter-power-states:s' => { name => 'filter_power_states' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();
    my $hosts = $options{custom}->request_api_get(endpoint => "hosts", get_param => ["fields=*"]);

    $disco_stats->{results} = [];
    foreach my $host (@{$hosts}) {
        my $host_disco = {};
        next if is_excluded($host->{power_state}, $self->{option_results}->{filter_power_states});

        # change the keys to match the host discovery provider's attributes
        $host_disco->{host_name} = delete $host->{name_label};
        $host_disco->{host_uuid} = delete $host->{uuid};
        $host_disco->{name_description} = delete $host->{name_description};
        $host_disco->{enabled} = $host->{enabled} // '';
        $host_disco->{power_state} = $host->{power_state} // '';
        $host_disco->{address} = $host->{address} // '';
        $host_disco->{pool_uuid} = $host->{'$pool'} // '';

        $host_disco->{manufacturer} = '';
        $host_disco->{product_name} = '';
        if (is_not_empty($host->{bios_strings}) and ref($host->{bios_strings}) eq "HASH") {
            $host_disco->{manufacturer} = $host->{bios_strings}->{'system-manufacturer'} // '';
            $host_disco->{product_name} = $host->{bios_strings}->{'system-product-name'} // '';
        }

        $host_disco->{cpu_count} = '';
        if (is_not_empty($host->{CPUs}) and ref($host->{CPUs}) eq "HASH") {
            $host_disco->{cpu_count} = $host->{CPUs}->{cpu_count} // '';
        }

        $host_disco->{memory_size} = '';
        if (is_not_empty($host->{memory}) and ref($host->{memory}) eq "HASH") {
            $host_disco->{memory_size} = $host->{memory}->{size} // '';
        }

        # there can be empty tag in the api answer, this allows to trim empty tags.
        $host_disco->{tags} = [];
        for my $tag (@{$host->{tags}}) {
            if (is_not_empty($tag)) {
                push(@{$host_disco->{tags}}, $tag);
            }
        }

        push(@{$disco_stats->{results}}, $host_disco);
    }
    # Record the metadata
    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@{$disco_stats->{results}});

    my $encoded_data = json_encode(
        $disco_stats,
        prettify => $self->{option_results}->{prettify},
        errstr   => '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}',
        output   => $self->{output}
    );

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
}

1;

__END__

=head1 MODE

Discover Vates XCP-ng hosts.

=over 8

=item B<--filter-power-states>

Filter hosts by power state (can be a regexp). Only matching hosts are included.

=item B<--prettify>

Prettify JSON output.

=back

=cut
