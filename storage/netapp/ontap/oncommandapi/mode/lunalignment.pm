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

package storage::netapp::ontap::oncommandapi::mode::lunalignment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'luns', type => 0},
    ];
    
    $self->{maps_counters}->{luns} = [
        { label => 'aligned', set => {
                key_values => [ { name => 'aligned' } ],
                output_template => 'Luns aligned: %d',
                perfdatas => [
                    { label => 'aligned', value => 'aligned', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'misaligned', set => {
                key_values => [ { name => 'misaligned' } ],
                output_template => 'Luns misaligned: %d',
                perfdatas => [
                    { label => 'misaligned', value => 'misaligned', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'possibly-misaligned', set => {
                key_values => [ { name => 'possibly_misaligned' } ],
                output_template => 'Luns possibly misaligned: %d',
                perfdatas => [
                    { label => 'possibly_misaligned', value => 'possibly_misaligned', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'indeterminate', set => {
                key_values => [ { name => 'indeterminate' } ],
                output_template => 'Luns indeterminate: %d',
                perfdatas => [
                    { label => 'indeterminate', value => 'indeterminate', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'partial-writes', set => {
                key_values => [ { name => 'partial_writes' } ],
                output_template => 'Luns partial writes: %d',
                perfdatas => [
                    { label => 'partial_writes', value => 'partial_writes', template => '%d',
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
    
    $self->{luns}->{aligned} = 0;
    $self->{luns}->{misaligned} = 0;
    $self->{luns}->{possibly_misaligned} = 0;
    $self->{luns}->{indeterminate} = 0;
    $self->{luns}->{partial_writes} = 0;
    $self->{luns}->{not_mapped} = 0;
    
    foreach my $lun (@{$result}) {
        my $volume = $2 if ($lun->{path} =~ /^\/(\S+)\/(\S+)\/(\S+)\s*/);

        if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '' &&
            defined($volume) && $volume !~ /$self->{option_results}->{filter_volume}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $lun->{path} . "': no matching filter volume '" . $volume . "'", debug => 1);
            next;
        }

        $self->{luns}->{$lun->{alignment}}++;
        
        if ($lun->{alignment} ne "aligned" && $lun->{alignment} ne "indeterminate") {
            my $long_msg = "Lun '" . $lun->{path} . "' is '" . $lun->{alignment} . "'";
            $long_msg .= " [volume: " . $volume . "]" if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '');
            $self->{output}->output_add(long_msg => $long_msg);
        }
    }
}

1;

__END__

=head1 MODE

Check NetApp luns alignment.

=over 8

=item B<--filter-*>

Filter lun.
Can be: 'volume' (can be a regexp).

=item B<--warning-*>

Threshold warning.
'aligned', 'misaligned', 'possibly-misaligned', 'indeterminate', 'partial-writes', 'not-mapped'.

=item B<--critical-*>

Threshold critical.
'aligned', 'misaligned', 'possibly-misaligned', 'indeterminate', 'partial-writes', 'not-mapped'.

=back

=cut
