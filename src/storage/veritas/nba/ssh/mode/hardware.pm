#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::veritas::nba::ssh::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^temperature$';

    $self->{cb_hook2} = 'ssh_execute';

    $self->{thresholds} = {
        default => [
            ['^ok$', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'storage::veritas::nba::ssh::mode::components';
    $self->{components_module} = ['disk', 'fan', 'psu', 'temperature'];
}

sub ssh_execute {
    my ($self, %options) = @_;

    ($self->{result}) = $options{custom}->execute_scenario(
        request => {
            interactive => 1,
            pty => {
                rows => 800,
                cols => 80
            },
            scenario => [
                { cmd => 'waitfor', options => { Match => 'Main_Menu>', Timeout => 20 } },
                { cmd => 'put', options => { String => "Monitor\n" } },
                { cmd => 'waitfor', options => { Match => 'Monitor>', Timeout => 5 } },
                { cmd => 'put', options => { String => "Hardware ShowHealth StorageShelf all\n" } },
                { cmd => 'waitfor', options => { Match => 'to quit', Timeout => 10 } },
                { cmd => 'put', options => { String => 'f' } },
                { cmd => 'waitfor', options => { Match => 'to quit', Timeout => 10 } },
                { cmd => 'put', options => { String => 'q' } },
                { cmd => 'waitfor', options => { Match => 'Monitor>', Timeout => 10 } },
                { cmd => 'put', options => { String => "exit\n" } },
                { cmd => 'close' }
            ]
        }
    );

    $self->{result} =~ s/\x{1b}\x{5b}\x{37}\x{6d}.*?\x{1b}\x{5b}\x{32}\x{37}\x{6d}//mg; # pager prompt in reverse video (ESC[7m...ESC[27m), can split a table row
    $self->{result} =~ s/\x{1b}\[[0-9;?]*[A-Za-z]//g; # remaining terminal control sequences (cursor moves, screen clears)
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware components (disks, fans, power supplies and temperatures).

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'disk', 'fan', 'psu', 'temperature'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=temperature).
You can also exclude items from specific instances: --filter=C<fan,shelf1\.0>

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='fan,WARNING,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=item B<--critical>

Set critical threshold for 'temperature' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,70'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
