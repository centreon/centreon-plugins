#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_overload_check_section_option} = '^(fru|operating)$';
    $self->{regexp_threshold_numeric_check_section_option} = '^(fru-temperature)$';
    
    $self->{cb_hook1} = 'get_type';
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        fru => [
            ['unknown', 'UNKNOWN'],
            ['present', 'OK'],
            ['ready', 'OK'],
            ['announce online', 'OK'],
            ['online', 'OK'],
            ['announce offline', 'WARNING'],
            ['offline', 'CRITICAL'],
            ['diagnostic', 'WARNING'],
            ['standby', 'WARNING'],
            ['empty', 'OK'],
        ],
        operating => [
            ['unknown', 'UNKNOWN'],
            ['running', 'OK'], 
            ['ready', 'OK'], 
            ['reset', 'WARNING'],
            ['runningAtFullSpeed', 'WARNING'],
            ['down', 'CRITICAL'],
            ['standby', 'OK'],
        ],
    };
    
    $self->{components_path} = 'network::juniper::common::junos::mode::components';
    $self->{components_module} = ['fru', 'operating'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub get_type {
    my ($self, %options) = @_;

    my $oid_jnxBoxDescr = ".1.3.6.1.4.1.2636.3.1.2.0";
    
    my $result = $options{snmp}->get_leef(oids => [$oid_jnxBoxDescr]);
    
    $self->{env_type} = defined($result->{$oid_jnxBoxDescr}) ? $result->{$oid_jnxBoxDescr} : 'unknown';
    $self->{output}->output_add(long_msg => sprintf("Environment type: %s", $self->{env_type}));
}

1;

__END__

=head1 MODE

Check Hardware (mib-jnx-chassis) (frus, operating).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fru', 'operating'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fru)
Can also exclude specific instance: --filter=fru,7.3.0.0

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fru,7.1.0.0

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='operating,CRITICAL,^(?!(running)$)'

=item B<--warning>

Set warning threshold for fru temperatures (syntax: type,regexp,threshold)
Example: --warning='fru-temperature,.*,30'

=item B<--critical>

Set critical threshold for fru temperatures (syntax: type,regexp,threshold)
Example: --critical='fru-temperature,.*,40'

=back

=cut
    