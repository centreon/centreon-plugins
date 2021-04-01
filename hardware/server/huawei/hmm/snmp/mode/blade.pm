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

package hardware::server::huawei::hmm::snmp::mode::blade;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(cpu|temperature)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        'default' => [
            ['normal', 'OK'],
            ['minor', 'WARNING'],
            ['major', 'CRITICAL'],
            ['critical', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'hardware::server::huawei::hmm::snmp::mode::components';
    $self->{components_module} = ['cpu', 'disk', 'memory', 'mezz', 'raidcontroller', 'temperature'];
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
        'blade-id:s' => { name => 'blade_id' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{blade_id}) || $self->{option_results}->{blade_id} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set --blade-id option.");
        $self->{output}->option_exit();
    }

    $self->{blade_id} = $self->{option_results}->{blade_id};
}

1;

__END__

=head1 MODE

Check blade components.

=over 8

=item B<--blade-id>

Set blade ID.

=item B<--component>

Which component to check (Default: '.*').
Can be: 'cpu', 'disk', 'memory', 'mezz', 'raidcontroller', 'temperature'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=cpu)
Can also exclude specific instance: --filter=cpu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='cpu,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
    
