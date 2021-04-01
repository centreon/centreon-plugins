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

package centreon::common::fortinet::fortigate::snmp::mode::virus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'domain', type => 1, cb_prefix_output => 'prefix_domain_output', message_multiple => 'All virtualdomains virus stats are ok' }
    ];

    $self->{maps_counters}->{domain} = [
        { label => 'virus-detected', nlabel => 'domain.virus.detected.count', set => {
                key_values => [ { name => 'fgAvVirusDetected', diff => 1 }, { name => 'display' } ],
                output_template => 'virus detected: %s',
                perfdatas => [
                    { label => 'virus_detected', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'virus-detected-psec', nlabel => 'domain.virus.detected.persecond', display_ok => 0, set => {
                key_values => [ { name => 'fgAvVirusDetected', per_second => 1 }, { name => 'display' } ],
                output_template => 'virus detected: %.2f/s',
                perfdatas => [
                    { label => 'domain.virus.detected.persecond', template => '%.2f',
                      unit => '/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'virus-blocked', nlabel => 'domain.virus.blocked.count', set => {
                key_values => [ { name => 'fgAvVirusBlocked', diff => 1 }, { name => 'display' } ],
                output_template => 'virus blocked: %s',
                perfdatas => [
                    { label => 'virus_blocked', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'virus-blocked-psec', nlabel => 'domain.virus.blocked.persecond', display_ok => 0, set => {
                key_values => [ { name => 'fgAvVirusBlocked', per_second => 1 }, { name => 'display' } ],
                output_template => 'virus blocked: %.2f/s',
                perfdatas => [
                    { label => 'domain.virus.blocked.persecond', template => '%.2f',
                      unit => '/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
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
    fgAvVirusDetected       => { oid => '.1.3.6.1.4.1.12356.101.8.2.1.1.1' },
    fgAvVirusBlocked        => { oid => '.1.3.6.1.4.1.12356.101.8.2.1.1.2' },
};
my $oid_fgAvStatsEntry = '.1.3.6.1.4.1.12356.101.8.2.1.1';
my $oid_fgVdEntName    = '.1.3.6.1.4.1.12356.101.3.2.1.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_fgVdEntName },
            { oid => $oid_fgAvStatsEntry, end => $mapping->{fgAvVirusBlocked}->{oid} }
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

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_fgAvStatsEntry}, instance => $instance);

        $self->{domain}->{$instance} = $result;
        $self->{domain}->{$instance}->{display} = $snmp_result->{$oid_fgVdEntName}->{$oid};
    }

    if (scalar(keys %{$self->{domain}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'no domain found.');
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "fortinet_fortigate_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virus blocked and detected.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'virus-detected', ''virus-detected-psec', 
'virus-blocked', 'virus-blocked-psec'.

=item B<--filter-name>

Filter virtual domain name (can be a regexp).

=back

=cut
    
