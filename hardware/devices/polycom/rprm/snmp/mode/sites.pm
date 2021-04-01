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

package hardware::devices::polycom::rprm::snmp::mode::sites;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'site', type => 1, cb_prefix_output => 'prefix_site_output', message_multiple => 'All sites are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'rprm-total-sites', nlabel => 'rprm.sites.total.count', set => {
                key_values => [ { name => 'sites_count' } ],
                output_template => 'Total sites: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{site} = [
        { label => 'site-active-calls', nlabel => 'rprm.site.calls.active.count', set => {
                key_values => [ { name => 'site_active_calls' }, { name => 'display' } ],
                output_template => 'current active calls: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'site-bandwidth-used-prct', nlabel => 'rprm.site.bandwidth.used.percentage', set => {
                key_values => [ { name => 'site_bandwidth_used_prct' }, { name => 'display' } ],
                output_template => 'current bandwidth usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'site-bandwidth-total', nlabel => 'rprm.site.bandwidth.total.bytespersecond', set => {
                key_values => [ { name => 'site_bandwidth_total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_bandwidth_total_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'site-callbitrate', nlabel => 'rprm.site.callbitrate.average.ratio', set => {
                key_values => [ { name => 'site_callbitrate' }, { name => 'display' } ],
                output_template => 'Average call bit rate: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'site-packetloss-prct', nlabel => 'rprm.site.packetloss.average.percentage', set => {
                key_values => [ { name => 'site_packetloss_prct' }, { name => 'display' } ],
                output_template => 'Average packetloss: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'site-jitter', nlabel => 'rprm.site.jitter.average.milliseconds', set => {
                key_values => [ { name => 'site_jitter' }, { name => 'display' } ],
                output_template => 'Average jitter time: %.2f ms',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'site-delay', nlabel => 'rprm.site.delay.average.milliseconds', set => {
                key_values => [ { name => 'site_delay' }, { name => 'display' } ],
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
        'filter-site:s' => { name => 'filter_site' }
    });

    return $self;
}

sub prefix_site_output {
    my ($self, %options) = @_;

    return "Site '" . $options{instance_value}->{display} . "' ";
}

sub custom_bandwidth_total_output {
     my ($self, %options) = @_;

    my ($bandwidth, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{site_bandwidth_total}, network => 1);
    return sprintf("Total allowed bandwidth: %.2f %s/s", $bandwidth, $unit);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        serviceTopologySiteName               => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.2' },
        serviceTopologySiteTerritoryId        => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.3' },
        serviceTopologySiteCallCount          => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.4' },
        serviceTopologySiteBandwidthUsed      => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.5' },
        serviceTopologySiteBandwidthTotal     => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.6' },
        serviceTopologySiteAverageCallBitRate => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.7' },
        serviceTopologySitePacketLoss         => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.8' },
        serviceTopologySiteAverageJitter      => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.9' },
        serviceTopologySiteAverageDelay       => { oid => '.1.3.6.1.4.1.13885.102.1.2.14.4.1.10' }
    };

    my $oid_serviceTopologySiteEntry = '.1.3.6.1.4.1.13885.102.1.2.14.4.1';
    my $oid_serviceTopologySiteCount = '.1.3.6.1.4.1.13885.102.1.2.14.3.0';

    my $global_result = $options{snmp}->get_leef(oids => [$oid_serviceTopologySiteCount], nothing_quit => 1);

    $self->{global} = { sites_count => $global_result->{$oid_serviceTopologySiteCount} };

    my $site_result = $options{snmp}->get_table(
        oid => $oid_serviceTopologySiteEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$site_result}) {
        next if ($oid !~ /^$mapping->{serviceTopologySiteName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $site_result, instance => $instance);

        $result->{serviceTopologySiteName} = centreon::plugins::misc::trim($result->{serviceTopologySiteName});
        if (defined($self->{option_results}->{filter_site}) && $self->{option_results}->{filter_site} ne '' &&
            $result->{serviceTopologySiteName} !~ /$self->{option_results}->{filter_site}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{serviceTopologySiteName} . "': no matching filter.", debug => 1);
            next;
        }

        my $site_bandwidth_total = $result->{serviceTopologySiteBandwidthTotal} * 1000000 ; #Mbps
        $result->{serviceTopologySiteName} =~ s/\ /\_/g; #instance perfdata compat

        $self->{site}->{$instance} = {
            display => $result->{serviceTopologySiteName},
            site_active_calls => $result->{serviceTopologySiteCallCount},
            site_bandwidth_used_prct => $result->{serviceTopologySiteBandwidthUsed},
            site_bandwidth_total => $site_bandwidth_total,
            site_callbitrate => $result->{serviceTopologySiteAverageCallBitRate},
            site_packetloss_prct => $result->{serviceTopologySitePacketLoss},
            site_jitter => $result->{serviceTopologySiteAverageJitter},
            site_delay => $result->{serviceTopologySiteAverageDelay}
        };
    }
}

1;

__END__

=head1 MODE

Check Polycom RPRM sites.

=over 8

=item B<--filter-site>

Filter on one or several site (POSIX regexp)

=item B<--warning-* --critical-*>

Warning & Critical Thresholds. Possible values:

[GLOBAL] rprm-total-sites

[SITE] site-active-calls, site-bandwidth-used-prct,
site-bandwidth-total, site-callbitrate, site-packetloss-prct,
site-jitter, site-delay

=back

=cut
