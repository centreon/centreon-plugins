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

package snmp_standard::mode::numericvalue;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'oid:s'                   => { name => 'oid' },
        'oid-type:s'              => { name => 'oid_type' },
        'counter-per-seconds'     => { name => 'counter_per_seconds' },
        'warning:s'               => { name => 'warning' },
        'critical:s'              => { name => 'critical' },
        'extracted-pattern:s'     => { name => 'extracted_pattern' },
        'format:s'                => { name => 'format' },
        'format-custom:s'         => { name => 'format_custom' },
        'format-scale'            => { name => 'format_scale' },
        'format-scale-type:s'     => { name => 'format_scale_type' },
        'perfdata-unit:s'         => { name => 'perfdata_unit' },
        'perfdata-name:s'         => { name => 'perfdata_name' },
        'perfdata-min:s'          => { name => 'perfdata_min' },
        'perfdata-max:s'          => { name => 'perfdata_max' },
        'config-json:s'           => { name => 'config_json' },
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{use_statefile} = 0;
    return $self;
}

sub add_data {
    my ($self, %options) = @_;
    
    my $entry = {};    
    return if (!defined($options{data}->{oid}) || $options{data}->{oid} eq '');
    $entry->{oid} = $options{data}->{oid};
    $entry->{oid} = '.' . $entry->{oid} if ($options{data}->{oid} !~ /^\./);

    $entry->{oid_type} = defined($options{data}->{oid_type}) && $options{data}->{oid_type} ne '' ? $options{data}->{oid_type} : 'gauge';    
    if ($entry->{oid_type} !~ /^gauge|counter$/i) {
        $self->{output}->add_option_msg(short_msg => "Wrong oid-type argument '" . $entry->{oid_type} . "' ('gauge' or 'counter').");
        $self->{output}->option_exit();
    }
    
    $entry->{format_scale_type} = defined($options{data}->{format_scale_type}) && $options{data}->{format_scale_type} ne '' ? $options{data}->{format_scale_type} : 'other';  
    if ($entry->{format_scale_type} !~ /^other|network$/i) {
        $self->{output}->add_option_msg(short_msg => "Wrong format-scale-type argument '" . $entry->{format_scale_type} . "' ('other' or 'network').");
        $self->{output}->option_exit();
    }
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-' . $options{num}, value => $options{data}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $options{data}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-' . $options{num}, value => $options{data}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $options{data}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    
    foreach (['oid_type', 'gauge'], ['counter_per_seconds'], ['format', 'current value is %s'], 
             ['format_custom', ''], ['format_scale'],
             ['perfdata_unit', ''], ['perfdata_name', 'value'],
             ['perfdata_min', ''], ['perfdata_max', ''], ['extracted_pattern', '']) {
        if (defined($options{data}->{$_->[0]})) {
            $entry->{$_->[0]} = $options{data}->{$_->[0]};
        } elsif (defined($_->[1])) {
            $entry->{$_->[0]} = $_->[1];
        }
    }
    
    push @{$self->{entries}}, $entry;
    push @{$self->{request_oids}}, $entry->{oid};
    
    if (defined($options{data}->{oid_type}) && $options{data}->{oid_type} =~ /^counter$/i)  {
        $self->{use_statefile} = 1;
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    ($self->{entries}, $self->{oids}) = ([], []);
    if (defined($self->{option_results}->{config_json}) && $self->{option_results}->{config_json} ne '') {
        centreon::plugins::misc::mymodule_load(
            module => 'JSON',
            error_msg => "Cannot load module 'JSON'."
        );
        my $json = JSON->new;
        my $content;
        eval {
            $content = $json->decode($self->{option_results}->{config_json});
        };
        if ($@) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
            $self->{output}->option_exit();
        }
        
        my $i = 0;
        foreach (@$content) {
            $self->add_data(data => $_, num => $i);
            $i++;
        }
    } else {
        $self->add_data(data => $self->{option_results}, num => 0);
    }
    
    if (scalar(@{$self->{entries}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Need to specify an OID.");
        $self->{output}->option_exit(); 
    }
    
    if ($self->{use_statefile} == 1) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub check_data {
    my ($self, %options) = @_;
    
    if (!defined($self->{results}->{$options{entry}->{oid}})) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot find oid:' . $options{entry}->{oid}
        );
        return ;
    }

    my $value = $self->{results}->{$options{entry}->{oid}};
    if (defined($options{entry}->{extracted_pattern}) && $options{entry}->{extracted_pattern} ne '') {
        if ($value =~ /$options{entry}->{extracted_pattern}/ && defined($1)) {
            $value = $1;
        }
    }
    if ($value !~ /^-?\d+(?:\.\d+)?$/) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'oid value is not numeric (' . $value . ')'
        );
        return ;
    }
    
    if ($options{entry}->{oid_type} =~ /^counter$/i)  {
        my $old_timestamp = $self->{statefile_cache}->get(name => 'timestamp');
        my $old_value = $self->{statefile_cache}->get(name => 'value-' . $options{num});
        
        $self->{cache_datas}->{timestamp} = time();
        $self->{cache_datas}->{'value-' . $options{num}} = $value;
        
        if (!defined($old_timestamp)) {
            $self->{output}->output_add(severity => 'OK',
                                        short_msg => "Buffer creation...");
            return ;
        }
        
        # Reboot or counter goes back
        if ($old_value > $value) {
            $old_value = 0;
        }
        $value = $value - $old_value;
        if (defined($options{entry}->{counter_per_seconds})) {
            my $delta_time = $self->{cache_datas}->{timestamp} - $old_timestamp;
            $delta_time = 1 if ($delta_time == 0); # at least 1 sec
            $value = $value / $delta_time;
        }
    }
    
    if ($options{entry}->{format_custom} ne '') {
        $value = eval "$value $options{entry}->{format_custom}";
    }
    
    my $exit = $self->{perfdata}->threshold_check(value => $value, 
                                                  threshold => [ { label => 'critical-' . $options{num}, exit_litteral => 'critical' }, { label => 'warning-' . $options{num}, exit_litteral => 'warning' } ]);
    if (defined($options{entry}->{format_scale})) {
        my ($value_mod, $value_unit) = $self->{perfdata}->change_bytes(value => $value);
        if ($options{entry}->{format_scale_type} =~ /^network$/i) {
            ($value_mod, $value_unit) = $self->{perfdata}->change_bytes(value => $value, network => 1);
        }
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf($options{entry}->{format}, $value_mod . $value_unit));
    } else {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf($options{entry}->{format}, $value));
    }

    $self->{output}->perfdata_add(label => $options{entry}->{perfdata_name}, unit => $options{entry}->{perfdata_unit},
                                  value => $value,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $options{num}),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $options{num}),
                                  min => $options{entry}->{perfdata_min}, max => $options{entry}->{perfdata_max});
}

