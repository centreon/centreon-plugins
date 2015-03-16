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

package network::cisco::common::mode::ipsla;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::values;
use Math::Complex;

my $maps_counters = {
    0_status  => { class => 'centreon::plugins::values', obj => undef, threshold => 0,
                   set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, 
                                        { name => 'rttMonCtrlAdminTag' },
                                        { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'rttMonCtrlAdminThreshold' },
                                        { name => 'rttMonEchoAdminPrecision' },
                                        { name => 'rttMonLatestRttOperCompletionTime' },
                                        { name => 'rttMonLatestRttOperSense' },
                                        { name => 'rttMonLatestRttOperApplSpecificSense' },
                                      ],
                        closure_custom_calc => \&custom_status_calc,
                        closure_custom_output => \&custom_status_output,
                        closure_custom_perfdata => \&custom_status_perfdata,
                        closure_custom_threshold_check => \&custom_status_threshold,
                    }
                 },
    1_NumberOverThresholds  => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'OverThresholds_1' }, { name => 'OverThresholds_2' }, { name => 'OverThresholds_times' },
                                      ],
                        closure_custom_calc => \&custom_NumberOverThresholds_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Number Over Thresholds : %s',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'number_over_thresholds', value => 'value', template => '%s',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    2_AverageDelaySD   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'OWSumSD_1' }, { name => 'OWSumSD_2' }, { name => 'OWSumSD_times' },
                                        { name => 'NumOfOW_1' }, { name => 'NumOfOW_2' }, { name => 'NumOfOW_times' },
                                      ],
                        closure_custom_calc => \&custom_AverageDelaySD_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Average Delay SD : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'average_delay_sd', value => 'value', template => '%.2f',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    3_AverageDelayDS   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'OWSumDS_1' }, { name => 'OWSumDS_2' }, { name => 'OWSumDS_times' },
                                        { name => 'NumOfOW_1' }, { name => 'NumOfOW_2' }, { name => 'NumOfOW_times' },
                                      ],
                        closure_custom_calc => \&custom_AverageDelayDS_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Average Delay DS : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'average_delay_ds', value => 'value', template => '%.2f',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    4_PacketLossRatio  => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'StatsPacketLossDS_1' }, { name => 'PacketLossDS_2' }, { name => 'PacketLossDS_times' },
                                        { name => 'PacketLossSD_2' }, { name => 'PacketLossSD_2' }, { name => 'PacketLossSD_times' },
                                        { name => 'PacketMIA_1' }, { name => 'PacketMIA_2' }, { name => 'PacketMIA_times' },
                                        { name => 'PacketLateArrival_1' }, { name => 'PacketLateArrival_2' }, { name => 'PacketLateArrival_times' },
                                        { name => 'PacketOutOfSequence_1' }, { name => 'PacketOutOfSequence_2' }, { name => 'PacketOutOfSequence_times' },
                                        { name => 'NumOfRTT_1' }, { name => 'NumOfRTT_2' }, { name => 'NumOfRTT_times' },
                                      ],
                        closure_custom_calc => \&custom_PacketLossRatio_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Packet Loss Ratio : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'packet_loss_ratio', value => 'value', template => '%.2f',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    5_PercentagePacketsPositiveJitter   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'NumOfPositiveSD_1' }, { name => 'NumOfPositiveSD_2' }, { name => 'NumOfPositiveSD_times' },
                                        { name => 'NumOfRTT_1' }, { name => 'NumOfRTT_2' }, { name => 'NumOfRTT_times' },
                                      ],
                        closure_custom_calc => \&custom_PercentagePacketsPositiveJitter_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Percentage of Packets that had Positive Jitter : %.2f %%',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'prct_jitter_per_packet_positive_jitter', value => 'value', template => '%.2f', unit => '%',
                              label_extra_instance => 1, min => 0, max => 100 },
                        ],
                    }
               },
    6_AverageJitterPerPacketPositiveJitter   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'SumOfPositiveSD_1' }, { name => 'SumOfPositiveSD_2' }, { name => 'SumOfPositiveSD_times' },
                                        { name => 'NumOfRTT_1' }, { name => 'NumOfRTT_2' }, { name => 'NumOfRTT_times' },
                                      ],
                        closure_custom_calc => \&custom_AverageJitterPerPacketPositiveJitter_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Average Jitter per Packet that had Positive Jitter : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'average_jitter_per_packet_positive_jitter', value => 'value', template => '%.2f',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    7_PercentagePacketsNegativeJitter   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'NumOfNegativeSD_1' }, { name => 'NumOfNegativeSD_2' }, { name => 'NumOfNegativeSD_times' },
                                        { name => 'NumOfRTT_1' }, { name => 'NumOfRTT_2' }, { name => 'NumOfRTT_times' },
                                      ],
                        closure_custom_calc => \&custom_PercentagePacketsNegativeJitter_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Percentage of Packets that had Negative Jitter : %.2f %%',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'prct_jitter_per_packet_negative_jitter', value => 'value', template => '%.2f', unit => '%',
                              label_extra_instance => 1, min => 0, max => 100 },
                        ],
                    }
               },
    8_AverageJitterPerPacketNegativeJitter   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'SumOfNegativeSD_1' }, { name => 'SumOfNegativeSD_2' }, { name => 'SumOfNegativeSD_times' },
                                        { name => 'NumOfRTT_1' }, { name => 'NumOfRTT_2' }, { name => 'NumOfRTT_times' },
                                      ],
                        closure_custom_calc => \&custom_AverageJitterPerPacketNegativeJitter_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Average Jitter per Packet that had Negative Jitter : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'average_jitter_per_packet_negative_jitter', value => 'value', template => '%.2f',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    9_AverageJitter   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'sumOfPositiveDS_1' }, { name => 'sumOfPositiveDS_2' }, { name => 'sumOfPositiveDS_times' },
                                        { name => 'sumOfNegativeDS_1' }, { name => 'sumOfNegativeDS_2' }, { name => 'sumOfNegativeDS_times' },
                                        { name => 'sumOfPositiveSD_1' }, { name => 'sumOfPositiveSD_2' }, { name => 'sumOfPositiveSD_times' },
                                        { name => 'sumOfNegativeSD_1' }, { name => 'sumOfNegativeSD_2' }, { name => 'sumOfNegativeSD_times' },
                                        { name => 'numOfPositiveDS_1' }, { name => 'numOfPositiveDS_2' }, { name => 'numOfPositiveDS_times' },
                                        { name => 'numOfNegativeDS_1' }, { name => 'numOfNegativeDS_2' }, { name => 'numOfNegativeDS_times' },
                                        { name => 'numOfPositiveSD_1' }, { name => 'numOfPositiveSD_2' }, { name => 'numOfPositiveSD_times' },
                                        { name => 'numOfNegativeSD_1' }, { name => 'numOfNegativeSD_2' }, { name => 'numOfNegativeSD_times' },
                                      ],
                        closure_custom_calc => \&custom_AverageJitter_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Average Jitter : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'average_jitter', value => 'value', template => '%.2f', unit => 'ms',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    10_RTTStandardDeviation   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'RTTSum2High_1' }, { name => 'RTTSum2High_2' }, { name => 'RTTSum2High_times' },
                                        { name => 'RTTSum2Low_1' }, { name => 'RTTSum2Low_2' }, { name => 'RTTSum2Low_times' },
                                        { name => 'NumOfRTT_1' }, { name => 'NumOfRTT_2' }, { name => 'NumOfRTT_times' },
                                        { name => 'RTTSum_1' }, { name => 'RTTSum_2' }, { name => 'RTTSum_times' },
                                      ],
                        closure_custom_calc => \&custom_RTTStandardDeviation_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'Round-Trip Time Standard Deviation : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'rtt_standard_deviation', value => 'value', template => '%.2f', unit => 'ms',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    11_DelaySource2DestinationStandardDeviation   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'OWSum2SDHigh_1' }, { name => 'OWSum2SDHigh_2' },  { name => 'OWSum2SDHigh_times' },
                                        { name => 'OWSum2SDLow_1' }, { name => 'OWSum2SDLow_2' },  { name => 'OWSum2SDLow_times' },
                                        { name => 'NumOfOW_1' }, { name => 'NumOfOW_2' },  { name => 'NumOfOW_times' },
                                        { name => 'OWSumDS_1' }, { name => 'OWSumDS_2' },  { name => 'OWSumDS_times' },
                                      ],
                        closure_custom_calc => \&custom_DelaySource2DestinationStandardDeviation_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'One-Way Delay Source to Destination Standard Deviation : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'delay_src2dest_stdev', value => 'value', template => '%.2f', unit => 'ms',
                              label_extra_instance => 1 },
                        ],
                    }
               },
               
    12_DelayDestination2SourceStandardDeviation   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'OWSum2DSHigh_1' }, { name => 'OWSum2DSHigh_2' }, { name => 'OWSum2DSHigh_times' },
                                        { name => 'OWSum2DSLow_1' }, { name => 'OWSum2DSLow_2' }, { name => 'OWSum2DSLow_times' },
                                        { name => 'NumOfOW_1' }, { name => 'NumOfOW_2' }, { name => 'NumOfOW_times' },
                                        { name => 'OWSumDS_1' }, { name => 'OWSumDS_2' }, { name => 'OWSumDS_times' },
                                      ],
                        closure_custom_calc => \&custom_DelayDestination2SourceStandardDeviation_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'One-Way Delay Destination to Source Standard Deviation : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'delay_dest2src_stdev', value => 'value', template => '%.2f', unit => 'ms',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    13_JitterSource2DestinationStandardDeviation   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'Sum2PositivesSDHigh_1' }, { name => 'Sum2PositivesSDHigh_2' }, { name => 'Sum2PositivesSDHigh_times' },
                                        { name => 'Sum2PositivesSDLow_1' }, { name => 'Sum2PositivesSDLow_2' }, { name => 'Sum2PositivesSDLow_times' },
                                        { name => 'Sum2NegativesSDHigh_1' }, { name => 'Sum2NegativesSdHigh_2' }, { name => 'Sum2NegativesSdHigh_times' },
                                        { name => 'Sum2NegativesSDLow_1' }, { name => 'Sum2NegativesSDLow_2' }, { name => 'Sum2NegativesSDLow_times' },
                                        { name => 'NumOfPositivesSD_1' }, { name => 'NumOfPositivesSD_2' }, { name => 'NumOfPositivesSD_times' },
                                        { name => 'NumOfNegativesSD_1' }, { name => 'NumOfNegativesSD_2' }, { name => 'NumOfNegativesSD_times' },
                                        ],
                        closure_custom_calc => \&custom_JitterSource2DestinationStandardDeviation_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'One-Way Jitter Source to Destination Standard Deviation : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'jitter_src2dest_stdev', value => 'value', template => '%.2f', unit => 'ms',
                              label_extra_instance => 1 },
                        ],
                    }
               },
    14_JitterDestination2SourceStandardDeviation   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'rttMonCtrlAdminStatus' }, { name => 'rttMonCtrlAdminRttType' },
                                        { name => 'Sum2PositivesDSHigh_1' }, { name => 'Sum2PositivesDSHigh_2' }, { name => 'Sum2PositivesDSHigh_times' },
                                        { name => 'Sum2PositivesDSLow_1' }, { name => 'Sum2PositivesDSLow_2' }, { name => 'Sum2PositivesDSLow_times' },
                                        { name => 'Sum2NegativesDSHigh_1' }, { name => 'Sum2NegativesDSHigh_2' }, { name => 'Sum2NegativesDSHigh_times' },
                                        { name => 'Sum2NegativesDSLow_1' }, { name => 'Sum2NegativesDSLow_2' }, { name => 'Sum2NegativesDSLow_times' },
                                        { name => 'NumOfPositivesDS_1' }, { name => 'NumOfPositivesDS_2' }, { name => 'NumOfPositivesDS_times' },
                                        { name => 'NumOfNegativesDS_1' }, { name => 'NumOfNegativesDS_2' }, { name => 'NumOfNegativesDS_times' },
                                        ],
                        closure_custom_calc => \&custom_JitterDestination2SourceStandardDeviation_calc,
                        closure_custom_output => \&custom_generic_output,
                        output_template => 'One-Way Jitter Destination to Source Standard Deviation : %.2f',
                        threshold_use => 'value',
                        perfdatas => [
                            { label => 'jitter_dest2src_stdev', value => 'value', template => '%.2f', unit => 'ms',
                              label_extra_instance => 1 },
                        ],
                    }
               },
};

