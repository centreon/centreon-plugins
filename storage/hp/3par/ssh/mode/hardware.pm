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

package storage::hp::3par::ssh::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(battery\.charge|sensor)$';
    
    $self->{cb_hook2} = 'ssh_execute';
    
    $self->{thresholds} = {
        default => [
            ['normal', 'OK'], # disk only
            ['ok', 'OK'],
            ['new', 'OK'],
            ['degraded', 'WARNING'],
            ['failed', 'CRITICAL'],
        ],
        'default.status' => [
            ['enabled', 'OK'],
            ['.*', 'CRITICAL'],
        ],
        'default.state' => [
            ['active', 'OK'],
            ['.*', 'CRITICAL'],
        ],
        port => [
            ['ready', 'OK'],
            ['loss_sync', 'WARNING'],
            ['offline', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'storage::hp::3par::ssh::mode::components';
    $self->{components_module} = ['battery', 'cim', 'port', 'node', 'disk', 'psu', 'sensor', 'wsapi'];
}

sub ssh_execute {
    my ($self, %options) = @_;
    
    ($self->{results}, $self->{exit_code}) = $options{custom}->execute_command(commands => $self->{commands});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    $self->{commands} = [];
    return $self;
}

1;

__END__

=head1 MODE

Check components.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'battery'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=battery --filter=cim)
Can also exclude specific instance: --filter=port,free

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='battery,OK,degraded'

=item B<--warning>

Set warning threshold for 'battery.charge' (syntax: type,regexp,threshold)
Example: --warning='battery.charge,.*,30'

=item B<--critical>

Set critical threshold for 'battery.charge' (syntax: type,regexp,threshold)
Example: --critical='battery.charge,.*,50'

=back

=cut
