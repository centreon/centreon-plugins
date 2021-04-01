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

package storage::dell::compellent::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:ctrltemp|ctrlvoltage|ctrlfan|encltemp)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['up', 'OK'],
            ['down', 'CRITICAL'],
            ['degraded', 'WARNING']
        ]
    };
    
    $self->{components_path} = 'storage::dell::compellent::snmp::mode::components';
    $self->{components_module} = [
        'ctrl', 'disk', 'diskfolder', 'ctrlfan', 'ctrlpower', 'ctrlvoltage', 'ctrltemp',
        'encl', 'enclfan', 'enclpower', 'encliomod', 'encltemp', 'volume', 'cache', 'server', 'sc'
    ];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { });

    return $self;
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'ctrl', 'disk', 'diskfolder', 'encl', 'ctrlfan', 'ctrlpower', 'ctrlvoltage',
'ctrltemp', 'enclfan', 'enclpower', 'encliomod', 'encltemp', 'volume', 'cache', 'server', 'sc'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=ctrlfan --filter=enclpower)
Can also exclude specific instance: --filter=ctrlfan,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='ctrl,CRITICAL,^(?!(up)$)'

=item B<--warning>

Set warning threshold for 'ctrltemp', 'ctrlfan', 'ctrlvoltage', 'encltemp' (syntax: type,regexp,threshold)
Example: --warning='ctrltemp,1,30'

=item B<--critical>

Set critical threshold for 'ctrltemp', 'ctrlfan', 'ctrlvoltage', 'encltemp' (syntax: type,regexp,threshold)
Example: --critical='ctrltemp,1,50'

=back

=cut