my $ipsla;
my $thresholds = {
    opersense => [
        ['ok', 'OK'],
        ['.*', 'CRITICAL'],
    ],
    applspecificsense => [
        ['.*', 'OK'],
    ],
};

###### Common func ######

sub get_my_delta {
    my ($self, %options) = @_;
    
    my $value;
    my ($old_time1, $old_time2) = split /_/, $options{old_datas}->{$self->{instance} . '_' . $options{name} . '_times'};
    my ($new_time1, $new_time2) = split /_/, $options{new_datas}->{$self->{instance} . '_' . $options{name} . '_times'};
    if ($old_time1 == $new_time1) {
        $value = $options{new_datas}->{$self->{instance} . '_' . $options{name} . '_1'} - $options{old_datas}->{$self->{instance} . '_' . $options{name} . '_1'} +
                 $options{new_datas}->{$self->{instance} . '_' . $options{name} . '_2'} - $options{old_datas}->{$self->{instance} . '_' . $options{name} . '_2'};
    } else {
        $value = $options{new_datas}->{$self->{instance} . '_' . $options{name} . '_1'} - $options{old_datas}->{$self->{instance} . '_' . $options{name} . '_2'} +
                 $options{new_datas}->{$self->{instance} . '_' . $options{name} . '_2'};
    }
    return $value;
}

