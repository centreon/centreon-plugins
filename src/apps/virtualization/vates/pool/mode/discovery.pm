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

package apps::virtualization::vates::pool::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc qw(json_encode is_excluded is_not_empty is_empty);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify'             => { name => 'prettify' },
        'filter-ha:s'          => { name => 'filter_ha' },
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
    my $pools = $options{custom}->request_api_get(endpoint => "pools", get_param => ["fields=*"]);

    $disco_stats->{results} = [];

    foreach my $pool (@{$pools}) {
        my $pool_disco = {};
        next if is_excluded($pool->{HA_enabled}, $self->{option_results}->{filter_ha} );
        # change the keys to match the host discovery provider's attributes
        $pool_disco->{pool_name} = $pool->{name_label} // '';
        $pool_disco->{pool_uuid} = $pool->{uuid} // '';
        $pool_disco->{name_description} = $pool->{name_description} // '';
        $pool_disco->{HA_enabled} = $pool->{HA_enabled} // "";

        # there can be empty tag in the api answer, this allows to trim empty tags.
        $pool_disco->{tags} = [];
        for my $tag (@{$pool->{tags}}){
            if (is_not_empty($tag)) {
                push(@{$pool_disco->{tags}}, $tag);
            }
        }
        $pool_disco->{cpu_cores} = '';
        $pool_disco->{cpu_sockets} = '';
        if ($pool->{cpus} && ref($pool->{cpus}) eq "HASH") {
            $pool_disco->{cpu_cores} = $pool->{cpus}->{cores} // '';
            $pool_disco->{cpu_sockets} = $pool->{cpus}->{sockets} // '';
        }
        # list all host in a pool and add their name_label in the output.
        my $hosts = $options{custom}->request_api_get(endpoint => "hosts", get_param => ["fields=uuid,name_label", 'filter=$pool:' . $pool->{uuid}]);
        $pool_disco->{hosts_name_label} = [];
        $pool_disco->{hosts_uuid} = [];
        foreach my $host (@{$hosts}){
            push(@{$pool_disco->{hosts_name_label}}, $host->{name_label});
            push(@{$pool_disco->{hosts_uuid}}, $host->{uuid});
        }

        push(@{$disco_stats->{results}}, $pool_disco);
    }
    # Record the metadata
    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar( @{$disco_stats->{results}});

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

Discover Vates Xen Orchestra pools.

=over 8

=item B<--filter-ha>

Filter pool by High availability status. Only matching pools are included.

=item B<--prettify>

Prettify JSON output.

=back

=cut
