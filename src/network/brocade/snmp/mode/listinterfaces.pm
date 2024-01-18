#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::brocade::snmp::mode::listinterfaces;

use base qw(snmp_standard::mode::listinterfaces);

use strict;
use warnings;

sub set_oids_label {
    my ($self, %options) = @_;

    $self->SUPER::set_oids_label(%options);
    $self->{oids_label}->{fcportname} =  '.1.3.6.1.4.1.1588.2.1.1.1.6.2.1.36';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oids = [{ oid => $self->{oids_label}->{$self->{option_results}->{oid_filter}} }];
    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
        push @$oids, { oid => $self->{oids_label}->{$self->{option_results}->{oid_display}} };
    }
    if (scalar(keys %{$self->{extra_oids}}) > 0) {
        foreach (keys %{$self->{extra_oids}}) {
            push @$oids, { oid => $self->{extra_oids}->{$_}->{oid} };
        }
    }

    # ifName mandatory with fcPortName
    if (($self->{option_results}->{oid_filter} eq 'fcportname' || $self->{option_results}->{oid_display} eq 'fcportname') && 
        ($self->{option_results}->{oid_filter} ne 'ifname' && $self->{option_results}->{oid_display} ne 'ifname')) {
        push @$oids, { oid => $self->{oids_label}->{ifname} };
    }

    $self->{datas} = {};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $oids);
    $self->{datas}->{all_ids} = [];

    my $oid_filter = $self->{option_results}->{oid_filter} eq 'fcportname' ? 'ifname' : $self->{option_results}->{oid_filter};
    foreach ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oids_label}->{$oid_filter} }})) {
        next if (! /^$self->{oids_label}->{$oid_filter}\.(.*)$/);

        my $ifIndex = $1;
        if ($self->{option_results}->{oid_filter} eq 'fcportname' && $self->{results}->{ $self->{oids_label}->{ifname} }->{$_} =~ /\d+\/(\d+)$/) {
            $self->{datas}->{ $self->{option_results}->{oid_filter} . '_' . $ifIndex } = $self->{output}->decode($self->{results}->{ $self->{oids_label}->{fcportname} }->{ $self->{oids_label}->{fcportname} . '.' . ($1 + 1) });
        } else {
            $self->{datas}->{ $self->{option_results}->{oid_filter} . '_' . $ifIndex } = $self->{output}->decode($self->{results}->{ $self->{oids_label}->{$oid_filter} }->{$_});
        }

        push @{$self->{datas}->{all_ids}}, $ifIndex;
    }

    if (scalar(@{$self->{datas}->{all_ids}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "Can't get interfaces...");
        $self->{output}->option_exit();
    }

    if ($self->{option_results}->{oid_filter} ne $self->{option_results}->{oid_display}) {
        my $oid_display = $self->{option_results}->{oid_display} eq 'fcportname' ? 'ifname' : $self->{option_results}->{oid_display};
        foreach ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{ $self->{oids_label}->{$oid_display} }})) {
            next if (! /^$self->{oids_label}->{$oid_display}\.(.*)$/);

            my $ifIndex = $1;
            if ($self->{option_results}->{oid_display} eq 'fcportname' && $self->{results}->{ $self->{oids_label}->{ifname} }->{$_} =~ /\d+\/(\d+)$/) {
                $self->{datas}->{ $self->{option_results}->{oid_display} . '_' . $ifIndex } = $self->{output}->decode($self->{results}->{ $self->{oids_label}->{fcportname} }->{ $self->{oids_label}->{fcportname} . '.' . ($1 + 1) });
            } else {
                $self->{datas}->{ $self->{option_results}->{oid_display} . '_' . $ifIndex } = $self->{output}->decode($self->{results}->{ $self->{oids_label}->{$oid_display} }->{$_});
            }
        }
    }

    if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{interface})) {
        foreach (@{$self->{datas}->{all_ids}}) {
            if ($self->{option_results}->{interface} =~ /(^|\s|,)$_(\s*,|$)/) {
                push @{$self->{interface_id_selected}}, $_;
            }
        }
    } else {
        foreach (@{$self->{datas}->{all_ids}}) {
            my $filter_name = $self->{datas}->{$self->{option_results}->{oid_filter} . "_" . $_};
            next if (!defined($filter_name));

            if (!defined($self->{option_results}->{interface})) {
                push @{$self->{interface_id_selected}}, $_;
                next;
            }
            if ($filter_name =~ /$self->{option_results}->{interface}/) {
                push @{$self->{interface_id_selected}}, $_; 
            }
        }
    }

    if (scalar(@{$self->{interface_id_selected}}) <= 0 && !defined($options{disco})) {
        $self->{output}->add_option_msg(short_msg => 'No entry found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Set the interface (number expected) example: 1,2,... (empty means 'check all interfaces').

=item B<--name>

Allows you to define the interface (in option --interface) by name instead of OID index. The name matching mode supports regular expressions.

=item B<--speed>

Set interface speed (in Mb).

=item B<--skip-speed0>

Don't display interface with speed 0.

=item B<--filter-status>

Display interfaces matching the filter (example: 'up').

=item B<--use-adminstatus>

Display interfaces with AdminStatus 'up'.

=item B<--oid-filter>

Define the OID to be used to filter interfaces (default: ifName) (values: fcPortName, ifDesc, ifAlias, ifName).

=item B<--oid-display>

Define the OID that will be used to name the interfaces (default: ifName) (values: fcPortName, ifDesc, ifAlias, ifName).

=item B<--display-transform-src> B<--display-transform-dst>

Modify the interface name displayed by using a regular expression.

Example: adding --display-transform-src='eth' --display-transform-dst='ens'  will replace all occurrences of 'eth' with 'ens'

=item B<--add-extra-oid>

Display an OID.
Example: --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'
or --add-extra-oid='vlan,.1.3.6.1.2.1.31.19,%{instance}\..*'

=item B<--add-mac-address>

Display interface mac address.

=back

=cut