sub custom_generic_output {
    my ($self, %options) = @_;
    
    return sprintf($self->{output_template}, $self->{result_values}->{value});
}

###### STATUS ######

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{rttMonCtrlAdminTag};
    }
    $self->{output}->perfdata_add(label => 'completion_time' . $extra_label, unit => $self->{result_values}->{rttMonEchoAdminPrecision},
                                  value => $self->{result_values}->{rttMonLatestRttOperCompletionTime},
                                  min => 0);
}

sub custom_status_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    
    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/) {
        return $status;
    }
   
    $status = $ipsla->get_severity(section => $self->{result_values}->{section}, value => $self->{result_values}->{opersense});
    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = 'Status : ';
    
    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/) {
        $msg .= 'not active (' . $self->{result_values}->{rttMonCtrlAdminStatus} . ')';
        return $msg;
    }
    $msg .= "operation sense is '" . $self->{result_values}->{opersense} . "'";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{rttMonCtrlAdminStatus} = $options{new_datas}->{$self->{instance} . '_rttMonCtrlAdminStatus'};
    $self->{result_values}->{rttMonCtrlAdminTag} = $options{new_datas}->{$self->{instance} . '_rttMonCtrlAdminTag'};
    $self->{result_values}->{rttMonCtrlAdminRttType} = $options{new_datas}->{$self->{instance} . '_rttMonCtrlAdminRttType'};
    $self->{result_values}->{rttMonCtrlAdminThreshold} = $options{new_datas}->{$self->{instance} . '_rttMonCtrlAdminThreshold'};
    $self->{result_values}->{rttMonEchoAdminPrecision} = $options{new_datas}->{$self->{instance} . '_rttMonEchoAdminPrecision'};
    $self->{result_values}->{rttMonLatestRttOperCompletionTime} = $options{new_datas}->{$self->{instance} . '_rttMonLatestRttOperCompletionTime'};
    $self->{result_values}->{rttMonLatestRttOperSense} = $options{new_datas}->{$self->{instance} . '_rttMonLatestRttOperSense'};
    $self->{result_values}->{rttMonLatestRttOperApplSpecificSense} = $options{new_datas}->{$self->{instance} . '_rttMonLatestRttOperApplSpecificSense'};
    $self->{result_values}->{opersense} = $self->{result_values}->{rttMonLatestRttOperSense};
    $self->{result_values}->{section} = 'opersense';
    if ($self->{result_values}->{opersense} =~ /applicationSpecific/i) {
        $self->{result_values}->{opersense} = $self->{result_values}->{rttMonLatestRttOperApplSpecificSense};
        $self->{result_values}->{section} = 'applspecificsense';
    }
    return 0;
}

