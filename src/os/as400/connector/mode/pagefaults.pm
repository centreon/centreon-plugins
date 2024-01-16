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

package os::as400::connector::mode::pagefaults;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 }  }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'pagefaults-database', nlabel => 'pagefaults.database.ratio.percentage', set => {
                key_values => [ { name => 'db_ratio' } ],
                output_template => 'database page faults: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'pagefaults-nondatabase', nlabel => 'pagefaults.nondatabase.ratio.percentage', set => {
                key_values => [ { name => 'non_db_ratio' } ],
                output_template => 'nondatabase page faults: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $pools = $options{custom}->request_api(command => 'pageFault');

    my ($db_page_fault, $db_page, $non_db_page_fault, $non_db_page) = (0, 0, 0, 0);
    foreach my $entry (@{$pools->{result}}) {
        $db_page_fault += $entry->{dbPageFault};
        $db_page += $entry->{dbPage};
        $non_db_page_fault += $entry->{nonDbPageFault};
        $non_db_page += $entry->{nonDbPage};
    }

    $self->{global} = { non_db_ratio => 0, db_ratio => 0 };
    if ($non_db_page > 0) {
        $self->{global}->{non_db_ratio} = $non_db_page_fault * 100 / $non_db_page;
    }
    if ($db_page > 0) {
        $self->{global}->{db_ratio} = $db_page_fault * 100 / $db_page;
    }
}

1;

__END__

=head1 MODE

Check page faults.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'pagefaults-database', 'pagefaults-nondatabase'.

=back

=cut
