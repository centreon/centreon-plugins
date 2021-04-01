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
#

package apps::backup::tsm::local::mode::volumes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'volumes', type => 1, cb_prefix_output => 'prefix_volumes_output', message_multiple => 'All volumes are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Volumes Total : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'online', set => {
                key_values => [ { name => 'online' } ],
                output_template => 'Online : %s',
                perfdatas => [
                    { label => 'online', value => 'online', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'offline', set => {
                key_values => [ { name => 'offline' } ],
                output_template => 'Offline : %s',
                perfdatas => [
                    { label => 'offline', value => 'offline', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'empty', set => {
                key_values => [ { name => 'empty' } ],
                output_template => 'Empty : %s',
                perfdatas => [
                    { label => 'empty', value => 'empty', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'pending', set => {
                key_values => [ { name => 'pending' } ],
                output_template => 'Pending : %s',
                perfdatas => [
                    { label => 'pending', value => 'pending', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'filling', set => {
                key_values => [ { name => 'filling' } ],
                output_template => 'Filling : %s',
                perfdatas => [
                    { label => 'filling', value => 'filling', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'full', set => {
                key_values => [ { name => 'full' } ],
                output_template => 'Full : %s',
                perfdatas => [
                    { label => 'full', value => 'full', template => '%s', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{volumes} = [
        { label => 'used', set => {
                key_values => [ { name => 'prct_utilized' }, { name => 'display' } ],
                output_template => 'Usage : %s %%',
                perfdatas => [
                    { label => 'used', value => 'prct_utilized', template => '%s', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_volumes_output {
    my ($self, %options) = @_;

    return "Volumes '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-volume:s"     => { name => 'filter_volume' },
                                  "filter-stgpool:s"    => { name => 'filter_stgpool' },
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $response = $options{custom}->execute_command(
        query => "SELECT volume_name, stgpool_name, status, pct_utilized FROM volumes"
    );
    $self->{volumes} = {};
    $self->{global} = { total => 0, online => 0, offline => 0, empty => 0, pending => 0, filling => 0, full => 0 };

    while ($response =~ /^(.*?),(.*?),(.*?),(.*?)$/mg) {
        my ($volume_name, $stgpool, $status, $pct_utilized) = ($1, $2, $3, $4);

        if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '' &&
            $volume_name !~ /$self->{option_results}->{filter_volume}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $volume_name . "': no matching volume name filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_stgpool}) && $self->{option_results}->{filter_stgpool} ne '' &&
            $stgpool !~ /$self->{option_results}->{filter_stgpool}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $stgpool . "': no matching storage pool filter.", debug => 1);
            next;
        }

        $self->{global}->{total}++;
        $self->{global}->{lc($status)}++;

        $self->{volumes}->{$volume_name} = {
            display => $volume_name,
            prct_utilized => $pct_utilized,
        };
    }
}

1;

__END__

=head1 MODE

Check volumes.

=over 8

=item B<--filter-volume>

Filter by volume name.

=item B<--filter-stgpool>

Filter by storage pool name.

=item B<--warning-*>

Set warning threshold. Can be : 'total', 'used', 
'online',' offline', 'empty', 'pending', 'filling', full'.

=item B<--critical-*>

Set critical threshold. Can be : 'total', 'used', 
'online', 'offline', empty', 'pending', 'filling', full'.

=back

=cut

