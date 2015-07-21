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

package centreon::common::airespace::snmp::mode::apchannelnoise;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {               
    '000_noise-power'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'noise_power' }, { name => 'label_perfdata' }
                                      ],
                        output_template => 'Noise Power : %s dBm',
                        perfdatas => [
                            { label => 'noise_power', value => 'noise_power_absolute', template => '%s', 
                              unit => 'dBm', label_extra_instance => 1, instance_use => 'label_perfdata_absolute' },
                        ],
                    }
               },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"     => { name => 'filter_name' },
                                  "filter-channel:s"  => { name => 'filter_channel' },
                                });

    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
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

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{ap_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All AP noise statistics are ok');
    }
    
    foreach my $id ($self->{snmp}->oid_lex_sort(keys %{$self->{ap_selected}})) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{ap_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
            push @exits, $exit2;

            my $output = $maps_counters->{$_}->{obj}->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => $self->{ap_selected}->{$id}->{display} . " $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => $self->{ap_selected}->{$id}->{display} . " $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => $self->{ap_selected}->{$id}->{display} . " $long_msg");
        }
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my $oid_bsnAPName = '.1.3.6.1.4.1.14179.2.2.1.1.3';
my $oid_bsnAPIfDBNoisePower = '.1.3.6.1.4.1.14179.2.2.15.1.21';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{ap_selected} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_bsnAPName },
                                                                   { oid => $oid_bsnAPIfDBNoisePower },
                                                                 ],
                                                         nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}->{$oid_bsnAPName}}) {
        $oid =~ /^$oid_bsnAPName\.(.*)$/;
        my $instance_mac = $1;        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $self->{results}->{$oid_bsnAPName}->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $self->{results}->{$oid_bsnAPName}->{$oid} . "': no matching filter.");
            next;
        }
        my $instance_end;
        foreach my $oid2 (keys %{$self->{results}->{$oid_bsnAPIfDBNoisePower}}) {
            if ($oid2 =~ /^$oid_bsnAPIfDBNoisePower\.$instance_mac\.(\d+)\.(\d+)$/) {
                $instance_end = $1 . '.' . $2;
                
                if (defined($self->{option_results}->{filter_channel}) && $self->{option_results}->{filter_channel} ne '' &&
                    $instance_end !~ /$self->{option_results}->{filter_channel}/) {
                    $self->{output}->output_add(long_msg => "Skipping channel '" . $instance_end . "': no matching filter.");
                    next;
                }
                
                $self->{ap_selected}->{$instance_mac . '.' . $instance_end} = {
                    display => "AP '" . $self->{results}->{$oid_bsnAPName}->{$oid} . "' Slot $1 Channel $2",
                    label_perfdata => $self->{results}->{$oid_bsnAPName}->{$oid} . "_$1_$2",
                    noise_power => $self->{results}->{$oid_bsnAPIfDBNoisePower}->{$oid_bsnAPIfDBNoisePower . '.' . $instance_mac . '.' . $instance_end}
                };
            }
        }
    }
    
    if (scalar(keys %{$self->{ap_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP Channel Noise.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'noise-power' (dBm).

=item B<--critical-*>

Threshold critical.
Can be: 'noise-power' (dBm).

=item B<--filter-name>

Filter AP name (can be a regexp).

=item B<--filter-channel>

Filter Channel (can be a regexp). Example: --filter-channel='0\.3'

=back

=cut
