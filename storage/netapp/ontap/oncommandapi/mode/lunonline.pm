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

package storage::netapp::ontap::oncommandapi::mode::lunonline;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'luns', type => 0},
    ];
    
    $self->{maps_counters}->{luns} = [
        { label => 'online', set => {
                key_values => [ { name => 'online' } ],
                output_template => 'Luns online: %d',
                perfdatas => [
                    { label => 'online', value => 'online', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'not-online', set => {
                key_values => [ { name => 'not_online' } ],
                output_template => 'Luns not online: %d',
                perfdatas => [
                    { label => 'not_online', value => 'not_online', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'mapped', set => {
                key_values => [ { name => 'mapped' } ],
                output_template => 'Luns mapped: %d',
                perfdatas => [
                    { label => 'mapped', value => 'mapped', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'not-mapped', set => {
                key_values => [ { name => 'not_mapped' } ],
                output_template => 'Luns not mapped: %d',
                perfdatas => [
                    { label => 'not_mapped', value => 'not_mapped', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-volume:s' => { name => 'filter_volume' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/luns');
    
    $self->{luns}->{online} = 0;
    $self->{luns}->{not_online} = 0;
    $self->{luns}->{mapped} = 0;
    $self->{luns}->{not_mapped} = 0;
    
    foreach my $lun (@{$result}) {
        my $volume = $2 if ($lun->{path} =~ /^\/(\S+)\/(\S+)\/(\S+)\s*/);

        if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '' &&
            defined($volume) && $volume !~ /$self->{option_results}->{filter_volume}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $lun->{path} . "': no matching filter volume '" . $volume . "'", debug => 1);
            next;
        }

        $self->{luns}->{online}++ if ($lun->{is_online});
        $self->{luns}->{mapped}++ if ($lun->{is_mapped});
        if (!$lun->{is_online}) {
            $self->{luns}->{not_online}++;

            my $long_msg = "Lun '" . $lun->{path} . "' is 'not online'";
            $long_msg .= " [volume: " . $volume . "]" if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '');
            $self->{output}->output_add(long_msg => $long_msg);
        }
        if (!$lun->{is_mapped}) {
            $self->{luns}->{not_mapped}++;

            my $long_msg = "Lun '" . $lun->{path} . "' is 'not mapped'";
            $long_msg .= " [volume: " . $volume . "]" if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '');
            $self->{output}->output_add(long_msg => $long_msg);
        }
    }
}

1;

__END__

=head1 MODE

Check NetApp luns status.

=over 8

=item B<--filter-*>

Filter lun.
Can be: 'volume' (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'online', 'not-online', 'mapped', 'not-mapped'.

=item B<--critical-*>

Threshold critical.
Can be: 'online', 'not-online', 'mapped', 'not-mapped'.

=back

=cut
