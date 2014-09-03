###############################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Simon BOMM <sbomm@merethis.com>
#
####################################################################################

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
    
    return @results;
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
