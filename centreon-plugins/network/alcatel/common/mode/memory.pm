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

package network::alcatel::common::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "warning:s"   => { name => 'warning', default => '' },
                                  "critical:s"  => { name => 'critical', default => '' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    ($self->{warn1m}, $self->{warn1h}) = split /,/, $self->{option_results}->{warning};
    ($self->{crit1m}, $self->{crit1h}) = split /,/, $self->{option_results}->{critical};
    
    if (($self->{perfdata}->threshold_validate(label => 'warn1m', value => $self->{warn1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1min) threshold '" . $self->{warn1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warn1h', value => $self->{warn1h})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning (1hour) threshold '" . $self->{warn1h} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit1m', value => $self->{crit1m})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1min) threshold '" . $self->{crit1m} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'crit5h', value => $self->{crit5})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical (1hour) threshold '" . $self->{crit1h} . "'.");
       $self->{output}->option_exit();
    }
}

sub check_memory {
    my ($self, %options) = @_;
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $options{'1min'}, threshold => [ { label => 'crit1m', exit_litteral => 'critical' },
                                                                                    { label => 'warn1m', exit_litteral => 'warning' },
                                                                                  ]);

    my $exit2 = $self->{perfdata}->threshold_check(value => $options{'1hour'}, threshold => [ { label => 'crit1h', exit_litteral => 'critical' },
                                                                                     { label => 'warn1h', exit_litteral => 'warning' },  
                                                                                   ]);

    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%s: %.2f%% (1min), %.2f%% (1hour)", $options{name}, $options{'1min'}, $options{'1hour'}));

    $self->{output}->perfdata_add(label => "mem1m" . $options{perf_label} , unit => '%',
                                  value => $options{'1min'},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1m'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1m'),
                                  min => 0, max => 100);
    $self->{output}->perfdata_add(label => "mem1h" . $options{perf_label} , unit => '%',
                                  value => $options{'1hour'},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warn1h'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'crit1h'),
                                  min => 0, max => 100);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_healthDeviceMemory1MinAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.1.10'; # it's '.0' but it's for walk multiple
    my $oid_healthDeviceMemory1HrAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.1.11'; # it's '.0' but it's for walk multiple
    my $oid_healthModuleMemory1MinAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.2.1.1.11';
    my $oid_healthModuleMemory1HrAvg = '.1.3.6.1.4.1.6486.800.1.2.1.16.1.1.2.1.1.12';
    
    my $result = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_healthDeviceMemory1MinAvg },
                                                            { oid => $oid_healthDeviceMemory1HrAvg },
                                                            { oid => $oid_healthModuleMemory1MinAvg },
                                                            { oid => $oid_healthModuleMemory1HrAvg },
                                                           ], nothing_quit => 1);
    
    $self->check_memory(name => 'Device memory', perf_label => '_device', 
                        '1min' => $result->{$oid_healthDeviceMemory1MinAvg}->{$oid_healthDeviceMemory1MinAvg . '.' . 0}, 
                        '1hour' => $result->{$oid_healthDeviceMemory1HrAvg}->{$oid_healthDeviceMemory1HrAvg . '.' . 0});
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$result->{$oid_healthModuleMemory1MinAvg}})) {
        $oid =~ /^$oid_healthModuleMemory1MinAvg\.(.*)$/;
        $self->check_memory(name => "Module memory '$1'", perf_label => "_module_$1", 
                            '1min' => $result->{$oid_healthModuleMemory1MinAvg}->{$oid_healthModuleMemory1MinAvg . '.' . $1}, 
                            '1hour' => $result->{$oid_healthModuleMemory1HrAvg}->{$oid_healthModuleMemory1HrAvg . '.' . $1});
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check memory usage (AlcatelIND1Health.mib).

=over 8

=item B<--warning>

Threshold warning in percent (1m,1h).

=item B<--critical>

Threshold critical in percent (1m,1h).

=back

=cut
