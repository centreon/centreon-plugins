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

package network::fiberstore::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} =
        '^(?:fan\.speed)$';

    $self->{cb_hook1} = 'check_version';
    $self->{cb_hook2} = 'get_informations';
    
    $self->{thresholds} = {
        fan => [
            ['active', 'OK'],
            ['deactive', 'OK'],
            ['notInstall', 'OK'],
            ['unsupport', 'UNKNOWN']
        ],
        power => [
            ['noAlert', 'OK'],
            ['alert', 'CRITICAL'],
            ['unsupported', 'OK']
        ],
        slot => [
            ['absent', 'OK'],
            ['creating', 'OK'],
            ['initing', 'OK'],
            ['syncing', 'OK'],
            ['fail', 'CRITICAL'],
            ['ready', 'OK'],
            ['uninit', 'WARNING'],
            ['conflict', 'CRITICAL']
        ],
    };

    $self->{components_path} = 'network::fiberstore::snmp::mode::components';
    $self->{components_module} = ['fan', 'power', 'slot'];
}

sub check_version {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    my $oid_version_legacy = '.1.3.6.1.4.1.27975.1.3.5.0';
    my $oid_version_current = '.1.3.6.1.4.1.52642.1.1.3.5.0';
    my $snmp_result = $self->{snmp}->get_leef(
        oids => [$oid_version_legacy, $oid_version_current],
        nothing_quit => 1
    );
    $self->{branch} = '.1.3.6.1.4.1.52642.1';
    if (!defined($snmp_result->{$oid_version_current})) {
        $self->{branch} = '.1.3.6.1.4.1.27975';
    }

    $self->{output}->output_add(long_msg => 'version: ' . $snmp_result->{ $self->{branch} . '.1.3.5.0' });
}

sub get_informations {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'power', 'slot'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=power)
Can also exclude specific instance: --filter=power,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='fan,CRITICAL,notInstall'

=item B<--warning>

Set warning threshold for 'fan.speed' (syntax: type,regexp,threshold)
Example:  --warning='fan.speed,.*,90'

=item B<--critical>

Set critical threshold for 'fan.speed' (syntax: type,regexp,threshold)
Example: --critical='fan.speed,.*,95'

=back

=cut
