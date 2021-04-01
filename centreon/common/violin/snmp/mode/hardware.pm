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

package centreon::common::violin::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        vimm => [
            ['not failed', 'OK'],
            ['failed', 'CRITICAL'],
        ],
        ca => [
            ['ON', 'CRITICAL'],
            ['OFF', 'OK'],
        ],
        psu => [
            ['OFF', 'CRITICAL'],
            ['Absent', 'OK'],
            ['ON', 'OK'],
        ],
        fan => [
            ['OFF', 'CRITICAL'],
            ['Absent', 'OK'],
            ['Low', 'OK'],
            ['Medium', 'OK'],
            ['High', 'WARNING'],
        ],
        gfc => [
            ['Online', 'OK'],
            ['Unconfigured', 'OK'],
            ['Unknown', 'UNKNOWN'],
            ['Not\s*Supported', 'WARNING'],
            ['Dead', 'CRITICAL'],
            ['Lost', 'CRITICAL'],
            ['Failover\s*Failed', 'CRITICAL'],
            ['Failover', 'WARNING'],
        ],
        lfc => [
            ['Online', 'OK'],
            ['Unconfigured', 'OK'],
            ['Unknown', 'UNKNOWN'],
            ['Not\s*Supported', 'WARNING'],
            ['Dead', 'CRITICAL'],
            ['Lost', 'CRITICAL'],
            ['Failover\s*Failed', 'CRITICAL'],
            ['Failover', 'WARNING'],
        ],
    };
    
    $self->{components_path} = 'centreon::common::violin::snmp::mode::components';
    $self->{components_module} = ['ca', 'psu', 'fan', 'vimm', 'temperature', 'gfc', 'lfc'];
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
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub convert_index {
    my ($self, %options) = @_;

    my @results = ();
    my $separator = 32;
    my $result = '';
    foreach (split /\./, $options{value}) {
        if ($_ < $separator) {
            push @results, $result;
            $result = '';
        } else {
            $result .= chr;
        }
    }
    
    push @results, $result;
    return @results;
}

1;

__END__

=head1 MODE

Check components (Fans, Power Supplies, Temperatures, Chassis alarm, vimm, global fc, local fc).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'ca', 'vimm', 'lfc', 'gfc', 'temperature'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan --filter=psu)
Can also exclude specific instance: --filter=fan,41239F00647-A

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=fan,41239F00647-fan02

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='gfc,CRITICAL,^(?!(Online)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='temperature,41239F00647-vimm46,20' --warning='temperature,41239F00647-vimm5.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,25' --warning='temperature,.*,35'

=back

=cut
    