sub run {
    my ($self, %options) = @_;
    
    if ($self->{use_statefile} == 1) {
        $self->{cache_datas} = {};
        $self->{statefile_cache}->read(statefile => 'snmpstandard_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . md5_hex(join('-', @{$self->{request_oids}})));
    }

    $self->{results} = $options{snmp}->get_leef(oids => $self->{request_oids}, nothing_quit => 1);
    my $num = 0;
    foreach (@{$self->{entries}}) {
        $self->check_data(entry => $_, num => $num);
        $num++;
    }
    
    if ($self->{use_statefile} == 1) {
        $self->{statefile_cache}->write(data => $self->{cache_datas});
    }
        
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check an SNMP numeric value: can be a Counter, Integer, Gauge, TimeTicks.
Use 'stringvalue' mode if you want to check: 
- 'warning' value is 2, 4 and 5.
- 'critical' value is 1.
- 'ok' value is 10.

=over 8

=item B<--oid>

OID value to check (numeric format only).

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--oid-type>

Type of the OID (Default: 'gauge').
Can be 'counter' also. 'counter' will use a retention file.

=item B<--counter-per-seconds>

Convert counter value on a value per seconds (only with type 'counter').

=item B<--extracted-pattern>

Set pattern to extracted a number.

=item B<--format>

Output format (Default: 'current value is %s')

=item B<--format-custom>

Apply a custom change on the value 
(Example to multiply the value: --format-custom='* 8').

=item B<--format-scale>

Scale bytes value. We'll display value in output.

=item B<--format-scale-type>

Could be 'network' (value divide by 1000) or 'other' (divide by 1024) (Default: 'other')

Output format (Default: 'current value is %s')

=item B<--perfdata-unit>

Perfdata unit in perfdata output (Default: '')

=item B<--perfdata-name>

Perfdata name in perfdata output (Default: 'value')

=item B<--perfdata-min>

Minimum value to add in perfdata output (Default: '')

=item B<--perfdata-max>

Maximum value to add in perfdata output (Default: '')

=item B<--config-json>

JSON format to configure the mode. Can check multiple OID.
Example: --config-json='[
{ "oid": ".1.3.6.1.2.1.1.3.0", "perfdata_name": "oid1", "format": "current oid1 value is %s"}, 
{ "oid": ".1.3.6.1.2.1.1.3.2", "perfdata_name": "oid2", "format": "current oid2 value is %s"}
]'

=back

=cut
