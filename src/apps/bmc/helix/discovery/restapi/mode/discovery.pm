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

package apps::bmc::helix::discovery::restapi::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify' => { name => 'prettify' },
        'query:s'  => { name => 'query' },
        'limit:s'  => { name => 'limit', default => '100' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{query} = (defined($self->{option_results}->{query})) ? $self->{option_results}->{query} : undef;

    if (!defined($self->{query}) || $self->{query} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --query option.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = $options{custom}->data_search(query => $self->{option_results}->{query}, limit => $self->{option_results}->{limit});

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};

    if (defined($results->[0]->{headings})) {
        my $new_data;
        my @headings = @{$results->[0]->{'headings'}};
        foreach my $dataset (@{$results}) {
            $disco_stats->{discovered_items} += scalar (@{$dataset->{'results'}});
            foreach my $result (@{$dataset->{'results'}}) {
                my $entry;
                foreach my $i (0..(scalar @headings -1)) {
                    $entry->{$headings[$i]} = $result->[$i];
                }
                push @$new_data, $entry;
            }
        }
        $disco_stats->{results} = $new_data;
    }

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

BMC Helix Discovery assets discovery.

=over 8

=item B<--query>

Set the search query (mandatory).
Example: --query='SEARCH Host'

=item B<--limit>

Limit the number of results per API query for performance purposes (default: 100).
Example: --limit='50'

=back

=cut