####### 1 - Number Over Thresholds #######
sub custom_NumberOverThresholds_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = get_my_delta(name => 'OverThresholds');
    return 0;
}

####### 2 - Average Delay SD #######
sub custom_AverageDelaySD_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = get_my_delta(name => 'OWSumSD') / get_my_delta(name => 'NumOfOW');
    return 0;
}

####### 3 - Average Delay DS #######
sub custom_AverageDelayDS_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = get_my_delta(name => 'OWSumDS') / get_my_delta(name => 'NumOfOW');
    return 0;
}

####### 4 - Packet Loss Ratio   #######
sub custom_PacketLossRatio_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = ((get_my_delta(name => 'PacketLossDS') + get_my_delta(name => 'PacketLossSD') + get_my_delta(name => 'PacketMIA')) * 100 ) / 
                                       (get_my_delta(name => 'PacketLossSD') + get_my_delta(name => 'PacketLossDS') + get_my_delta(name => 'PacketMIA') + 
                                        get_my_delta(name => 'PacketLateArrival') + get_my_delta(name => 'PacketOutOfSequence') + get_my_delta(name => 'NumOfRTT'));
    return 0;
}

####### 5 - Percentage of Packets that had Positive Jitter   #######
sub custom_PercentagePacketsPositiveJitter_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = get_my_delta(name => 'NumOfPositiveSD') / get_my_delta(name => 'NumOfRTT');
    return 0;
}

####### 6 - Average Jitter per Packet that had Positive Jitter   #######
sub custom_AverageJitterPerPacketPositiveJitter_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = get_my_delta(name => 'SumOfPositiveSD') / get_my_delta(name => 'NumOfRTT');
    return 0;
}

####### 7 - Percentage of Packets that had Negative Jitter   #######
sub custom_PercentagePacketsNegativeJitter_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = get_my_delta(name => 'NumOfNegativeSD') / get_my_delta(name => 'NumOfRTT');
    return 0;
}

####### 8 - Average Jitter per Packet that had Negative Jitter   #######
sub custom_AverageJitterPerPacketNegativeJitter_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = get_my_delta(name => 'SumOfNegativeSD') / get_my_delta(name => 'NumOfRTT');
    return 0;
}

####### 9 - Average Jitter   #######
sub custom_AverageJitter_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = (get_my_delta(name => 'sumOfPositiveDS') + get_my_delta(name => 'sumOfNegativeDS') + get_my_delta(name => 'sumOfPositiveSD') + get_my_delta(name => 'sumOfNegativeSD')) / 
                                      (get_my_delta(name => 'numOfPositiveDS) + get_my_delta(name => 'numOfNegativeDS') + get_my_delta(name => 'numOfPositiveSD') + get_my_delta(name => 'numOfNegativeSD'));
    return 0;
}

####### 10 - Round-Trip Time Standard Deviation   #######
sub custom_RTTStandardDeviation_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = sqrt ( ((get_my_delta(name => 'RTTSum2High') * 2 ** 32 + get_my_delta(name => 'RTTSum2Low')) 
                                                / get_my_delta(name => 'NumOfRTT')) - (get_my_delta(name => 'RTTSum') / get_my_delta(name => 'NumOfRTT')) ** 2
                                      );
    return 0;
}

