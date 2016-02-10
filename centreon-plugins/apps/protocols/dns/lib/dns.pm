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

package apps::protocols::dns::lib::dns;

use strict;
use warnings;
use Net::DNS;

my $handle;

my %map_search_field = (
    MX => 'exchange',
    SOA => 'mname',
    NS => 'nsdname',
    A => 'address',
    PTR => 'name',
);

sub search {
    my ($self, %options) = @_;
    
    my @results = ();
    my $search_type = $self->{option_results}->{search_type};
    if (defined($search_type) && !defined($map_search_field{$search_type})) {
        $self->{output}->add_option_msg(short_msg => "search-type '$search_type' is unknown or unsupported");
        $self->{output}->option_exit();
    }
    
    my $error_quit = defined($options{error_quit}) ? $options{error_quit} : undef;
    
    my $reply = $handle->search($self->{option_results}->{search}, $search_type);
    if ($reply) {
        foreach my $rr ($reply->answer) {
            if (!defined($search_type)) {
                if ($rr->type eq 'A') {
                    push @results, $rr->address;
                }
                if ($rr->type eq 'PTR') {
                    push @results, $rr->name;
                }
                next;
            }

            next if ($rr->type ne $search_type);
            my $search_field = $map_search_field{$search_type};
            push @results, $rr->$search_field;
        }
    } else {
        if (defined($error_quit)) {
            $self->{output}->output_add(severity => $error_quit,
                                        short_msg => sprintf("DNS Query Failed: %s", $handle->errorstring));
            $self->{output}->display();
            $self->{output}->exit();
        }
    }
    
    return sort @results;
}

sub connect {
    my ($self, %options) = @_;
    my %dns_options = ();
    
    my $nameservers = [];
    if (defined($self->{option_results}->{nameservers})) {
        $nameservers = [@{$self->{option_results}->{nameservers}}];
    }
    my $searchlist = [];
    if (defined($self->{option_results}->{searchlist})) {
        $searchlist = [@{$self->{option_results}->{searchlist}}];
    }
    foreach my $option (@{$self->{option_results}->{dns_options}}) {
        next if ($option !~ /^(.+?)=(.+)$/);
        $dns_options{$1} = $2;
    }

    $handle = Net::DNS::Resolver->new(
        nameservers => $nameservers,
        searchlist  => $searchlist,
        %dns_options
    );
}

1;
