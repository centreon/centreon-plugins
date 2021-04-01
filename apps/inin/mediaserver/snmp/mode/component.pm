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

package apps::inin::mediaserver::snmp::mode::component;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        device => [
            ['unknown', 'UNKNOWN'],
            ['up', 'OK'],
            ['down', 'CRITICAL'],
            ['congested', 'WARNING'],
            ['restarting', 'OK'],
            ['quiescing', 'OK'],
            ['testing', 'OK'],
        ],
    };
    
    $self->{components_path} = 'apps::inin::mediaserver::snmp::mode::components';
    $self->{components_module} = ['device'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, no_load_components => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check hardware devices.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'device'.

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='device,WARNING,restarting'

=back

=cut

package apps::inin::mediaserver::snmp::mode::components::device;

use strict;
use warnings;

my %map_status = (1 => 'unknown', 2 => 'up', 3 => 'down', 4 => 'congested',
    5 => 'restarting', 6 => 'quiescing', 7 => 'testing'
);

my $mapping = {
    i3MsGeneralInfoOperStatus    => { oid => '.1.3.6.1.4.1.2793.8227.1.2', map => \%map_status },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{i3MsGeneralInfoOperStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking devices");
    $self->{components}->{device} = {name => 'devices', total => 0, skip => 0};
    return if ($self->check_filter(section => 'device'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{i3MsGeneralInfoOperStatus}->{oid}}, instance => '0');
    
    return if (!defined($result->{i3MsGeneralInfoOperStatus}));
    $self->{components}->{device}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("device status is '%s' [instance = %s]",
                                                    $result->{i3MsGeneralInfoOperStatus}, '0'));
    my $exit = $self->get_severity(section => 'device', value => $result->{i3MsGeneralInfoOperStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Device status is '%s'", $result->{i3MsGeneralInfoOperStatus}));
    }
}

1;
