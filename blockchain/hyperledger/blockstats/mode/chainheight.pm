#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package blockchain::hyperledger::blockstats::mode::chainheight;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'height', nlabel => 'chain.height.count', set => {
                key_values => [ { name => 'height' } ],
                output_template => 'Chain height: %d',
                perfdatas => [
                    { label => 'height', value => 'height_absolute', template => '%d', min => 0 },
                ],
            }
        },
    ];
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
   
    return $self;
}

# {
#     "ChainHeight": "5"
# }

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my $result = $options{custom}->request_api(url_path => '/statistics/chainHeight');
    # use Data::Dumper;
    # print Dumper $result;
    $self->{global}->{height} = $result->{ChainHeight};
}

1;

__END__

=head1 MODE

Check blockchain statistics

=cut