####### 11 - One-Way Delay Source to Destination Standard Deviation  #######
sub custom_DelaySource2DestinationStandardDeviation_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = sqrt ( ((get_my_delta(name => 'OWSum2SDHigh') * 2 ** 32 + get_my_delta(name => 'OWSum2SDLow')) / 
                                                get_my_delta(name => 'NumOfOW')) - (get_my_delta(name => 'OWSumSD') / get_my_delta(name => 'NumOfOW')) ** 2
                                      );
    return 0;
}

####### 12 - One-Way Delay Destination to Source Standard Deviation  #######
sub custom_DelayDestination2SourceStandardDeviation_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = sqrt ( ((get_my_delta(name => 'OWSum2DSHigh') * 2 ** 32 + get_my_delta(name => 'OWSum2DSLow')) / 
                                                get_my_delta(name => 'NumOfOW')) - (get_my_delta(name => 'OWSumDS') / get_my_delta(name => 'NumOfOW')) ** 2
                                      );
    return 0;
}

####### 13 - One-Way Jitter Source to Destination Standard Deviation #######
sub custom_JitterSource2DestinationStandardDeviation_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = sqrt ( ((get_my_delta(name => 'Sum2PositivesSDHigh') * 2 ** 32 + get_my_delta(name => 'Sum2PositivesSDLow') + get_my_delta(name => 'Sum2NegativesSDHigh') * 2 ** 32 + get_my_delta(name => 'Sum2NegativesSDLow')) 
                                        / (get_my_delta(name => 'NumOfPositivesSD') + get_my_delta(name => 'NumOfNegativesSD'))) - 
                                        ((get_my_delta(name => 'SumOfPositivesSD') + get_my_delta(name => 'SumOfNegativesSD')) / 
                                        (get_my_delta(name => 'NumOfPositivesSD') + get_my_delta(name => 'NumOfNegativesSD'))) ** 2
                                      );
    return 0;
}

####### 14 - JitterDestination2SourceStandardDeviation #######
sub custom_JitterDestination2SourceStandardDeviation_calc {
    my ($self, %options) = @_;

    if ($self->{result_values}->{rttMonCtrlAdminStatus} !~ /active/ && 
        $self->{result_values}->{rttMonCtrlAdminRttType} !~ /jitter/) {
        return -2;
    }
        
    $self->{result_values}->{value} = sqrt ( ((get_my_delta(name => 'Sum2PositivesDSHigh') * 2 ** 32 + get_my_delta(name => 'Sum2PositivesDSLow') + get_my_delta(name => 'Sum2NegativesDSHigh') * 2 ** 32 + get_my_delta(name => 'Sum2NegativesDSLow')) 
                                        / (get_my_delta(name => 'NumOfPositivesDS') + get_my_delta(name => 'NumOfNegativesDS'))) - 
                                        ((get_my_delta(name => 'SumOfPositivesDS') + get_my_delta(name => 'SumOfNegativesDS')) / 
                                        (get_my_delta(name => 'NumOfPositivesDS') + get_my_delta(name => 'NumOfNegativesDS'))) ** 2
                                      );
    return 0;
}

my $oid_rttMonCtrlAdminEntry        = '.1.3.6.1.4.1.9.9.42.1.2.1.1';
my $oid_rttMonEchoAdminPrecision    = '.1.3.6.1.4.1.9.9.42.1.2.2.1.37';

my $oid_rttMonLatestRttOperEntry    = '.1.3.6.1.4.1.9.9.42.1.2.10.1';

# Packet Loss Ratio (unit: integer):
#    [(RttMonJitterStatsPacketLossDS + RttMonJitterStatsPacketLossSD + RttMonJitterStatsPacketMIA) * 100 ] / 
#           [RttMonJitterStatsPacketLossSD + RttMonJitterStatsPacketLossDS + RttMonJitterStatsPacketMIA + 
#            RttMonJitterStatsPacketLateArrival + RttMonJitterStatsPacketOutOfSequence + RttMonJitterStatsNumOfRTT ]

# Percentage (unit: %):
#    NumOfPositiveSD/NumOfRTT (Percentage of Packets that had Positive Jitter)
#    SumOfPositiveSD/NumOfRTT (Average Jitter per Packet that had Positive Jitter)
#    NumOfNegativeSD/NumOfRTT (Percentage of Packets that had Negative Jitter)
#    SumOfNegativeSD/NumOfRTT (Average Jitter per Packet that had Negative Jitter)
#    
# Average Jitter (unit: ms):
#  jitterSum = sumOfPositiveDS + sumOfNegativeDS + sumOfPositiveSD + sumOfNegativeSD;
#  jitterNum = numOfPositiveDS + numOfNegativeDS + numOfPositiveSD + numOfNegativeSD;
#  avgJitter = jitterSum/jitterNum;

