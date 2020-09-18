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

package database::firebird::mode::pages;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'reads', nlabel => 'pages.reads.persecond', set => {
                key_values => [ { name => 'reads', per_second => 1 } ],
                output_template => 'Reads : %.2f',
                perfdatas => [
                    { label => 'reads', template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'writes', nlabel => 'pages.writes.persecond', set => {
                key_values => [ { name => 'writes', per_second => 1 } ],
                output_template => 'Writes : %.2f',
                perfdatas => [
                    { label => 'writes', template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'fetches', nlabel => 'pages.fetches.persecond', set => {
                key_values => [ { name => 'fetches', per_second => 1 } ],
                output_template => 'Fetches : %.2f',
                perfdatas => [
                    { label => 'fetches', template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        },
        { label => 'marks', nlabel => 'pages.marks.persecond', set => {
                key_values => [ { name => 'marks', per_second => 1 } ],
                output_template => 'Marks : %.2f',
                perfdatas => [
                    { label => 'marks', template => '%.2f', unit => '/s', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Page ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{SELECT MON$PAGE_READS as PAGE_READS, MON$PAGE_WRITES as PAGE_WRITES, MON$PAGE_FETCHES as PAGE_FETCHES, MON$PAGE_MARKS as PAGE_MARKS FROM MON$IO_STATS mi WHERE mi.MON$STAT_GROUP = 0});    
    my $row = $options{sql}->fetchrow_hashref();
    if (!defined($row)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get page informations");
        $self->{output}->option_exit();
    }
    
    $self->{global} = { reads => $row->{PAGE_READS}, writes => $row->{PAGE_WRITES}, 
        fetches => $row->{PAGE_FETCHES}, marks => $row->{PAGE_MARKS} };
    
    $self->{cache_name} = 'firebird_' . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check page statistics on current database. 

=over 8)

=item B<--warning-*>

Threshold warning.
Can be: 'reads', 'writes', 'fetches', 'marks'. 

=item B<--critical-*>

Threshold critical.
Can be: 'reads', 'writes', 'fetches', 'marks'. 

=back

=cut
