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

package centreon::common::fortinet::fortigate::mode::signatures;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX qw(mktime floor);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'av', type => 0, cb_prefix_output => 'prefix_av_output' },
        { name => 'ips', type => 0, cb_prefix_output => 'prefix_ips_output' },
    ];

    $self->{maps_counters}->{av} = [
        { label => 'av', set => {
                key_values => [ { name => 'human' }, { name => 'value' }  ],
                threshold_use => 'value_absolute',
                output_template => "last refresh is: '%s'",
                perfdatas => [
                    { label => 'av_update', value => 'value_absolute',
                      template => '%d', min => 0, unit => 's' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{ips} = [
        { label => 'ips', set => {
                key_values => [ { name => 'human' }, { name => 'value' } ],
                threshold_use => 'value_absolute',
                output_template => "last refresh is: '%s'",
                perfdatas => [
                    { label => 'ips_update', value => 'value_absolute',
                      template => '%d', min => 0, unit => 's' },
                ],
            }
        },
    ];
}

sub prefix_av_output {
    my ($self, %options) = @_;

    return "AV Signature ";
}

sub prefix_ips_output {
    my ($self, %options) = @_;

    return "IPS Signature ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
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
    $self->{snmp} = $options{snmp};

    my $oid_fgSysVersionAv = '.1.3.6.1.4.1.12356.101.4.2.1.0';
    my $oid_fgSysVersionIps = '.1.3.6.1.4.1.12356.101.4.2.2.0';

    my $result = $self->{snmp}->get_leef(oids => [$oid_fgSysVersionAv, $oid_fgSysVersionIps], nothing_quit => 1);

    my $av_epoch = $self->get_epoch_from_signature(date => $result->{$oid_fgSysVersionAv});
    my $ips_epoch = $self->get_epoch_from_signature(date => $result->{$oid_fgSysVersionIps});

    my $now = time();

    my $av_diff = $now - $av_epoch;
    my $ips_diff = $now - $ips_epoch;

    $self->{av} = { human => centreon::plugins::misc::change_seconds(value => $av_diff, start => 'h'),
                    value => $av_diff };

    $self->{ips} = { human => centreon::plugins::misc::change_seconds(value => $ips_diff, start => 'h'),
                     value => $ips_diff };


}

1;

__END__

=head1 MODE

Check last update/refresh of av and ips signatures

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^av$'

=item B<--warning-*>

Threshold warning (in hours).
Can be: 'av', 'ips'

=item B<--critical-*>

Threshold critical (in hours).
Can be: 'av', 'ips'

=back

=cut