# Delays (unit: ms):
#   RttMonJitterStatsOWSumSD / RttMonJitterStatsNumOfOW
#   RttMonJitterStatsOWSumDS / RttMonJitterStatsNumOfOW

# Round-Trip Time Standard Deviation (unit: ms):
#   Square Root of [ ((RttMonJitterStatsRTTSum2High * 2^32 + RttMonJitterStatsRTTSum2Low) / RttMonJitterStatsNumOfRTT) - (RttMonJitterStatsRTTSum / RttMonJitterStatsNumOfRTT)^2 ]
# One-Way Delay Source to Destination Standard Deviation (unit: ms):
#    Square Root of [ ((RttMonJitterStatsOWSum2SDHigh * 2^32 + RttMonJitterStatsOWSum2SDLow) / RttMonJitterStatsNumOfOW) - (RttMonJitterStatsOWSumSD / RttMonJitterStatsNumOfOW)^2 ]
# One-Way Delay Destination to Source Standard Deviation (unit: ms):
#    Square Root of [ ((RttMonJitterStatsOWSum2DSHigh * 2^32 + RttMonJitterStatsOWSum2DSLow) / RttMonJitterStatsNumOfOW) - (RttMonJitterStatsOWSumDS / RttMonJitterStatsNumOfOW)^2 ]
# One-Way Jitter Source to Destination Standard Deviation (unit: ms):
#    Square Root of [ ((RttMonJitterStatsSum2PositivesSDHigh * 2^32 + RttMonJitterStatsSum2PositivesSDLow + RttMonJitterStatsSum2NegativesSDHigh * 2^32 + RttMonJitterStatsSum2NegativesSDLow) / (RttMonJitterStatsNumOfPositivesSD + RttMonJitterStatsNumOfNegativesSD)) - ((RttMonJitterStatsSumOfPositivesSD + RttMonJitterStatsSumOfNegativesSD) / (RttMonJitterStatsNumOfPositivesSD + RttMonJitterStatsNumOfNegativesSD))^2 ]
# One-Way Jitter Destination to Source Standard Deviation (unit: ms):
#    Square Root of [ ((RttMonJitterStatsSum2PositivesDSHigh * 2^32 + RttMonJitterStatsSum2PositivesDSLow + RttMonJitterStatsSum2NegativesDSHigh * 2^32 + RttMonJitterStatsSum2NegativesDSLow) / (RttMonJitterStatsNumOfPositivesDS + RttMonJitterStatsNumOfNegativesDS)) - ((RttMonJitterStatsSumOfPositivesDS + RttMonJitterStatsSumOfNegativesDS) / (RttMonJitterStatsNumOfPositivesDS + RttMonJitterStatsNumOfNegativesDS))^2 ]

my $oid_rttMonJitterStatsEntry  = '.1.3.6.1.4.1.9.9.42.1.3.5.1';
my $oids_jitter_stats = {
    StatsNumOfRTT          => '.1.3.6.1.4.1.9.9.42.1.3.5.1.4',
    OverThresholds         => '.1.3.6.1.4.1.9.9.42.1.3.5.1.3',
    RTTSum                 => '.1.3.6.1.4.1.9.9.42.1.3.5.1.5',
    RTTSum2Low             => '.1.3.6.1.4.1.9.9.42.1.3.5.1.6',
    RTTSum2High            => '.1.3.6.1.4.1.9.9.42.1.3.5.1.7',
    NumOfOW                => '.1.3.6.1.4.1.9.9.42.1.3.5.1.51',
    OWSumSD                => '.1.3.6.1.4.1.9.9.42.1.3.5.1.41', # low
    OWSumSDHigh            => '.1.3.6.1.4.1.9.9.42.1.3.5.1.67', # high
    OWSumDS                => '.1.3.6.1.4.1.9.9.42.1.3.5.1.46', # low
    OWSumDSHigh            => '.1.3.6.1.4.1.9.9.42.1.3.5.1.68', # high
    SumOfPositivesSD       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.13',
    SumOfNegativesSD       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.19',
    SumOfPositivesDS       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.25',
    SumOfNegativesDS       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.31',
    NumOfNegativesSD       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.18',
    Sum2NegativesSDLow     => '.1.3.6.1.4.1.9.9.42.1.3.5.1.20',
    Sum2NegativesSDHigh    => '.1.3.6.1.4.1.9.9.42.1.3.5.1.21',
    NumOfNegativesDS       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.30',
    Sum2NegativesDSLow     => '.1.3.6.1.4.1.9.9.42.1.3.5.1.32',
    Sum2NegativesDSHigh    => '.1.3.6.1.4.1.9.9.42.1.3.5.1.33',
    NumOfPositivesSD       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.12',
    Sum2PositivesSDLow     => '.1.3.6.1.4.1.9.9.42.1.3.5.1.14',
    Sum2PositivesSDHigh    => '.1.3.6.1.4.1.9.9.42.1.3.5.1.15',
    NumOfPositivesDS       => '.1.3.6.1.4.1.9.9.42.1.3.5.1.24',
    Sum2PositivesDSLow     => '.1.3.6.1.4.1.9.9.42.1.3.5.1.26',
    Sum2PositivesDSHigh    => '.1.3.6.1.4.1.9.9.42.1.3.5.1.27',
    PacketLossSD           => '.1.3.6.1.4.1.9.9.42.1.3.5.1.34',
    PacketLossDS           => '.1.3.6.1.4.1.9.9.42.1.3.5.1.35',
    PacketOutOfSequence    => '.1.3.6.1.4.1.9.9.42.1.3.5.1.36',
    PacketMIA              => '.1.3.6.1.4.1.9.9.42.1.3.5.1.37',
    PacketLateArrival      => '.1.3.6.1.4.1.9.9.42.1.3.5.1.38',
    MaxOfICPIF             => '.1.3.6.1.4.1.9.9.42.1.3.5.1.59',
    MaxOfMOS               => '.1.3.6.1.4.1.9.9.42.1.3.5.1.57',
};

