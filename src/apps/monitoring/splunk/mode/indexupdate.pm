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

package apps::monitoring::splunk::mode::indexupdate;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'index', type => 1, cb_prefix_output => 'index_prefix_output', message_multiple => 'All indexes are OK' }
    ];

    $self->{maps_counters}->{index} = [
        { label => 'index-last-update-seconds', nlabel => 'splunk.index.last.updated.seconds', set => {
                key_values => [ { name => 'index_last_update' }, { name => 'expires_human' } ],
                output_use => 'expires_human',
                output_template => 'last update %s ',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub index_prefix_output {
    my ($self, %options) = @_;

    return sprintf( "Index '%s' ", $options{instance});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'index-name:s'     => { name => 'index_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $index_info = $options{custom}->get_index_info(
        index_name => $self->{option_results}->{index_name}
    );

    foreach my $value (@{$index_info}){
        $self->{index}->{$value->{index_name}} = {
            index_last_update => $value->{ts_last_update},
            expires_human => centreon::plugins::misc::change_seconds(value => $value->{ts_last_update})
        }
    }

}

1;

__END__

=head1 MODE

Check Splunk index last update time.

=over 8

=item B<--index-name> 

Specify index name to get last updates. 

If not specified, all indexes are checked by default.

=item B<--warning-index-last-update-seconds> 

Warning threshold in seconds for last update.

Example: --warning-index-last-update-seconds=15000

=item B<--critical-index-last-update-seconds>

Critical threshold in seconds for last update.

Example: --critical-index-last-update-seconds=25000

=back

=cut
