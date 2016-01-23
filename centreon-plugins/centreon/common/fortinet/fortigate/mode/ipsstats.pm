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

package centreon::common::fortinet::fortigate::mode::ipsstats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    '000_intrusions-detected'   => { set => {
                        key_values => [ { name => 'fgIpsIntrusionsDetected', diff => 1 }, { name => 'display' } ],
                        output_template => 'Intrusions detected : %s',
                        perfdatas => [
                            { label => 'intrusions_detected', value => 'fgIpsIntrusionsDetected_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '001_intrusions-blocked'   => { set => {
                        key_values => [ { name => 'fgIpsIntrusionsBlocked', diff => 1 }, { name => 'display' } ],
                        output_template => 'Intrusions blocked : %s',
                        perfdatas => [
                            { label => 'intrusions_blocked', value => 'fgIpsIntrusionsBlocked_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '002_crit-sev-detections'   => { set => {
                        key_values => [ { name => 'fgIpsCritSevDetections', diff => 1 }, { name => 'display' } ],
                        output_template => 'Critical severity intrusions detected : %s',
                        perfdatas => [
                            { label => 'crit_sev_detections', value => 'fgIpsCritSevDetections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '003_high-sev-detections'   => { set => {
                        key_values => [ { name => 'fgIpsHighSevDetections', diff => 1 }, { name => 'display' } ],
                        output_template => 'High severity intrusions detected : %s',
                        perfdatas => [
                            { label => 'high_sev_detections', value => 'fgIpsHighSevDetections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '004_med-sev-detections'   => { set => {
                        key_values => [ { name => 'fgIpsMedSevDetections', diff => 1 }, { name => 'display' } ],
                        output_template => 'Medium severity intrusions detected : %s',
                        perfdatas => [
                            { label => 'med_sev_detections', value => 'fgIpsMedSevDetections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '005_low-sev-detections'   => { set => {
                        key_values => [ { name => 'fgIpsLowSevDetections', diff => 1 }, { name => 'display' } ],
                        output_template => 'Low severity intrusions detected : %s',
                        perfdatas => [
                            { label => 'low_sev_detections', value => 'fgIpsLowSevDetections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '006_info-sev-detections'   => { set => {
                        key_values => [ { name => 'fgIpsInfoSevDetections', diff => 1 }, { name => 'display' } ],
                        output_template => 'Informational severity intrusions detected : %s',
                        perfdatas => [
                            { label => 'info_sev_detections', value => 'fgIpsInfoSevDetections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '007_signature-detections'   => { set => {
                        key_values => [ { name => 'fgIpsSignatureDetections', diff => 1 }, { name => 'display' } ],
                        output_template => 'Signature intrusions detected : %s',
                        perfdatas => [
                            { label => 'signature_detection', value => 'fgIpsSignatureDetections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                        ],
                    }
               },
    '008_anomaly-detections'   => { set => {
                        key_values => [ { name => 'fgIpsAnomalyDetections', diff => 1 }, { name => 'display' } ],
                        output_template => 'Anomaly intrusions detected : %s',
                        perfdatas => [
                            { label => 'anomaly_detections', value => 'fgIpsAnomalyDetections_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
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
        $maps_counters->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
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
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{domain_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All IPS domain statistics are ok');
    }
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "fortinet_fortigate_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('.*')));
    $self->{new_datas}->{last_timestamp} = time();
    
    foreach my $id (sort keys %{$self->{domain_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{domain_selected}->{$id},
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

        $self->{output}->output_add(long_msg => "Domain '" . $self->{domain_selected}->{$id}->{display} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Domain '" . $self->{domain_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Domain '" . $self->{domain_selected}->{$id}->{display} . "' $long_msg");
        }
    }
     
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    fgIpsIntrusionsDetected       => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.1' },
    fgIpsIntrusionsBlocked        => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.2' },
    fgIpsCritSevDetections        => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.3' },
    fgIpsHighSevDetections        => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.4' },
    fgIpsMedSevDetections         => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.5' },
    fgIpsLowSevDetections         => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.6' },
    fgIpsInfoSevDetections        => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.7' },
    fgIpsSignatureDetections      => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.8' },
    fgIpsAnomalyDetections        => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.9' },
};
my $oid_fgIpsStatsEntry = '.1.3.6.1.4.1.12356.101.9.2.1.1';
my $oid_fgVdEntName     = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{domain_selected} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
                                                           { oid => $oid_fgVdEntName},
                                                           { oid => $oid_fgIpsStatsEntry},
                                                         ],
                                                         nothing_quit => 1);
    foreach my $oid (keys %{$self->{results}->{$oid_fgVdEntName}}) {
        next if ($oid !~ /^$oid_fgVdEntName\.(.*)/);
        my $instance = $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $self->{results}->{$oid_fgVdEntName}->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $self->{results}->{$oid_fgVdEntName}->{$oid}  . "': no matching filter.");
            next;
        }
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fgIpsStatsEntry}, instance => $instance);
        
        $self->{domain_selected}->{$instance} = $result;
        $self->{domain_selected}->{$instance}->{display} = $self->{results}->{$oid_fgVdEntName}->{$oid};
    }
    
    if (scalar(keys %{$self->{domain_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual domain IPS statistics.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'intrusions-detected', 'intrusions-blocked', 
'crit-sev-detections', 'high-sev-detections', 'med-sev-detections', 
'low-sev-detections', 'info-sev-detections', 'signature-detections',
'anomaly-detections'.

=item B<--critical-*>

Threshold critical.
Can be: 'intrusions-detected', 'intrusions-blocked', 
'crit-sev-detections', 'high-sev-detections', 'med-sev-detections', 
'low-sev-detections', 'info-sev-detections', 'signature-detections',
'anomaly-detections'.

=item B<--filter-name>

Filter virtual domain name (can be a regexp).

=back

=cut
