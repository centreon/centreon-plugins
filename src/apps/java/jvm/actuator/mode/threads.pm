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

package apps::java::jvm::actuator::mode::threads;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Threads ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'active', nlabel => 'threads.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'daemon', nlabel => 'threads.daemon.count', set => {
                key_values => [ { name => 'daemon' } ],
                output_template => 'daemon: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => '/metrics/jvm.threads.live');
    $self->{global} = { active => $result->{measurements}->[0]->{value} };

    $result = $options{custom}->request_api(endpoint => '/metrics/jvm.threads.daemon');
    $self->{global}->{daemon} = $result->{measurements}->[0]->{value};
}

1;

__END__

=head1 MODE

Check threads.

=over 8

=item B<--warning-*>

Warning threshold.
Can be: 'active', 'daemon'.

=item B<--critical-*>

Critical threshold.
Can be: 'active', 'daemon'.

=back

=cut
