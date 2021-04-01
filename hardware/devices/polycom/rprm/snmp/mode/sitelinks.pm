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

package hardware::devices::polycom::rprm::snmp::mode::sitelinks;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'sitelink', type => 1, cb_prefix_output => 'prefix_sitelink_output', message_multiple => 'All SiteLinks are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'rprm-total-sitelinks', nlabel => 'rprm.sitelinks.total.count', set => {
                key_values => [ { name => 'sitelinks_count' } ],
                output_template => 'Total sitelinks : %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{sitelink} = [
        { label => 'sitelink-status', type => 2, critical_default => '%{sitelink_status} =~ /failed/i', set => {
                key_values => [ { name => 'sitelink_status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_sitelink_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'sitelink-active-calls', nlabel => 'rprm.sitelink.calls.active.count', set => {
                key_values => [ { name => 'sitelink_active_calls' }, { name => 'display' } ],
                output_template => 'current active calls: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'sitelink-bandwidth-used-prct', nlabel => 'rprm.sitelink.bandwidth.used.percentage', set => {
                key_values => [ { name => 'sitelink_bandwidth_used_prct' }, { name => 'display' } ],
                output_template => 'current bandwidth usage: %.2f %%',
                perfdatas => [
                    { unit => '%', template => '%.2f', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'sitelink-bandwidth-total', nlabel => 'rprm.sitelink.bandwidth.total.bytespersecond', set => {
                key_values => [ { name => 'sitelink_bandwidth_total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_bandwidth_total_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'sitelink-callbitrate', nlabel => 'rprm.sitelink.callbitrate.average.ratio', set => {
                key_values => [ { name => 'sitelink_callbitrate' }, { name => 'display' } ],
                output_template => 'Average call bit rate: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'sitelink-packetloss-prct', nlabel => 'rprm.sitelink.packetloss.average.percentage', set => {
                key_values => [ { name => 'sitelink_packetloss_prct' }, { name => 'display' } ],
                output_template => 'Average packetloss: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'sitelink-jitter', nlabel => 'rprm.sitelink.jitter.average.milliseconds', set => {
                key_values => [ { name => 'sitelink_jitter' }, { name => 'display' } ],
                output_template => 'Average jitter time: %.2f ms',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display'  }
                ]
            }
        },
        { label => 'sitelink-delay', nlabel => 'rprm.sitelink.delay.average.milliseconds', set => {
                key_values => [ { name => 'sitelink_delay' }, { name => 'display'} ],
                output_template => 'Average delay time: %.2f ms',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-sitelink:s' => { name => 'filter_sitelink' }
    });

    return $self;
}

sub custom_sitelink_status_output {
    my ($self, %options) = @_;

    return sprintf('Current status: "%s"',  $self->{result_values}->{sitelink_status});
}

sub prefix_sitelink_output {
    my ($self, %options) = @_;

    return "SiteLink '" . $options{instance_value}->{display} . "' ";
}

sub custom_bandwidth_total_output {
     my ($self, %options) = @_;

    my ($bandwidth, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{sitelink_bandwidth_total}, network => 1);

    return sprintf("Total allowed bandwidth: %.2f %s/s", $bandwidth, $unit);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        serviceTopologySiteLinkName               => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.3' },
        serviceTopologySiteLinkStatus             => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.4' },
        serviceTopologySiteLinkCallCount          => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.7' },
        serviceTopologySiteLinkBandwidthUsed      => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.8' },
        serviceTopologySiteLinkBandwidthTotal     => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.9' },
        serviceTopologySiteLinkAverageCallBitRate => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.10' },
        serviceTopologySiteLinkPacketLoss         => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.11' },
        serviceTopologySiteLinkAverageJitter      => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.12' },
        serviceTopologySiteLinkAverageDelay       => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.6.1.13' },
    };

    my %sitelink_status = ( 1 => 'disabled', 2 => 'ok', 3 => 'failed' );
    my $oid_serviceTopologySiteLinkEntry = '.1.3.6.1.4.1.13885.102.1.2.14.6.1';
    my $oid_serviceTopologySiteLinkCount = '.1.3.6.1.4.1.13885.102.1.2.14.5.0';

    my $global_result = $options{snmp}->get_leef(oids => [$oid_serviceTopologySiteLinkCount], nothing_quit => 1);

    $self->{global} = { sitelinks_count => $global_result->{$oid_serviceTopologySiteLinkCount} };

    my $sitelink_result = $options{snmp}->get_table(
        oid => $oid_serviceTopologySiteLinkEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$sitelink_result}) {
        next if ($oid !~ /^$mapping->{serviceTopologySiteLinkName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $sitelink_result, instance => $instance);

        $result->{serviceTopologySiteLinkName} = centreon::plugins::misc::trim($result->{serviceTopologySiteLinkName});
        if (defined($self->{option_results}->{filter_sitelink}) && $self->{option_results}->{filter_sitelink} ne '' &&
            $result->{serviceTopologySiteLinkName} !~ /$self->{option_results}->{filter_sitelink}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{serviceTopologySiteLinkName} . "': no matching filter.", debug => 1);
            next;
        }

        my $sitelink_bandwidth_total = $result->{serviceTopologySiteLinkBandwidthTotal} * 1000000 ; #Mbps
        $result->{serviceTopologySiteLinkName} =~ s/\ /\_/g; #instance perfdata compat

        $self->{sitelink}->{$instance} = {
            display => $result->{serviceTopologySiteLinkName},
            sitelink_status => $sitelink_status{$result->{serviceTopologySiteLinkStatus}},
            sitelink_active_calls => $result->{serviceTopologySiteLinkCallCount},
            sitelink_bandwidth_used_prct => $result->{serviceTopologySiteLinkBandwidthUsed},
            sitelink_bandwidth_total => $sitelink_bandwidth_total,
            sitelink_callbitrate => $result->{serviceTopologySiteLinkAverageCallBitRate},
            sitelink_packetloss_prct => $result->{serviceTopologySiteLinkPacketLoss},
            sitelink_jitter => $result->{serviceTopologySiteLinkAverageJitter},
            sitelink_delay => $result->{serviceTopologySiteLinkAverageDelay}
        };
    }
}

1;

__END__

=head1 MODE

Check Polycom RPRM SiteLinks.

=over 8

=item B<--filter-sitelink>

Filter on one or several SiteLinks (POSIX regexp)

=item B<--warning-sitelink-status>

Custom Warning threshold of the SiteLink state (Default: none)
Syntax: --warning-sitelink-status='%{sitelink_status} =~ /disabled/i'

=item B<--critical-sitelink-status>

Custom Critical threshold of the SiteLink state
(Default: '%{sitelink_status} =~ /failed/i' )
Syntax: --critical-sitelink-status='%{sitelink_status} =~ /failed/i'

=item B<--warning-* --critical-*>

Warning & Critical Thresholds. Possible values:

[GLOBAL] rprm-total-sitelinks

[SITE] sitelink-active-calls, sitelink-bandwidth-used-prct,
sitelink-bandwidth-total, sitelink-callbitrate, sitelink-packetloss-prct,
sitelink-jitter, sitelink-delay

=back

=cut
