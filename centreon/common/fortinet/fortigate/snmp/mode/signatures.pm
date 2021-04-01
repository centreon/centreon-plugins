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

package centreon::common::fortinet::fortigate::snmp::mode::signatures;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX qw(mktime floor);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'av', type => 0, cb_prefix_output => 'prefix_av_output' },
        { name => 'avet', type => 0, cb_prefix_output => 'prefix_avet_output' },
        { name => 'ips', type => 0, cb_prefix_output => 'prefix_ips_output' },
        { name => 'ipset', type => 0, cb_prefix_output => 'prefix_ipset_output' }
    ];

    $self->{maps_counters}->{av} = [
        { label => 'av', set => {
                key_values => [ { name => 'human' }, { name => 'value' }  ],
                threshold_use => 'value',
                output_template => "last refresh is: '%s'",
                perfdatas => [
                    { label => 'av_update', value => 'value',
                      template => '%d', min => 0, unit => 's' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{avet} = [
        { label => 'avet', set => {
                key_values => [ { name => 'human' }, { name => 'value' }  ],
                threshold_use => 'value',
                output_template => "last refresh is: '%s'",
                perfdatas => [
                    { label => 'avet_update', value => 'value',
                      template => '%d', min => 0, unit => 's' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ips} = [
        { label => 'ips', set => {
                key_values => [ { name => 'human' }, { name => 'value' } ],
                threshold_use => 'value',
                output_template => "last refresh is: '%s'",
                perfdatas => [
                    { label => 'ips_update', value => 'value',
                      template => '%d', min => 0, unit => 's' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ipset} = [
        { label => 'ipset', set => {
                key_values => [ { name => 'human' }, { name => 'value' } ],
                threshold_use => 'value',
                output_template => "last refresh is: '%s'",
                perfdatas => [
                    { label => 'ipset_update', value => 'value',
                      template => '%d', min => 0, unit => 's' }
                ]
            }
        }
    ];
}

sub prefix_av_output {
    my ($self, %options) = @_;

    return 'AV Signature ';
}

sub prefix_avet_output {
    my ($self, %options) = @_;

    return 'AV Extended Signature ';
}

sub prefix_ips_output {
    my ($self, %options) = @_;

    return 'IPS Signature ';
}

sub prefix_ipset_output {
    my ($self, %options) = @_;

    return 'IPS Extended Signature ';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub get_epoch_from_signature {
    my ($self, %options) = @_;
    $options{date} =~ /\((\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2})\)/;
    my ($YYYY,$MM,$DD,$hh,$mm)=($1,$2,$3,$4,$5);
    return mktime (0, $mm, $hh, $DD, $MM - 1, $YYYY - 1900);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_fgSysVersionAv = '.1.3.6.1.4.1.12356.101.4.2.1.0';
    my $oid_fgSysVersionIps = '.1.3.6.1.4.1.12356.101.4.2.2.0';
    my $oid_fgSysVersionAvEt = '.1.3.6.1.4.1.12356.101.4.2.3.0';
    my $oid_fgSysVersionIpsEt = '.1.3.6.1.4.1.12356.101.4.2.4.0';

    my $result = $options{snmp}->get_leef(oids => [$oid_fgSysVersionAv, $oid_fgSysVersionIps, $oid_fgSysVersionAvEt, $oid_fgSysVersionIpsEt], nothing_quit => 1);

    my $av_epoch = $self->get_epoch_from_signature(date => $result->{$oid_fgSysVersionAv});
    my $ips_epoch = $self->get_epoch_from_signature(date => $result->{$oid_fgSysVersionIps});
    my $avet_epoch = $self->get_epoch_from_signature(date => $result->{$oid_fgSysVersionAvEt});
    my $ipset_epoch = $self->get_epoch_from_signature(date => $result->{$oid_fgSysVersionIpsEt});

    my $now = time();

    my $av_diff = $now - $av_epoch;
    my $ips_diff = $now - $ips_epoch;
    my $avet_diff = $now - $avet_epoch;
    my $ipset_diff = $now - $ipset_epoch;

    $self->{av} = {
        human => centreon::plugins::misc::change_seconds(value => $av_diff, start => 'h'),
        value => $av_diff
    };
    $self->{ips} = {
        human => centreon::plugins::misc::change_seconds(value => $ips_diff, start => 'h'),
        value => $ips_diff
    };
    $self->{avet} = {
        human => centreon::plugins::misc::change_seconds(value => $avet_diff, start => 'h'),
        value => $avet_diff
    };
    $self->{ipset} = {
        human => centreon::plugins::misc::change_seconds(value => $ipset_diff, start => 'h'),
        value => $ipset_diff
    };
}

1;

__END__

=head1 MODE

Check last update/refresh of av and ips signatures

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^av$'

=item B<--warning-*> B<--critical-*>

Thresholds (in seconds).
Can be: 'av', 'ips', 'avet', ipset'.

=back

=cut
