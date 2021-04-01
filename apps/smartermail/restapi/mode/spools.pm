#
# Copyright 2021 Centreon (http://www.centreon.com/)
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
# Authors : Roman Morandell - ivertix
#

package apps::smartermail::restapi::mode::spools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_spool_output {
    my ($self, %options) = @_;

    return "Spool '" . $options{instance_value}->{display} ."' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'spools', type => 1, cb_prefix_output => 'prefix_spool_output', message_multiple => 'All spools are ok' }
    ];

    $self->{maps_counters}->{spools} = [
        { label => 'spool-messages', nlabel => 'spool.messages.count', set => {
                key_values      => [ { name => 'messages' }, { name => 'display' } ],
                output_template => 'messages: %d',
                perfdatas       => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
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
        'filter-spool:s' => { name => 'filter_spool' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(endpoint => '/settings/sysadmin/spool-message-counts');

    $self->{spools} = {};
    foreach my $name (keys %{$results->{counts}}) {
        if (defined($self->{option_results}->{filter_spool}) && $self->{option_results}->{filter_spool} ne '' &&
            $name !~ /$self->{option_results}->{filter_spool}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $name  . "': no matching filter.", debug => 1);
            next;
        }

        $self->{spools}->{$name} = {
            display => $name,
            messages => $results->{counts}->{$name}
        };
    }
}


1;

__END__

=head1 MODE

Check spools.

=over 8

=item B<--filter-spool>

Filter spools by name (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'spool-messages'.

=back

=cut
