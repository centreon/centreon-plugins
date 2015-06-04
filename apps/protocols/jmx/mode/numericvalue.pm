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

package apps::protocols::jmx::mode::numericvalue;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "mbean-pattern:s"         => { name => 'mbean_pattern' },
                                  "attribute:s@"            => { name => 'attribute' },
                                  "lookup-path:s"           => { name => 'lookup_path' },
                                  "lookup-jpath:s"          => { name => 'lookup_jpath' },
                                  
                                  "type:s@"                 => { name => 'type' },
                                  "counter-per-seconds:s@"  => { name => 'counter_per_seconds' },
                                  "warning:s@"              => { name => 'warning' },
                                  "critical:s@"             => { name => 'critical' },
                                  "format:s@"               => { name => 'format' },
                                  "format-scale:s@"         => { name => 'format_scale' },
                                  "format-scale-unit:s@"    => { name => 'format_scale_unit' },
                                  "perfdata-unit:s@"        => { name => 'perfdata_unit' },
                                  "perfdata-name:s@"        => { name => 'perfdata_name' },
                                  "perfdata-min:s@"         => { name => 'perfdata_min' },
                                  "perfdata-max:s@"         => { name => 'perfdata_max' },
                                });
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{jpath} = undef;
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{mbean_pattern}) || $self->{option_results}->{mbean_pattern} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify mbean-pattern option.");
       $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{attribute}) || scalar($self->{option_results}->{attribute}) == 0) {
        $self->{option_results}->{attribute} = undef;
    }    
    
    if (defined($self->{option_results}->{type})) {
        foreach (@{$self->{option_results}->{type}}) {
            if ($_ =~ /^counter$/) {
                $self->{statefile_cache}->check_options(%options);
                last;
            }
        }
    }
    
    if ((!defined($self->{option_results}->{lookup_jpath}) || $self->{option_results}->{lookup_jpath} eq '') &&
        (!defined($self->{option_results}->{lookup_path}) || $self->{option_results}->{lookup_path} eq '')) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --lookup-path or --lookup-jpath option.");
        $self->{output}->option_exit(); 
    }
    
    if (defined($self->{option_results}->{lookup_jpath}) && $self->{option_results}->{lookup_jpath} ne '') {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'JSON::Path',
                                               error_msg => "Cannot load module 'JSON::Path'.");
        $self->{jpath} = JSON::Path->new($self->{option_results}->{lookup_jpath});
    }
}

sub set_attributes {
    my ($self, %options) = @_;
    
    $self->{attributes} = {};
    $self->{attributes}->{type} = (defined($self->{option_results}->{type})) ? shift(@{$self->{option_results}->{type}}) : 'gauge';
    $self->{attributes}->{counter_per_seconds} = (defined($self->{option_results}->{counter_per_seconds})) ? shift(@{$self->{option_results}->{counter_per_seconds}}) : undef;
    $self->{attributes}->{warning} = (defined($self->{option_results}->{warning})) ? shift(@{$self->{option_results}->{warning}}) : undef;
    $self->{attributes}->{critical} = (defined($self->{option_results}->{critical})) ? shift(@{$self->{option_results}->{critical}}) : undef;
    $self->{attributes}->{format} = (defined($self->{option_results}->{format})) ? shift(@{$self->{option_results}->{format}}) : 'current value' . $options{number} . ' is %s';
    $self->{attributes}->{format_scale} = (defined($self->{option_results}->{format_scale})) ? shift(@{$self->{option_results}->{format_scale}}) : undef;
    $self->{attributes}->{format_scale_unit} = (defined($self->{option_results}->{format_scale_unit})) ? shift(@{$self->{option_results}->{format_scale_unit}}) : 'other';
    $self->{attributes}->{perfdata_unit} = (defined($self->{option_results}->{perfdata_unit})) ? shift(@{$self->{option_results}->{perfdata_unit}}) : '';
    $self->{attributes}->{perfdata_name} = (defined($self->{option_results}->{perfdata_name})) ? shift(@{$self->{option_results}->{perfdata_name}}) : 'value' . $options{number};
    $self->{attributes}->{perfdata_min} = (defined($self->{option_results}->{perfdata_min})) ? shift(@{$self->{option_results}->{perfdata_min}}) : '';
    $self->{attributes}->{perfdata_max} = (defined($self->{option_results}->{perfdata_max})) ? shift(@{$self->{option_results}->{perfdata_max}}) : '';
    
    if ($self->{attributes}->{type} !~ /^gauge|counter$/i) {
        $self->{output}->add_option_msg(short_msg => "Wrong --type argument '" . $self->{attributes}->{type} . "' ('gauge' or 'counter').");
        $self->{output}->option_exit();
    }
    if ($self->{attributes}->{format_scale_unit} !~ /^other|network$/i) {
        $self->{output}->add_option_msg(short_msg => "Wrong --format-scale-unit argument '" . $self->{attributes}->{format_scale_unit} . "' ('other' or 'network').");
        $self->{output}->option_exit();
    }
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-' . $options{number}, value => $self->{attributes}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{attributes}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-' . $options{number}, value => $self->{attributes}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{attributes}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub check_value {
    my ($self, %options) = @_;
    
    my $value = $options{value};
    if ($self->{attributes}->{type} =~ /^counter$/i)  {
        if (!defined($self->{datas})) {
            $self->{datas} = {};
            $self->{statefile_cache}->read(statefile => "jmxstandard_" . $self->{mode} . '_' . md5_hex($self->{connector}->{url} . ' ' . $self->{option_results}->{mbean_pattern}));
        }
    
        my $old_timestamp = $self->{statefile_cache}->get(name => 'timestamp');
        my $old_value = $self->{statefile_cache}->get(name => 'value' . $options{number});
        
        $self->{datas}->{timestamp} = time();
        $self->{datas}->{'value' . $options{number}} = $value;
        if (!defined($old_timestamp)) {
            $self->{output}->output_add(severity => 'OK',
                                        short_msg => "Value " . $options{number} . ": buffer creation...");
            return ;
        }
        
        # Reboot or counter goes back
        if ($old_value > $value) {
            $old_value = 0;
        }
        $value = $value - $old_value;
        if (defined($self->{attributes}->{counter_per_seconds})) {
            my $delta_time = $self->{datas}->{timestamp} - $old_timestamp;
            $delta_time = 1 if ($delta_time == 0); # at least 1 sec
            $value = $value / $delta_time;
        }
    }
    
    my $exit = $self->{perfdata}->threshold_check(value => $value, 
                                  threshold => [ { label => 'critical-' . $options{number}, exit_litteral => 'critical' }, { label => 'warning-' . $options{number}, exit_litteral => 'warning' } ]);
    if (defined($self->{attributes}->{format_scale})) {
        my ($value_mod, $value_unit) = $self->{perfdata}->change_bytes(value => $value);
        if ($self->{attributes}->{format_scale} =~ /^network$/i) {
            ($value_mod, $value_unit) = $self->{perfdata}->change_bytes(value => $value, network => 1);
        }
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf($self->{attributes}->{format}, $value_mod . $value_unit));
    } else {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf($self->{attributes}->{format}, $value));
    }

    $self->{output}->perfdata_add(label => $self->{attributes}->{perfdata_name}, unit => $self->{attributes}->{perfdata_unit},
                                  value => $value,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $options{number}),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $options{number}),
                                  min => $self->{attributes}->{perfdata_min}, max => $self->{attributes}->{perfdata_max});
}

