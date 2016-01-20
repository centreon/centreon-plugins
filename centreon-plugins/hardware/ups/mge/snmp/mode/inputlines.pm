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

package hardware::ups::mge::snmp::mode::inputlines;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my %map_input_status = (
    1 => 'no',
    2 => 'outoftolvolt',
    3 => 'outoftolfreq',
    4 => 'utilityoff',
);

my $maps_counters = {
    voltage => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'voltage', no_value => 0, },
                                      ],
                        output_template => 'Voltage: %.2f V', output_error_template => 'Voltage: %s',
                        perfdatas => [
                            { value => 'voltage_absolute', label => 'voltage', template => '%.2f',
                              unit => 'V', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
    current => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'current', no_value => 0 },
                                      ],
                        output_template => 'Current: %.2f A', output_error_template => 'Current: %s',
                        perfdatas => [
                            { value => 'current_absolute', label => 'current', template => '%.2f',
                              unit => 'A', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
    frequence => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'frequence', no_value => 0, },
                                      ],
                        output_template => 'Frequence: %.2f Hz', output_error_template => 'Frequence: %s',
                        perfdatas => [
                            { value => 'frequence_absolute', label => 'frequence', template => '%.2f',
                              unit => 'Hz', min => 0 },
                        ],
                    }
               },
};

my $oid_upsmgInputPhaseNumEntry = '.1.3.6.1.4.1.705.1.6.1'; 
my $oid_mginputVoltageEntry = '.1.3.6.1.4.1.705.1.6.2.1.2'; # in dV
my $oid_mginputFrequencyEntry = '.1.3.6.1.4.1.705.1.6.2.1.3'; # in dHz
my $oid_mginputCurrentEntry = '.1.3.6.1.4.1.705.1.6.2.1.6'; # in dA
my $oid_upsmgInputBadStatusEntry = '.1.3.6.1.4.1.705.1.6.3';
my $oid_upsmgInputLineFailCauseEntry = '.1.3.6.1.4.1.705.1.6.4';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    $self->{instance_selected} = {};
     
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
}

sub manage_counters {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$options{maps_counters}}) {
        $options{maps_counters}->{$_}->{obj}->set(instance => $options{instance});
    
        my ($value_check) = $options{maps_counters}->{$_}->{obj}->execute(values => $self->{instance_selected}->{$options{instance}});

        # We don't want to display no value
        next if ($value_check == -10);
        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $options{maps_counters}->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $options{maps_counters}->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $options{maps_counters}->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $options{maps_counters}->{$_}->{obj}->perfdata(extra_instance => $self->{multiple});
    }

    $self->{output}->output_add(long_msg => $options{label} . " " . $long_msg);
    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => $options{label} . " " . $short_msg
                                    );
    }
    
    if ($self->{multiple} == 0) {
        $self->{output}->output_add(short_msg => $options{label} . " " . $long_msg);
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Input Line(s) status is ok');
    if (defined($self->{results}->{$oid_upsmgInputBadStatusEntry}->{$oid_upsmgInputBadStatusEntry . '.0'}) &&
        $self->{results}->{$oid_upsmgInputBadStatusEntry}->{$oid_upsmgInputBadStatusEntry . '.0'} == 1) {
        $self->{output}->output_add(severity => 'CRITICAL',
                                    short_msg => sprintf("Input Line(s) status is '%s'", 
                                                         $map_input_status{$self->{results}->{$oid_upsmgInputLineFailCauseEntry}->{$oid_upsmgInputLineFailCauseEntry . '.0'}}));
    }
    
    $self->{multiple} = 1;
    if (scalar(keys %{$self->{instance_selected}}) == 1) {
        $self->{multiple} = 0;
    }
    
    if ($self->{multiple} == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Input Lines are ok');
    }
    
    foreach my $id (sort keys %{$self->{instance_selected}}) {     
        $self->manage_counters(instance => $id, maps_counters => $maps_counters, label => "Input Line '" . $id . "'");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub add_result {
    my ($self, %options) = @_;
    
    $self->{instance_selected}->{$options{instance}} = {} if (!defined($self->{instance_selected}->{$options{instance}}));
    $self->{instance_selected}->{$options{instance}}->{$options{name}} = $self->{results}->{$options{oid}}->{$options{oid} . '.' . $options{instance2}} * 0.1;
}

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_upsmgInputPhaseNumEntry },
                                                            { oid => $oid_mginputVoltageEntry },
                                                            { oid => $oid_mginputFrequencyEntry },
                                                            { oid => $oid_mginputCurrentEntry },
                                                            { oid => $oid_upsmgInputBadStatusEntry },
                                                            { oid => $oid_upsmgInputLineFailCauseEntry },
                                                         ],
                                                         , nothing_quit => 1);

    if (!defined($self->{results}->{$oid_upsmgInputPhaseNumEntry}->{$oid_upsmgInputPhaseNumEntry . '.0'}) || 
        $self->{results}->{$oid_upsmgInputPhaseNumEntry}->{$oid_upsmgInputPhaseNumEntry . '.0'} == 0) {
        $self->{output}->add_option_msg(short_msg => "No input lines found.");
        $self->{output}->option_exit();
    }
    
    my %instances = ();
    # can be 'xxx.1' or 'xxx.1.0' (cannot respect MIB :)
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_mginputVoltageEntry}})) {
        $oid =~ /^$oid_mginputVoltageEntry\.((\d+).*)/;
        if (scalar(keys %instances) < $self->{results}->{$oid_upsmgInputPhaseNumEntry}->{$oid_upsmgInputPhaseNumEntry . '.0'}) {
            $instances{$2} = 1;
            $self->add_result(instance => $2, instance2 => $1, name => 'voltage', oid => $oid_mginputVoltageEntry);
        }
    }
    %instances = ();
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_mginputCurrentEntry}})) {
        $oid =~ /^$oid_mginputCurrentEntry\.((\d+).*)/;
        if (scalar(keys %instances) < $self->{results}->{$oid_upsmgInputPhaseNumEntry}->{$oid_upsmgInputPhaseNumEntry . '.0'}) {
            $instances{$2} = 1;
            $self->add_result(instance => $2, instance2 => $1, name => 'current', oid => $oid_mginputCurrentEntry);
        }
    }
    %instances = ();
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_mginputFrequencyEntry}})) {
        $oid =~ /^$oid_mginputFrequencyEntry\.((\d+).*)/;
        if (scalar(keys %instances) < $self->{results}->{$oid_upsmgInputPhaseNumEntry}->{$oid_upsmgInputPhaseNumEntry . '.0'}) {
            $instances{$2} = 1;
            $self->add_result(instance => $2, instance2 => $1, name => 'frequence', oid => $oid_mginputFrequencyEntry);
        }
    }
    
    if (scalar(keys %{$self->{instance_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No input lines found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Input lines metrics (frequence, voltage, current).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'frequence', 'voltage', 'current'.

=item B<--critical-*>

Threshold critical.
Can be: 'frequence', 'voltage', 'current'.

=back

=cut
