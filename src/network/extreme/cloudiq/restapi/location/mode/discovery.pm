#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::extreme::cloudiq::restapi::location::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'location-type:s' => { name => 'location_type', default => 'site' },
        'prettify'        => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ($self->{option_results}->{location_type} !~ /^?(site|floor|building)/) {
        $self->{output}->add_option_msg(short_msg => "unknown device type $self->{option_results}->{location_type}");
        $self->{output}->option_exit();
    }
}

sub discovery {
    my ($self, %options) = @_;

    my $endpoint = sprintf(
        "/locations/%s?page=%d&limit=100",
        $self->{option_results}->{location_type},
        1
    );

    my $json = $options{custom}->request_api(
        endpoint => $endpoint
    );

    my $page_cnt = $json->{total_pages};
    my $disco_data = [];

    foreach my $location (@{$json->{data}}) {
        push @$disco_data, $location;
    }

    if ($page_cnt > 1) {
        for my $page (2 .. $page_cnt) {
            $endpoint = sprintf(
                "/locations/%s?page=%d&limit=100",
                $self->{option_results}->{location_type},
                $page
            );

            $json = $options{custom}->request_api(
                endpoint => $endpoint
            );

            foreach my $location (@{$json->{data}}) {
                push @$disco_data, $location;
            }
        }
    }

    return $disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = $self->discovery(
        custom => $options{custom}
    );

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$results);
    $disco_stats->{results} = $results;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Extreme Cloud IQ location discovery.

=over 8

=item B<--location-type>

Choose the device type to discover (can be: 'site', 'floor', 'building').

=item B<--prettify>

Prettify JSON output.

=back

=cut
