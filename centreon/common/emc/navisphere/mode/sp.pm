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

package centreon::common::emc::navisphere::mode::sp;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'navisphere_execute';
    
    $self->{thresholds} = {
        battery => [
            ['^(Not Ready|Testing|Unknown)$', 'WARNING'],
            ['^(?!(Present|Valid)$)', 'CRITICAL'],
            ['.*', 'OK'],
        ],
        psu => [
            ['^(?!(Present|Valid)$)', 'CRITICAL'],
            ['.*', 'OK'],
        ],
        sp => [
            ['^(?!(Present|Valid)$)', 'CRITICAL'],
            ['.*', 'OK'],
        ],
        cable => [
            ['^(.*Unknown.*)$' => 'WARNING'],
            ['^(?!(Present|Valid)$)' => 'CRITICAL'],
            ['.*', 'OK'],
        ],
        cpu => [
            ['^(?!(Present|Valid)$)' => 'CRITICAL'],
            ['.*', 'OK'],
        ],
        fan => [
            ['^(?!(Present|Valid)$)' => 'CRITICAL'],
            ['.*', 'OK'],
        ],
        io => [
            ['^(?!(Present|Valid|Empty)$)' => 'CRITICAL'],
            ['.*', 'OK'],
        ],
        lcc => [
            ['^(?!(Present|Valid)$)' => 'CRITICAL'],
            ['.*', 'OK'],
        ],
        dimm => [
            ['^(?!(Present|Valid)$)' => 'CRITICAL'],
            ['.*', 'OK'],
        ],
    };
    
    $self->{components_path} = 'centreon::common::emc::navisphere::mode::spcomponents';
    $self->{components_module} = ['fan', 'lcc', 'psu', 'battery', 'memory', 'cpu', 'iomodule', 'cable'];
}

sub navisphere_execute {
    my ($self, %options) = @_;
    
    $self->{response} = $options{custom}->execute_command(cmd => 'getcrus ' . $self->{option_results}->{getcrus_options});
    chomp $self->{response};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'getcrus-options:s' => { name => 'getcrus_options', default => '-all' }
    });
    
    return $self;
}

1;

__END__

=head1 MODE

Check status of storage processor.

=over 8

=item B<--getcrus-options>

Set option for 'getcrus' command (Default: '-all').
'-all' option is for some new flare version.

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'lcc', 'psu', 'battery', 'memory', 'cpu', 'iomodule', 'cable'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=lcc --filter=fan)
Can also exclude specific instance: --filter=fan,1.2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=back

=cut
