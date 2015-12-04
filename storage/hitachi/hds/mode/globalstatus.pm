#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package storage::hitachi::hds::snmp::mode::globalstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $mapping_type = {
	0 => 'drive',     
	1 => 'spare drive'
    2 => 'data drive',
    3 => 'ENC',
    5 => 'notUsed',
    6 => 'warning',
    7 => 'Other controller',
    8 => 'UPS',
    9 => 'loop',
    10 =>'path',
    11 =>'NAS Server',
    12 =>'NAS Path',
    13 =>'NAS UPS',
    14 =>'notUsed',
    15 =>'notUsed',
    16 =>'battery',
    17 =>'power supply',
    18 =>'AC',
    19 =>'BK', 
    20 =>'fan',
    21 =>'notUsed',
    22 =>'notUsed',
    23 =>'notUsed',
    24 =>'cache memory',
    25 =>'SATA spare disk',
    26 =>'SATA data drive',
    27 =>'SENC status',
    28 =>'HostConnector',
    29 =>'notUsed',
    30 =>'notUsed',
    31 =>'notUsed',
};

my $mapping_status = {
	0 => 'NOK',
	1 => 'OK',
};

my $thresholds = {
    default => [
        ['NOK', 'CRITICAL'],
        ['OK', 'OK'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"     => { name => 'threshold_overload' },
                                });
    return $self;
}

sub check_treshold_overload {
    my ($self, %options) = @_;

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        if (scalar(@values) < 3) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $instance, $status, $filter);
        if (scalar(@values) == 3) {
            ($section, $status, $filter) = @values;
            $instance = '.*';
        } else {
             ($section, $instance, $status, $filter) = @values;
        }
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status, instance => $instance };
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->check_treshold_overload();
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i && 
                (!defined($options{instance}) || $options{instance} =~ /$_->{instance}/)) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    my $label = defined($options{label}) ? $options{label} : $options{section};
    foreach (@{$thresholds->{$label}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_dfRegressionStatus = '.1.3.6.1.4.1.116.5.11.1.2.2.1.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_dfRegressionStatus], nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK',
                       	        short_msg =>  sprintf("Overall regression status is OK."));
    
    for my $i (0..31) {
	      next if $mapping_type->{$i} eq 'notUsed';
        my $value = $result->{$oid_dfRegressionStatus} & (1 << $i);
    	  $self->{output}->output_add(long_msg =>  sprintf("'%s' state is '%s'", $mapping_type->{$i}, $mapping_status->{$value} ));
		    my $exit = $self->get_severity(section => $mapping_type->{$i}, label => 'default', value => $mapping_status->{$value});
        if ($self->{output}->is_litteral_status(status => $exit) == 0) {
            $self->{output}->output_add(severity => $exit,
	                                      short_msg => sprintf("Problem on '%s'", $mapping_type->{$i}));
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the overall hardware status for Hitachi equipment (Hitachi-DF-RAID-LAN-MIB)

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='drive,OK,.*'

=back

=cut
