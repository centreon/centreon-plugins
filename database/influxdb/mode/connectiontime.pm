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

package database::influxdb::mode::connectiontime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'connection-time', nlabel => 'connection.time.milliseconds', set => {
                key_values => [ { name => 'connection_time' } ],
                output_template => 'Connection established in %d ms',
                perfdatas => [
                    { value => 'connection_time', template => '%d', unit => 'ms', 
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{custom} = $options{custom};

    my $start = Time::HiRes::time();
    $self->{custom}->request(url_path => '/ping?verbose=true');
    my $end = Time::HiRes::time();
    
    $self->{global}->{connection_time} = ($end - $start) * 1000;
}

1;

__END__

=head1 MODE

Check database connection time.

=over 8

=item B<--warning-connection-time>

Threshold warning in milliseconds.

=item B<--critical-connection-time>

Threshold critical in milliseconds.

=back

=cut