my %map_admin_rtt_type = (
    1 => 'echo1', 2 => 'pathEcho', 3 => 'fileIO', 4 => 'script', 5 => 'udpEcho', 6 => 'tcpConnect',
    7 => 'http', 8 => 'dns', 9 => 'jitter', 10 => 'dlsw', 11 => 'dhcp', 12 => 'ftp',
    13 => 'voip', 14 => 'rtp', 15 => 'lspGroup', 16 => 'icmpjitter', 17 => 'lspPing',
    18 => 'lspTrace', 19 => 'ethernetPing', 20 => 'ethernetJitter',
    21 => 'lspPingPseudowire', 22 => 'video', 23 => 'y1731Delay', 24 => 'y1731Loss', 25 => 'mcastJitter',
);
my %map_admin_status = (
    1 => 'active', 2 => 'notInService', 3 => 'notReady', 4 => 'createAndGo', 5 => 'createAndWait', 6 => 'destroy',
);
my %map_admin_precision = (
    1 => 'milliseconds',
    2 => 'microseconds',
);
my %map_rtt_oper_sense = (
    0 => 'other', 1 => 'ok', 2 => 'disconnected', 3 => 'overThreshold', 4 => 'timeout', 5 => 'busy',
    6 => 'notConnected', 7 => 'dropped', 8 => 'sequenceError', 9 => 'verifyError', 10 => 'applicationSpecific',
    11 => 'dnsServerTimeout', 12 => 'tcpConnectTimeout', 13 => 'httpTransactionTimeout', 14 => 'dnsQueryError',
    15 => 'httpError', 16 => 'error', 17 => 'mplsLspEchoTxError', 18 => 'mplsLspUnreachable',
    19 => 'mplsLspMalformedReq', 20 => 'mplsLspReachButNotFEC', 21 => 'enableOk', 22 => 'enableNoConnect',
    23 => 'enableVersionFail', 24 => 'enableInternalError', 25 => 'enableAbort', 26 => 'enableFail',
    27 => 'enableAuthFail', 28 => 'enableFormatError', 29 => 'enablePortInUse', 30 => 'statsRetrieveOk',
    31 => 'statsRetrieveNoConnect', 32 => 'statsRetrieveVersionFail', 33 => 'statsRetrieveInternalError',
    34 => 'statsRetrieveAbort', 35 => 'statsRetrieveFail', 36 => 'statsRetrieveAuthFail',
    37 => 'statsRetrieveFormatError', 38 => 'statsRetrievePortInUse',
);

