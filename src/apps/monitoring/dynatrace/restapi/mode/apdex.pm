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

package apps::monitoring::dynatrace::restapi::mode::apdex;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_entity_output {
    my ($self, %options) = @_;

    return sprintf(
        "Entity '%s' ", 
        $options{instance_value}->{display}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'apdex', type => 1, cb_prefix_output => 'prefix_entity_output', message_multiple => 'All Apdex are OK', skipped_code => { -10 => 1 }}
    ];

    $self->{maps_counters}->{apdex} = [
        { label => 'apdex', nlabel => 'apdex', set => {
                key_values => [ { name => 'apdex' }, { name => 'display' } ],
                output_template => 'apdex : %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 1, label_extra_instance => 1, instance_use => 'display' }
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
        'aggregation-type:s' => { name => 'aggregation_type', default => 'count' },
        'filter-entity:s'    => { name => 'filter_entity' },
        'relative-time:s'    => { name => 'relative_time', default => '30mins' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_apdex();

    foreach my $apdex (keys %{$result->{result}->{dataPoints}}) {
        
        if (defined($self->{option_results}->{filter_entity}) && $self->{option_results}->{filter_entity} ne '' &&
            $result->{result}->{entities}->{$apdex} !~ /$self->{option_results}->{filter_entity}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{result}->{entities}->{$apdex} . "': no matching filter.", debug => 1);
            next;
        }

        if (defined($result->{result}->{dataPoints}->{$apdex}[0][1])) {
            $self->{apdex}->{$result->{result}->{entities}->{$apdex}} = {
                display => $result->{result}->{entities}->{$apdex},
                apdex   => $result->{result}->{dataPoints}->{$apdex}[0][1]
            };
        }
    }

    if (scalar(keys %{$self->{apdex}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entity found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Apdex.

=over 8

=item B<--relative-time>

Set request relative time (default: '30min').
Can use: min, 5mins, 10mins, 15mins, 30mins, hour, 2hours, 6hours, day, 3days, week, month.

=item B<--aggregation-type>

Set aggregation type (default: 'count').

=item B<--filter-entity>

Filter Apdex by entity (can be a regexp).

=item B<--warning-apdex>

Set warning threshold for Apdex.

=item B<--critical-apdex>

Set critical threshold for Apdex.

=back

=cut
