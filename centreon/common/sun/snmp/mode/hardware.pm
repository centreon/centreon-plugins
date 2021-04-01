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

package centreon::common::sun::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = 
        '^(other|unknown|temperature|voltage|current|tachometer|counter|switch|lock|humidity|smokeDetection|presence|airFlow)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['critical', 'CRITICAL'],
            ['major', 'CRITICAL'],
            ['minor', 'WARNING'],
            ['indeterminate', 'OK'],
            ['warning', 'WARNING'],
            ['pending', 'OK'],
            ['cleared', 'OK'],
        ],
    };
    
    $self->{components_path} = 'centreon::common::sun::snmp::mode::components';
    $self->{components_module} = ['entity'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request}, return_type => 1);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
    
    return $self;
}

1;

__END__

=head1 MODE

Check Hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'entity'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=entity,sensor.18

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='entity,sensor..*,CRITICAL,minor'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,20'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,30'

=back

=cut
