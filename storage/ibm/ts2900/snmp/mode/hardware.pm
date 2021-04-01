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

package storage::ibm::ts2900::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        default => [
            ['unknown', 'UNKNOWN'],
            ['ok', 'OK'],
            ['warning', 'WARNING'],
            ['failed', 'CRITICAL'],
            ['needClean', 'WARNING'], # for drive only
        ],
    };
    
    $self->{components_path} = 'storage::ibm::ts2900::snmp::mode::components';
    $self->{components_module} = ['robot', 'drive', 'ctrl', 'ctrlpower', 'magazine'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    my $oid_contStatusEntry = '.1.3.6.1.4.1.2.6.219.2.2.1.1';
    my $oid_drvStatusEntry = '.1.3.6.1.4.1.2.6.219.2.2.2.1';
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_contStatusEntry }, { oid => $oid_drvStatusEntry } ], return_type => 1);
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'robot', 'drive', 'ctrl', 'ctrlpower', 'magazine'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=ctrl,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='drive,OK,needClean'

=back

=cut

package storage::ibm::ts2900::snmp::mode::components::common;

my %map_default_status = (1 => 'unknown', 2 => 'ok', 3 => 'warning', 4 => 'failed');

sub check {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => "Checking " . $options{description});
    $self->{components}->{$options{section}} = {name => $options{section}, total => 0, skip => 0};
    return if ($self->check_filter(section => $options{section}));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}})) {
        next if ($oid !~ /^$options{mapping}->{$options{status}}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $options{mapping}, results => $self->{results}, instance => $instance);
        
        next if ($self->check_filter(section => $options{section}, instance => $instance));

        $self->{components}->{$options{section}}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("%s '%s' status is '%s' [instance = %s]",
                                                        $options{description}, $instance, $result->{$options{status}}, $instance));
        my $exit = $self->get_severity(label => 'default', section => $options{section}, value => $result->{$options{status}});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s '%s' status is '%s'", $options{description}, $instance, $result->{$options{status}}));
        }
    }
}

package storage::ibm::ts2900::snmp::mode::components::robot;

use strict;
use warnings;

my $mapping_robot = {
    robotStatus => { oid => '.1.3.6.1.4.1.2.6.219.2.2.1.1.6', map => \%map_default_status },
};

sub load {}

sub check {
    my ($self) = @_;

    storage::ibm::ts2900::snmp::mode::components::common::check($self, 
        section => 'robot', mapping => $mapping_robot, description => 'robot', status => 'robotStatus');
}

package storage::ibm::ts2900::snmp::mode::components::ctrl;

use strict;
use warnings;

my $mapping_ctrl = {
    contState => { oid => '.1.3.6.1.4.1.2.6.219.2.2.1.1.7', map => \%map_default_status },
};

sub load {}

sub check {
    my ($self) = @_;

    storage::ibm::ts2900::snmp::mode::components::common::check($self, 
        section => 'ctrl', mapping => $mapping_ctrl, description => 'controller', status => 'contState');
}

package storage::ibm::ts2900::snmp::mode::components::ctrlpower;

use strict;
use warnings;

my $mapping_ctrlpower = {
    contPowerStatus => { oid => '.1.3.6.1.4.1.2.6.219.2.2.1.1.2', map => \%map_default_status },
};

sub load {}

sub check {
    my ($self) = @_;

    storage::ibm::ts2900::snmp::mode::components::common::check($self, 
        section => 'ctrlpower', mapping => $mapping_ctrlpower, description => 'controller power', status => 'contPowerStatus');
}

package storage::ibm::ts2900::snmp::mode::components::magazine;

use strict;
use warnings;

my $mapping_magazine = {
    magStatus => { oid => '.1.3.6.1.4.1.2.6.219.2.2.1.1.4', map => \%map_default_status },
};

sub load {}

sub check {
    my ($self) = @_;

    storage::ibm::ts2900::snmp::mode::components::common::check($self, 
        section => 'magazine', mapping => $mapping_magazine, description => 'magazine', status => 'magStatus');
}

package storage::ibm::ts2900::snmp::mode::components::drive;

use strict;
use warnings;

my %map_drive_status = (1 => 'unknown', 2 => 'ok', 3 => 'needClean', 4 => 'warning', 5 => 'failed');

my $mapping_drive = {
    driveStatus => { oid => '.1.3.6.1.4.1.2.6.219.2.2.2.1.3', map => \%map_drive_status },
};

sub load {}

sub check {
    my ($self) = @_;

    storage::ibm::ts2900::snmp::mode::components::common::check($self, 
        section => 'drive', mapping => $mapping_drive, description => 'drive', status => 'driveStatus');
}
