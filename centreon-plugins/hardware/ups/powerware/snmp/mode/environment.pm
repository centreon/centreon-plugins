#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::ups::powerware::snmp::mode::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    temperature => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'temperature', no_value => 0, },
                                      ],
                        output_template => 'Ambiant Temperature: %.2f C', output_error_template => 'Ambiant Temperature: %s',
                        perfdatas => [
                            { value => 'temperature_absolute', label => 'temperature', template => '%.2f',
                              unit => 'C' },
                        ],
                    }
               },
    humidity => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'humidity', no_value => 0 },
                                      ],
                        output_template => 'Humidity: %.2f %%', output_error_template => 'Humidity: %s',
                        perfdatas => [
                            { value => 'humidity_absolute', label => 'humidity', template => '%.2f',
                              unit => '%', min => 0, max => 100 },
                        ],
                    }
               },
};

my $oid_xupsEnvironment = '.1.3.6.1.4.1.534.1.6';
my $oid_xupsEnvAmbientTemp = '.1.3.6.1.4.1.534.1.6.1.0'; # in degree centigrade
my $oid_xupsEnvAmbientLowerLimit = '.1.3.6.1.4.1.534.1.6.2.0';
my $oid_xupsEnvAmbientUpperLimit = '.1.3.6.1.4.1.534.1.6.3.0';
my $oid_xupsEnvAmbientHumidity = '.1.3.6.1.4.1.534.1.6.4.0'; # in %

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
    
    foreach (sort keys %{$options{maps_counters}}) {
        $options{maps_counters}->{$_}->{obj}->set(instance => $options{instance});
    
        my ($value_check) = $options{maps_counters}->{$_}->{obj}->execute(values => $self->{instance_selected}->{$options{instance}});

        # We don't want to display no value
        next if ($value_check == -10);
        if ($value_check != 0) {
            next;
        }
        my $exit = $options{maps_counters}->{$_}->{obj}->threshold_check();

        my $output = $options{maps_counters}->{$_}->{obj}->output();
        
        $self->{output}->output_add(severity => $exit,
                                    short_msg => $output
                                    );
        
        $options{maps_counters}->{$_}->{obj}->perfdata();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    $self->manage_counters(instance => 'ambiant', maps_counters => $maps_counters);
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    my $values_ok = 0;
    $self->{instance_selected}->{ambiant} = {}; 
    
    $self->{results} = $self->{snmp}->get_table(oid => $oid_xupsEnvironment,
                                                nothing_quit => 1);
    
    if (defined($self->{results}->{$oid_xupsEnvAmbientTemp}) && $self->{results}->{$oid_xupsEnvAmbientTemp} ne '' &&
        $self->{results}->{$oid_xupsEnvAmbientTemp} != 0) {
        $self->{instance_selected}->{ambiant}->{temperature} = $self->{results}->{$oid_xupsEnvAmbientTemp};
        $values_ok++;
    }
    if (defined($self->{results}->{$oid_xupsEnvAmbientHumidity}) && $self->{results}->{$oid_xupsEnvAmbientHumidity} ne '' &&
        $self->{results}->{$oid_xupsEnvAmbientHumidity} != 0) {
        $self->{instance_selected}->{ambiant}->{humidity} = $self->{results}->{$oid_xupsEnvAmbientHumidity};
        $values_ok++;
    }
    
    if (!defined($self->{option_results}->{'critical-temperature'}) || $self->{option_results}->{'critical-temperature'} eq '') {
        my $crit_val = '';
        $crit_val = $self->{results}->{$oid_xupsEnvAmbientLowerLimit} . ':' if (defined($self->{results}->{$oid_xupsEnvAmbientLowerLimit}) && 
                                                                                $self->{results}->{$oid_xupsEnvAmbientLowerLimit} ne '');
        $crit_val .= $self->{results}->{$oid_xupsEnvAmbientUpperLimit} if (defined($self->{results}->{$oid_xupsEnvAmbientUpperLimit}) && 
                                                                                $self->{results}->{$oid_xupsEnvAmbientUpperLimit} ne '' && $self->{results}->{$oid_xupsEnvAmbientUpperLimit} ne 0);
        $self->{perfdata}->threshold_validate(label => 'critical-temperature', value => $crit_val);
    }
    
    if ($values_ok == 0) {
        $self->{output}->add_option_msg(short_msg => "Cannot get temperature and humidity values.");
        $self->{output}->option_exit();
    }    
}

1;

__END__

=head1 MODE

Check environment (temperature and humidity) (XUPS-MIB).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'temperature', 'humidity'.

=item B<--critical-*>

Threshold critical.
Can be: 'temperature', 'humidity'.

=back

=cut