my $mapping = {
    rttMonCtrlAdminTag          => { oid => '.1.3.6.1.4.1.9.9.42.1.2.1.1.3' },
    rttMonCtrlAdminRttType      => { oid => '.1.3.6.1.4.1.9.9.42.1.2.1.1.4', map => \%map_admin_rtt_type },
    rttMonCtrlAdminThreshold    => { oid => '.1.3.6.1.4.1.9.9.42.1.2.1.1.5' },
    rttMonCtrlAdminStatus       => { oid => '.1.3.6.1.4.1.9.9.42.1.2.1.1.9', map => \%map_admin_status },
};
my $mapping2 = {
    rttMonEchoAdminPrecision    => { oid => '.1.3.6.1.4.1.9.9.42.1.2.2.1.37', map => \%map_admin_precision },
};
my $mapping3 = {
    rttMonLatestRttOperCompletionTime       => { oid => '.1.3.6.1.4.1.9.9.42.1.2.10.1.1' },
    rttMonLatestRttOperSense                => { oid => '.1.3.6.1.4.1.9.9.42.1.2.10.1.2', map => \%map_rtt_oper_sense },
    rttMonLatestRttOperApplSpecificSense    => { oid => '.1.3.6.1.4.1.9.9.42.1.2.10.1.3' },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-tag:s"          => { name => 'filter_tag', default => '.*' },
                                    "threshold-overload:s@" => { name => 'threshold_overload' },
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);  
    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        next if (defined($maps_counters->{$_}->{threshold}) && $maps_counters->{$_}->{threshold} == 0);
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
    
    $self->{statefile_value}->check_options(%options);
    # to be used on custom function
    $ipsla = $self;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();

    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_cisco_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{datas}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All RTT controls are ok');
    }

    foreach my $id (sort keys %{$self->{datas}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{datas}->{$id},
                                                                     new_datas => $self->{new_datas});

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

        $self->{output}->output_add(long_msg => "RTT '" . $self->{datas}->{$id}->{rttMonCtrlAdminTag} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "RTT '" . $self->{datas}->{$id}->{rttMonCtrlAdminTag} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "RTT '" . $self->{datas}->{$id}->{rttMonCtrlAdminTag} . "' $long_msg");
        }
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_rttMonCtrlAdminEntry },
                                                                   { oid => $oid_rttMonEchoAdminPrecision },
                                                                   { oid => $oid_rttMonLatestRttOperEntry },
                                                                   { oid => $oid_rttMonJitterStatsEntry },
                                                                 ],
                                                         nothing_quit => 1);
    
    $self->{datas} = {};
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rttMonCtrlAdminEntry}})) {
        next if ($oid !~ /^$oid_rttMonCtrlAdminEntry\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rttMonCtrlAdminEntry}, instance => $instance);
        if (defined($self->{datas}->{$result->{rttMonCtrlAdminTag}})) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{rttMonCtrlAdminTag} . "': duplicate (please change the tag name).");
            next;
        }
        if (defined($self->{option_results}->{filter_tag}) && $self->{option_results}->{filter_tag} ne '' &&
            $result->{rttMonCtrlAdminTag} !~ /$self->{option_results}->{filter_tag}/);
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{rttMonCtrlAdminTag} . "': no matching filter.");
            next;
        }
        $self->{datas}->{$result->{rttMonCtrlAdminTag}} = { %{$result} };
        $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$oid_rttMonEchoAdminPrecision}, instance => $instance);
        $self->{datas}->{$result->{rttMonCtrlAdminTag}} = { %{$result}, %{$self->{datas}->{$result->{rttMonCtrlAdminTag}}} };
        
        # there are two entries with rotation: 1 -> last hour, 2 -> current hour.
        foreach my %key (keys %{$oids_jitter_stats}) {
            $self->{datas}->{$result->{rttMonCtrlAdminTag}}->{$key . '_1'} = 0;
            $self->{datas}->{$result->{rttMonCtrlAdminTag}}->{$key . '_2'} = 0;
            my $i = 1;
            my $instances = [];
            foreach my $oid2 ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_rttMonJitterStatsEntry}})) {
                next if ($oid2 !~ /^$oids_jitter_stats->{$key}\.\d+.(\d+)/);
                push @{$instances}, $1;
                $self->{datas}->{$result->{rttMonCtrlAdminTag}}->{$key . '_' . $i} = $self->{results}->{$oid_rttMonJitterStatsEntry}->{$oid2};
                $i++;
            }
            $self->{datas}->{$result->{rttMonCtrlAdminTag}}->{$key . '_times'} = join('_', @{$instances});
        }        
    }
    
    if (scalar(keys %{$self->{datas}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    } 
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }
    
    return $status;
}

1;

__END__

=head1 MODE

Check RTT Controls (CISCO-RTT-MON)

=over 8

=item B<--filter-tag>

Filter tag (Default: '.*')

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='opersense,CRITICAL,^(?!(ok)$)'

=item B<--warning-*>

Threshold warning.
Can be: 'NumberOverThresholds', 'AverageDelaySD', 'AverageDelayDS', 'PacketLossRatio', 
'PercentagePacketsPositiveJitter', 'AverageJitterPerPacketPositiveJitter', 'PercentagePacketsNegativeJitter', 'AverageJitterPerPacketNegativeJitter',
'AverageJitter', 'RTTStandardDeviation', 'DelaySource2DestinationStandardDeviation', 'DelayDestination2SourceStandardDeviation', 
'JitterSource2DestinationStandardDeviation', 'JitterDestination2SourceStandardDeviation'.

=item B<--critical-*>

Threshold critical.
Can be: 'NumberOverThresholds', 'AverageDelaySD', 'AverageDelayDS', 'PacketLossRatio', 
'PercentagePacketsPositiveJitter', 'AverageJitterPerPacketPositiveJitter', 'PercentagePacketsNegativeJitter', 'AverageJitterPerPacketNegativeJitter',
'AverageJitter', 'RTTStandardDeviation', 'DelaySource2DestinationStandardDeviation', 'DelayDestination2SourceStandardDeviation', 
'JitterSource2DestinationStandardDeviation', 'JitterDestination2SourceStandardDeviation'.

=back

=cut
    