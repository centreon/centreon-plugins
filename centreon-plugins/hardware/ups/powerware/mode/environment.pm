################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package hardware::ups::powerware::mode::environment;

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
    # $options{snmp} = snmp object
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
