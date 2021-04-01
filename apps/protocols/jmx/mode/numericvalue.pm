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
                                  "format-scale-type:s@"    => { name => 'format_scale_type' },
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
    $self->{request} = [
         { mbean => $self->{option_results}->{mbean_pattern} }
    ];
    if (!defined($self->{option_results}->{attribute}) || scalar($self->{option_results}->{attribute}) == 0) {
        $self->{option_results}->{attribute} = undef;
    } else {
        $self->{request}->[0]->{attributes} = [];
        foreach (@{$self->{option_results}->{attribute}}) {
            push @{$self->{request}->[0]->{attributes}}, { name => $_, path => $self->{option_results}->{lookup_path}};
        }
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
    $self->{attributes}->{type} = (defined($self->{option_results}->{type}) && scalar(@{$self->{option_results}->{type}}) > 0) ? shift(@{$self->{option_results}->{type}}) : 'gauge';
    $self->{attributes}->{counter_per_seconds} = (defined($self->{option_results}->{counter_per_seconds}) && scalar(@{$self->{option_results}->{counter_per_seconds}}) > 0) ? shift(@{$self->{option_results}->{counter_per_seconds}}) : undef;
    $self->{attributes}->{warning} = (defined($self->{option_results}->{warning}) && scalar(@{$self->{option_results}->{warning}}) > 0) ? shift(@{$self->{option_results}->{warning}}) : undef;
    $self->{attributes}->{critical} = (defined($self->{option_results}->{critical}) && scalar(@{$self->{option_results}->{critical}}) > 0) ? shift(@{$self->{option_results}->{critical}}) : undef;
    $self->{attributes}->{format} = (defined($self->{option_results}->{format}) && scalar(@{$self->{option_results}->{format}}) > 0) ? shift(@{$self->{option_results}->{format}}) : 'current value' . $options{number} . ' is %s';
    $self->{attributes}->{format_scale} = (defined($self->{option_results}->{format_scale}) && scalar(@{$self->{option_results}->{format_scale}}) > 0) ? shift(@{$self->{option_results}->{format_scale}}) : undef;
    $self->{attributes}->{format_scale_type} = (defined($self->{option_results}->{format_scale_type}) && scalar(@{$self->{option_results}->{format_scale_type}}) > 0) ? shift(@{$self->{option_results}->{format_scale_type}}) : 'other';
    $self->{attributes}->{perfdata_unit} = (defined($self->{option_results}->{perfdata_unit}) && scalar(@{$self->{option_results}->{perfdata_unit}}) > 0) ? shift(@{$self->{option_results}->{perfdata_unit}}) : '';
    $self->{attributes}->{perfdata_name} = (defined($self->{option_results}->{perfdata_name}) && scalar(@{$self->{option_results}->{perfdata_name}}) > 0) ? shift(@{$self->{option_results}->{perfdata_name}}) : 'value' . $options{number};
    $self->{attributes}->{perfdata_min} = (defined($self->{option_results}->{perfdata_min}) && scalar(@{$self->{option_results}->{perfdata_min}}) > 0) ? shift(@{$self->{option_results}->{perfdata_min}}) : '';
    $self->{attributes}->{perfdata_max} = (defined($self->{option_results}->{perfdata_max}) && scalar(@{$self->{option_results}->{perfdata_max}}) > 0) ? shift(@{$self->{option_results}->{perfdata_max}}) : '';
    
    if ($self->{attributes}->{type} !~ /^gauge|counter$/i) {
        $self->{output}->add_option_msg(short_msg => "Wrong --type argument '" . $self->{attributes}->{type} . "' ('gauge' or 'counter').");
        $self->{output}->option_exit();
    }
    if ($self->{attributes}->{format_scale_type} !~ /^other|network$/i) {
        $self->{output}->add_option_msg(short_msg => "Wrong --format-scale-unit argument '" . $self->{attributes}->{format_scale_type} . "' ('other' or 'network').");
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
            $self->{statefile_cache}->read(statefile => "jmxstandard_" . $self->{mode} . '_' . md5_hex($self->{connector}->get_connection_info() . ' ' . $self->{option_results}->{mbean_pattern}));
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
        if ($self->{attributes}->{format_scale_type} =~ /^network$/i) {
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
        if (defined($self->{option_results}->{attribute})) {
            foreach (@{$self->{option_results}->{attribute}}) {
                if (defined($options{result}->{$self->{option_results}->{mbean_pattern}}->{$_}) && !ref($options{result}->{$self->{option_results}->{mbean_pattern}}->{$_})) {
                    push @{$self->{values}}, $options{result}->{$self->{option_results}->{mbean_pattern}}->{$_} if ($options{result}->{$self->{option_results}->{mbean_pattern}}->{$_} =~ /^[0-9\.,]+$/);
                }
            }
        }
        if (defined($self->{jpath})) {
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
    $self->{connector} = $options{custom};

    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
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
perl centreon_plugins.pl --plugin=apps::protocols::jmx::plugin --custommode=jolokia --url=http://127.0.0.1/jolokia --mode=numeric-value --mbean-pattern='java.lang:type=Memory' --attribute='HeapMemoryUsage' --lookup-path='used' --format-scale --format='HeapMemory Usage used: %s' --perfdata-unit='B' --perfdata-name='used'

=over 8

=item B<--lookup-path>

What to lookup (from internal Jmx4Perl). Use --lookup-jpath for complex matching. 

=item B<--lookup-jpath>

What to lookup in JSON response (JSON XPath string)
See: http://goessner.net/articles/JsonPath/

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--type>

Type (Default: 'gauge').
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