sub find_values {
    my ($self, %options) = @_;
    
    $self->{values} = [];
    if (defined($options{result})) {
        if (!ref($options{result})) {
            push @{$self->{values}}, $options{result} if ($options{result} =~ /^[0-9\.,]+$/);
        } elsif (defined($self->{jpath})) {
            my @values = ();
            
            eval {
                @values = $self->{jpath}->values($options{result});
            };
            if ($@) {
                $self->{output}->add_option_msg(short_msg => "Cannot lookup: $@");
                $self->{output}->option_exit();
            }
            foreach my $value (@values) {
                push @{$self->{values}}, $value if (!ref($value) && $value =~ /^[0-9\.,]+$/);
            }
        }
    }
    
    if (scalar(@{$self->{values}}) == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find numeric values');
        $self->{output}->display();
        $self->{output}->exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{connector} = $options{custom};

    my $result = $self->{connector}->get_attributes(mbean_pattern => $self->{option_results}->{mbean_pattern}, attributes => $self->{option_results}->{attribute}, path => $self->{option_results}->{lookup_path});

    $self->find_values(result => $result);
    for (my $i = 1; $i <= scalar(@{$self->{values}}); $i++) {
        $self->set_attributes(number => $i);
        $self->check_value(value => $self->{values}->[$i - 1], number => $i);
    }
    
    if (defined($self->{datas})) {
        $self->{statefile_cache}->write(data => $self->{datas});
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check an JMX numeric value.
Example:
perl centreon_plugins.pl --plugin=apps::protocols::jmx::plugin --custommode=jolokia --url=http://127.0.0.1/jolokia --mode=numeric-value --mbean-pattern='java.lang:type=Memory' --attribute='HeapMemoryUsage' --lookup-path='used' --format-scale --format-unit='B' --format='HeapMemory Usage used: %s' --perfdata-name='used'

=over 8

=item B<--oid>

OID value to check (numeric format only).

=item B<--lookup-path>

What to lookup (from internal Jmx4Perl). Use --lookup-jpath for complex matching. 

=item B<--lookup-jpath>

What to lookup in JSON response (JSON XPath string)
See: http://goessner.net/articles/JsonPath/

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--oid-type>

Type of the OID (Default: 'gauge').
Can be 'counter' also. 'counter' will use a retention file.

=item B<--counter-per-seconds>

Convert counter value on a value per seconds (only with type 'counter'.

=item B<--format>

Output format (Default: 'current valueX is %s')

=item B<--format-scale>

Scale bytes value. We'll display value in output.

=item B<--format-scale-type>

Could be 'network' (value divide by 1000) or 'other' (divide by 1024) (Default: 'other')

=item B<--perfdata-unit>

Perfdata unit in perfdata output (Default: '')

=item B<--perfdata-name>

Perfdata name in perfdata output (Default: 'valueX')

=item B<--perfdata-min>

Minimum value to add in perfdata output (Default: '')

=item B<--perfdata-max>

Maximum value to add in perfdata output (Default: '')

=back

=cut
