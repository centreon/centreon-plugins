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

package network::aerohive::snmp::mode::connectedusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ssid', type => 1, cb_prefix_output => 'prefix_ssid_output', message_multiple => 'All users by SSID are ok' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'users.current.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Users : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s',
                      unit => 'users', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{ssid} = [
        { label => 'ssid', nlabel => 'ssid.users.current.count', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users : %s',
                perfdatas => [
                    { label => 'ssid', value => 'total', template => '%s',
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_ssid_output {
    my ($self, %options) = @_;

    return "SSID '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                  "filter-ssid:s"   => { name => 'filter_ssid' },
                                });

    return $self;
}

my $oid_ahSSIDNAME = '.1.3.6.1.4.1.26928.1.1.1.2.1.1.1.2';
my $oid_ahClientSSID = '.1.3.6.1.4.1.26928.1.1.1.2.1.2.1.10';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => 0 };
    $self->{ssid} = {};

    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_ahSSIDNAME },
                                                                    { oid => $oid_ahClientSSID },
                                                                 ],
                                                          nothing_quit => 1);

    foreach my $oid (keys %{$self->{results}->{ $oid_ahSSIDNAME }}) {
        my $ssid = $self->{results}->{ $oid_ahSSIDNAME }->{$oid};
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $ssid !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "skipping ssid " . $ssid . " : no matching filter.", debug => 1);
            next;
        }
        $self->{ssid}->{$ssid} = { display => $ssid, total => 0 } if (!defined($self->{ssid}->{$ssid}));
    }

    foreach my $oid (keys %{$self->{results}->{ $oid_ahClientSSID }}) {
        $self->{global}->{total}++;
        my $ssid = $self->{results}->{ $oid_ahClientSSID }->{$oid};
        $self->{ssid}->{$ssid}->{total}++ if (defined($self->{ssid}->{$ssid}));
    }

}

1;

__END__

=head1 MODE

Check number of connected users (total and by SSID).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='ssid$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'ssid'

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'ssid'

=item B<--filter-ssid>

Filter by SSID (can be a regexp).

=back

=cut
