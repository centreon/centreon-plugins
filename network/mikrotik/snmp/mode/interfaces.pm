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

package network::mikrotik::snmp::mode::interfaces;

use base qw(snmp_standard::mode::interfaces);

use strict;
use warnings;

sub set_oids_errors {
    my ($self, %options) = @_;
    
    $self->{oids_errors}->{oid_ifInDiscard} = '.1.3.6.1.2.1.2.2.1.13';
    $self->{oids_errors}->{oid_ifInError} = '.1.3.6.1.2.1.2.2.1.14';
    $self->{oids_errors}->{oid_ifOutDiscard} = '.1.3.6.1.2.1.2.2.1.19';
    $self->{oids_errors}->{oid_ifOutError} = '.1.3.6.1.2.1.2.2.1.20';
    $self->{oids_errors}->{oid_ifInTooShort} = '.1.3.6.1.4.1.14988.1.1.14.1.1.33';
    $self->{oids_errors}->{oid_ifInTooLong} = '.1.3.6.1.4.1.14988.1.1.14.1.1.41';
    $self->{oids_errors}->{oid_ifInFCSError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.45';
    $self->{oids_errors}->{oid_ifInAlignError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.46';
    $self->{oids_errors}->{oid_ifInFragment} = '.1.3.6.1.4.1.14988.1.1.14.1.1.47';
    $self->{oids_errors}->{oid_ifInOverflow} = '.1.3.6.1.4.1.14988.1.1.14.1.1.48';
    $self->{oids_errors}->{oid_ifInUnknownOp} = '.1.3.6.1.4.1.14988.1.1.14.1.1.50';
    $self->{oids_errors}->{oid_ifInLengthError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.51';
    $self->{oids_errors}->{oid_ifInCodeError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.52';
    $self->{oids_errors}->{oid_ifInCarrierError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.53';
    $self->{oids_errors}->{oid_ifInJabber} = '.1.3.6.1.4.1.14988.1.1.14.1.1.54';
    $self->{oids_errors}->{oid_ifInDrop} = '.1.3.6.1.4.1.14988.1.1.14.1.1.55';
    $self->{oids_errors}->{oid_ifOutTooShort} = '.1.3.6.1.4.1.14988.1.1.14.1.1.63';
    $self->{oids_errors}->{oid_ifOutTooLong} = '.1.3.6.1.4.1.14988.1.1.14.1.1.71';
    $self->{oids_errors}->{oid_ifOutUnderrun} = '.1.3.6.1.4.1.14988.1.1.14.1.1.75';
    $self->{oids_errors}->{oid_ifOutCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.76';
    $self->{oids_errors}->{oid_ifOutExcessiveCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.77';
    $self->{oids_errors}->{oid_ifOutMultipleCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.78';
    $self->{oids_errors}->{oid_ifOutSingleCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.79';
    $self->{oids_errors}->{oid_ifOutExcessiveDeferred} = '.1.3.6.1.4.1.14988.1.1.14.1.1.80';
    $self->{oids_errors}->{oid_ifOutDeferred} = '.1.3.6.1.4.1.14988.1.1.14.1.1.81';
    $self->{oids_errors}->{oid_ifOutLateCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.82';
    $self->{oids_errors}->{oid_ifOutTotalCollision} = '.1.3.6.1.4.1.14988.1.1.14.1.1.83';
    $self->{oids_errors}->{oid_ifOutDrop} = '.1.3.6.1.4.1.14988.1.1.14.1.1.85';
    $self->{oids_errors}->{oid_ifOutJabber} = '.1.3.6.1.4.1.14988.1.1.14.1.1.86';
    $self->{oids_errors}->{oid_ifOutFCSError} = '.1.3.6.1.4.1.14988.1.1.14.1.1.87';
    $self->{oids_errors}->{oid_ifOutFragment} = '.1.3.6.1.4.1.14988.1.1.14.1.1.89';
}

sub set_counters_errors {
    my ($self, %options) = @_;

    $self->set_oids_errors();

    foreach my $oid (keys %{$self->{oids_errors}}) {
        $oid =~ /^oid_if(In|Out)(.*)$/;
        push @{$self->{maps_counters}->{int}}, 
            { label => lc($1) . '-' . lc($2), filter => 'add_errors', nlabel => 'interface.packets.' . lc($1) . '.' . lc($2) . '.count', set => {
                    key_values => [ { name => lc($1.$2), diff => 1 }, { name => 'total_' . lc($1) . '_packets', diff => 1 }, { name => 'display' }, { name => 'mode_cast' } ],
                    closure_custom_calc => $self->can('custom_errors_calc'), closure_custom_calc_extra_options => { label => $1 . ' ' . $2, label_ref1 => lc($1), label_ref2 => lc($2) },
                    closure_custom_output => $self->can('custom_errors_output'), output_error_template => 'Packets ' . $1 . ' ' . $2 . ' : %s',
                    closure_custom_perfdata => $self->can('custom_errors_perfdata'),
                    closure_custom_threshold_check => $self->can('custom_errors_threshold'),
                }
            },
        ;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'warning-errors:s'  => { name => 'warning_errors' },
        'critical-errors:s' => { name => 'critical_errors' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    foreach ('warning', 'critical') {
        next if (!defined($options{option_results}->{$_ . '_errors'}) || $options{option_results}->{$_ . '_errors'} eq '');
        foreach my $oid (keys %{$self->{oids_errors}}) {
            $oid =~ /^oid_if(In|Out)(.*)$/;
            if (!defined($options{option_results}->{$_ . '-instance-interface-packets-' . lc($1) . '-' . lc($2) . '-count'})) {
                $options{option_results}->{$_ . '-instance-interface-packets-' . lc($1) . '-' . lc($2) . '-count'} = $options{option_results}->{$_ . '_errors'};
            }
            if (!defined($options{option_results}->{$_ . '-' . lc($1) . '-' . lc($2)})) {
                $options{option_results}->{$_ . '-' . lc($1) . '-' . lc($2)} = $options{option_results}->{$_ . '_errors'};
            }
        }
    }

    $self->SUPER::check_options(%options);
}

sub load_errors {
    my ($self, %options) = @_;

    $self->{snmp}->load(
        oids => [ values %{$self->{oids_errors}} ],
        instances => $self->{array_interface_selected}
    );
}

sub add_result_errors {
    my ($self, %options) = @_;

    foreach my $oid (keys %{$self->{oids_errors}}) {
        $oid =~ /^oid_if(In|Out)(.*)$/;
        $self->{int}->{$options{instance}}->{lc($1.$2)} = $self->{results}->{$self->{oids_errors}->{$oid} . '.' . $options{instance}};
    }
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--add-global>

Check global port statistics (By default if no --add-* option is set).

=item B<--add-status>

Check interface status.

=item B<--add-duplex-status>

Check duplex status (with --warning-status and --critical-status).

=item B<--add-traffic>

Check interface traffic.

=item B<--add-errors>

Check interface errors.

=item B<--add-cast>

Check interface cast.

=item B<--add-speed>

Check interface speed.

=item B<--add-volume>

Check interface data volume between two checks (not supposed to be graphed, useful for BI reporting).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admstatus} eq "up" and %{opstatus} ne "up"').
Can used special variables like: %{admstatus}, %{opstatus}, %{duplexstatus}, %{display}

=item B<--warning-errors>

Set warning threshold for all error counters.

=item B<--critical-errors>

Set critical threshold for all error counters.

=item B<--warning-*>

Threshold warning (will superseed --warning-errors).
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

And also: 'in-tooshort' (%), 'in-toolong' (%), 'in-fcserror' (%), 'in-alignerror' (%), 'in-fragment' (%),
'in-overflow' (%), 'in-unknownop' (%), 'in-lengtherror' (%), 'in-codeerror' (%), 'in-carriererror' (%),
'in-jabber' (%), 'in-drop' (%), 'out-tooshort' (%), 'out-toolong' (%), 'out-underrun' (%),
'out-collision' (%), 'out-excessivecollision' (%), 'out-multiplecollision' (%), 'out-singlecollision' (%),
'out-excessivedeferred' (%),'out-deferred' (%), 'out-latecollision' (%), 'out-totalcollision' (%),
'out-drop' (%), 'out-jabber' (%), 'out-fcserror' (%), 'out-fragment' (%).

=item B<--critical-*>

Threshold critical (will superseed --warning-errors).
Can be: 'total-port', 'total-admin-up', 'total-admin-down', 'total-oper-up', 'total-oper-down',
'in-traffic', 'out-traffic', 'in-error', 'in-discard', 'out-error', 'out-discard',
'in-ucast' (%), 'in-bcast' (%), 'in-mcast' (%), 'out-ucast' (%), 'out-bcast' (%), 'out-mcast' (%),
'speed' (b/s).

And also: 'in-tooshort' (%), 'in-toolong' (%), 'in-fcserror' (%), 'in-alignerror' (%), 'in-fragment' (%),
'in-overflow' (%), 'in-unknownop' (%), 'in-lengtherror' (%), 'in-codeerror' (%), 'in-carriererror' (%),
'in-jabber' (%), 'in-drop' (%), 'out-tooshort' (%), 'out-toolong' (%), 'out-underrun' (%),
'out-collision' (%), 'out-excessivecollision' (%), 'out-multiplecollision' (%), 'out-singlecollision' (%),
'out-excessivedeferred' (%),'out-deferred' (%), 'out-latecollision' (%), 'out-totalcollision' (%),
'out-drop' (%), 'out-jabber' (%), 'out-fcserror' (%), 'out-fragment' (%).

=item B<--units-traffic>

Units of thresholds for the traffic (Default: '%') ('%', 'b/s').

=item B<--units-errors>

Units of thresholds for errors/discards (Default: '%') ('%', 'absolute').

=item B<--nagvis-perfdata>

Display traffic perfdata to be compatible with nagvis widget.

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--speed>

Set interface speed for incoming/outgoing traffic (in Mb).

=item B<--speed-in>

Set interface speed for incoming traffic (in Mb).

=item B<--speed-out>

Set interface speed for outgoing traffic (in Mb).

=item B<--no-skipped-counters>

Don't skip counters when no change.

=item B<--force-counters32>

Force to use 32 bits counters (even in snmp v2c and v3). Should be used when 64 bits counters are buggy.

=item B<--reload-cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--oid-filter>

Choose OID used to filter interface (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-display>

Choose OID used to display interface (default: ifName) (values: ifDesc, ifAlias, ifName, IpAddr).

=item B<--oid-extra-display>

Add an OID to display.

=item B<--display-transform-src>

Regexp src to transform display value.

=item B<--display-transform-dst>

Regexp dst to transform display value.

=item B<--show-cache>

Display cache interface datas.

=back

=cut
