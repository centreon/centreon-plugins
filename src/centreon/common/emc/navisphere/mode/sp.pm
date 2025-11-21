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
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        psu => [
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        sp => [
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        cable => [
            ['^(.*Unknown.*)$' => 'WARNING'],
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        cpu => [
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        fan => [
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        io => [
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        lcc => [
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ],
        dimm => [
            ['^(Present|Valid|Empty)$', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'centreon::common::emc::navisphere::mode::spcomponents';
    $self->{components_module} = ['fan', 'lcc', 'psu', 'battery', 'memory', 'cpu', 'iomodule', 'cable'];
}

sub navisphere_execute {
    my ($self, %options) = @_;

    ($self->{response}) = $options{custom}->execute_command(cmd => 'getcrus ' . $self->{option_results}->{getcrus_options});
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

Set option for 'getcrus' command (default: '-all').
'-all' option is for some new flare version.

=item B<--component>

Which component to check (default: '.*').
Can be: 'fan', 'lcc', 'psu', 'battery', 'memory', 'cpu', 'iomodule', 'cable'.

=item B<--filter>

Exclude the items given as a comma-separated list (example: --filter=lcc --filter=fan).
You can also exclude items from specific instances: --filter=fan,1.2

=item B<--absent-problem>

Return an error if a component is not 'present' (default is skipping).
It can be set globally or for a specific instance: --absent-problem='component_name' or --absent-problem='component_name,instance_value'.

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='xxxxx,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Define the warning threshold for temperatures (syntax: type,instance,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Define the critical threshold for temperatures (syntax: type,instance,threshold)
Example: --critical='temperature,.*,40'

=item B<--warning-count-*>

Define the warning threshold for the number of components of one type (replace '*' with the component type).

=item B<--critical-count-*>

Define the critical threshold for the number of components of one type (replace '*' with the component type).

=back

=cut
