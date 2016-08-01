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

package hardware::ups::powerware::snmp::mode::outputlines;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    voltage => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'voltage', no_value => 0 },
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
    power => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'power', no_value => 0 },
                                      ],
                        output_template => 'Power: %.2f W', output_error_template => 'Power: %s',
                        perfdatas => [
                            { value => 'power_absolute', label => 'power', template => '%.2f',
                              unit => 'W', min => 0, label_extra_instance => 1 },
                        ],
                    }
               },
};

my $maps_counters2 = {
    frequence => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'frequence', no_value => 0 },
                                      ],
                        output_template => 'Frequence: %.2f Hz', output_error_template => 'Frequence: %s',
                        perfdatas => [
                            { value => 'frequence_absolute', label => 'frequence', template => '%.2f',
                              unit => 'Hz', min => 0 },
                        ],
                    }
               },
    load => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'load', no_value => -1 },
                                      ],
                        output_template => 'Load: %.2f %%', output_error_template => 'Load: %s',
                        perfdatas => [
                            { value => 'load_absolute', label => 'load', template => '%.2f',
                              unit => '%', min => 0 },
                        ],
                    }
               },
};

my $oid_xupsOutputVoltageEntry = '.1.3.6.1.4.1.534.1.4.4.1.2'; # in V
my $oid_xupsOutputCurrentEntry = '.1.3.6.1.4.1.534.1.4.4.1.3'; # in A
my $oid_xupsOutputWattsEntry = '.1.3.6.1.4.1.534.1.4.4.1.4'; # in W
my $oid_xupsOutputFrequencyEntry = '.1.3.6.1.4.1.534.1.4.2';
my $oid_xupsOutputFrequency = '.1.3.6.1.4.1.534.1.4.2.0'; # in dHZ
my $oid_xupsOutputLoadEntry = '.1.3.6.1.4.1.534.1.4.1';
my $oid_xupsOutputLoad = '.1.3.6.1.4.1.534.1.4.1.0'; # in %

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
    foreach (keys %{$maps_counters2}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters2->{$_}->{class};
        $maps_counters2->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters2->{$_}->{obj}->set(%{$maps_counters2->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    foreach (keys %{$maps_counters2}) {
        $maps_counters2->{$_}->{obj}->init(option_results => $self->{option_results});
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
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    $self->{multiple} = 1;
    if (scalar(keys %{$self->{instance_selected}}) == 1) {
        $self->{multiple} = 0;
    }
    
    if ($self->{multiple} == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Output Lines are ok.');
    }
    
    foreach my $id (sort keys %{$self->{instance_selected}}) {     
        $self->manage_counters(instance => $id, maps_counters => $maps_counters, label => "Output Line '" . $id . "'");
    }
    
    $self->{instance_selected}->{lines} = { frequence => defined($self->{results}->{$oid_xupsOutputFrequencyEntry}->{$oid_xupsOutputFrequency}) ? $self->{results}->{$oid_xupsOutputFrequencyEntry}->{$oid_xupsOutputFrequency} * 0.1 : 0,
                                            load => defined($self->{results}->{$oid_xupsOutputLoadEntry}->{$oid_xupsOutputLoad}) ? $self->{results}->{$oid_xupsOutputLoadEntry}->{$oid_xupsOutputLoad} : -1 };
    $self->manage_counters(instance => 'lines', maps_counters => $maps_counters2, label => "Output Lines");
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub add_result {
    my ($self, %options) = @_;
    
    $self->{instance_selected}->{$options{instance}} = {} if (!defined($self->{instance_selected}->{$options{instance}}));
    $self->{instance_selected}->{$options{instance}}->{$options{name}} = $self->{results}->{$options{oid}}->{$options{oid} . '.' . $options{instance}};
}

sub manage_selection {
    my ($self, %options) = @_;
 
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_xupsOutputVoltageEntry },
                                                            { oid => $oid_xupsOutputCurrentEntry },
                                                            { oid => $oid_xupsOutputWattsEntry },
                                                            { oid => $oid_xupsOutputFrequencyEntry },
                                                            { oid => $oid_xupsOutputLoadEntry },
                                                         ],
                                                         , nothing_quit => 1);
 
    foreach my $oid (keys %{$self->{results}->{$oid_xupsOutputVoltageEntry}}) {
        $oid =~ /^$oid_xupsOutputVoltageEntry\.(\d)$/;
        $self->add_result(instance => $1, name => 'voltage', oid => $oid_xupsOutputVoltageEntry);
    }
    foreach my $oid (keys %{$self->{results}->{$oid_xupsOutputCurrentEntry}}) {
        $oid =~ /^$oid_xupsOutputCurrentEntry\.(\d)$/;
        $self->add_result(instance => $1, name => 'current', oid => $oid_xupsOutputCurrentEntry);
    }
    foreach my $oid (keys %{$self->{results}->{$oid_xupsOutputWattsEntry}}) {
        $oid =~ /^$oid_xupsOutputWattsEntry\.(\d)$/;
        $self->add_result(instance => $1, name => 'power', oid => $oid_xupsOutputWattsEntry);
    }
    
    if (scalar(keys %{$self->{instance_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No output lines found.");
        $self->{output}->option_exit();
    }    
}

1;

__END__

=head1 MODE

Check Output lines metrics (load, voltage, current and true power) (XUPS-MIB).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'load', 'voltage', 'current', 'power'.
Load is a rate for X phase.

=item B<--critical-*>

Threshold critical.
Can be: 'load', 'voltage', 'current', 'power'.
Load is a rate for X phase.

=back

=cut
