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

package hardware::ups::mge::snmp::mode::outputsource;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_upsmgOutput = '.1.3.6.1.4.1.705.1.7';
my $oid_upsmgOutputOnBatteryEntry = '.1.3.6.1.4.1.705.1.7.3';

my %map_output_status = (
    '.1.3.6.1.4.1.705.1.7.3.0' => 'OutputOnBattery', 
    '.1.3.6.1.4.1.705.1.7.4.0' => 'OutputOnByPass', 
    '.1.3.6.1.4.1.705.1.7.5.0' => 'OutputUnavailableByPass',
    '.1.3.6.1.4.1.705.1.7.6.0' => 'OutputNoByPass',
    '.1.3.6.1.4.1.705.1.7.7.0' => 'OutputUtilityOff',
    '.1.3.6.1.4.1.705.1.7.8.0' => 'OutputOnBoost',
    '.1.3.6.1.4.1.705.1.7.9.0' => 'OutputInverterOff',
    '.1.3.6.1.4.1.705.1.7.10.0' => 'OutputOverLoad',
    '.1.3.6.1.4.1.705.1.7.11.0' => 'OutputOverTemp',
    '.1.3.6.1.4.1.705.1.7.12.0' => 'OutputOnBuck',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                "filter-status:s" => { name => 'filter_status', default => '^OutputInverterOff'},
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    my $result = $self->{snmp}->get_table(oid => $oid_upsmgOutput, start => $oid_upsmgOutputOnBatteryEntry, nothing_quit => 1);
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("Output status is ok"));
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %map_output_status)) {
        next if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' && $map_output_status{$oid} =~ /$self->{option_results}->{filter_status}/);
        if (defined($result->{$oid}) && $result->{$oid} == 1) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Output status is '%s'", $map_output_status{$oid}));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check output source status.

=over 8

=item B<--filter-status>

Filter on status. (can be a regexp)
Default: ^OutputInverterOff

=back

=cut
