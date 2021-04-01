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

package centreon::common::fortinet::fortigate::snmp::mode::ipsstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'domain', type => 1, cb_prefix_output => 'prefix_domain_output', message_multiple => 'All IPS domain statistics are ok' }
    ];

    $self->{maps_counters}->{domain} = [
        { label => 'intrusions-detected', nlabel => 'domain.intrusions.detected.count', set => {
                key_values => [ { name => 'fgIpsIntrusionsDetected', diff => 1 }, { name => 'display' } ],
                output_template => 'Intrusions detected : %s',
                perfdatas => [
                    { label => 'intrusions_detected', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'intrusions-blocked', nlabel => 'domain.intrusions.blocked.count', set => {
                key_values => [ { name => 'fgIpsIntrusionsBlocked', diff => 1 }, { name => 'display' } ],
                output_template => 'Intrusions blocked : %s',
                perfdatas => [
                    { label => 'intrusions_blocked', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'crit-sev-detections', nlabel => 'domain.intrusions.detected.critical.severity.count', set => {
                key_values => [ { name => 'fgIpsCritSevDetections', diff => 1 }, { name => 'display' } ],
                output_template => 'Critical severity intrusions detected : %s',
                perfdatas => [
                    { label => 'crit_sev_detections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'high-sev-detections', nlabel => 'domain.intrusions.detected.high.severity.count', set => {
                key_values => [ { name => 'fgIpsHighSevDetections', diff => 1 }, { name => 'display' } ],
                output_template => 'High severity intrusions detected : %s',
                perfdatas => [
                    { label => 'high_sev_detections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'med-sev-detections', nlabel => 'domain.intrusions.detected.medium.severity.count', set => {
                key_values => [ { name => 'fgIpsMedSevDetections', diff => 1 }, { name => 'display' } ],
                output_template => 'Medium severity intrusions detected : %s',
                perfdatas => [
                    { label => 'med_sev_detections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'low-sev-detections', nlabel => 'domain.intrusions.detected.low.severity.count', set => {
                key_values => [ { name => 'fgIpsLowSevDetections', diff => 1 }, { name => 'display' } ],
                output_template => 'Low severity intrusions detected : %s',
                perfdatas => [
                    { label => 'low_sev_detections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'info-sev-detections', nlabel => 'domain.intrusions.detected.info.severity.count', set => {
                key_values => [ { name => 'fgIpsInfoSevDetections', diff => 1 }, { name => 'display' } ],
                output_template => 'Informational severity intrusions detected : %s',
                perfdatas => [
                    { label => 'info_sev_detections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'signature-detections', nlabel => 'domain.intrusions.detected.signature.count', set => {
                key_values => [ { name => 'fgIpsSignatureDetections', diff => 1 }, { name => 'display' } ],
                output_template => 'Signature intrusions detected : %s',
                perfdatas => [
                    { label => 'signature_detection', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'anomaly-detections', nlabel => 'domain.intrusions.detected.anomaly.count', set => {
                key_values => [ { name => 'fgIpsAnomalyDetections', diff => 1 }, { name => 'display' } ],
                output_template => 'Anomaly intrusions detected : %s',
                perfdatas => [
                    { label => 'anomaly_detections', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_domain_output {
    my ($self, %options) = @_;
    
    return "Domain '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
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
    fgIpsAnomalyDetections        => { oid => '.1.3.6.1.4.1.12356.101.9.2.1.1.9' }
};
my $oid_fgIpsStatsEntry = '.1.3.6.1.4.1.12356.101.9.2.1.1';
my $oid_fgVdEntName     = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fgVdEntName },
            { oid => $oid_fgIpsStatsEntry }
        ],
        nothing_quit => 1
    );

    $self->{domain} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_fgVdEntName}}) {
        next if ($oid !~ /^$oid_fgVdEntName\.(.*)/);
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$oid_fgVdEntName}->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $snmp_result->{$oid_fgVdEntName}->{$oid}  . "': no matching filter.");
            next;
        }

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_fgIpsStatsEntry}, instance => $instance);
        $self->{domain}->{$instance} = $result;
        $self->{domain}->{$instance}->{display} = $snmp_result->{$oid_fgVdEntName}->{$oid};
    }

    if (scalar(keys %{$self->{domain}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No domain found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "fortinet_fortigate_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual domain IPS statistics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'intrusions-detected', 'intrusions-blocked', 
'crit-sev-detections', 'high-sev-detections', 'med-sev-detections', 
'low-sev-detections', 'info-sev-detections', 'signature-detections',
'anomaly-detections'.

=item B<--filter-name>

Filter virtual domain name (can be a regexp).

=back

=cut
