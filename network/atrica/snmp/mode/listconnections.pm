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

package network::atrica::snmp::mode::listconnections;

use base qw(snmp_standard::mode::listinterfaces);

use strict;
use warnings;

sub set_oids_status {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{oid_filter} eq 'atrconncepgendescr') {
        $self->{oid_adminstatus} = '.1.3.6.1.4.1.6110.2.7.5.1.7';
        $self->{oid_adminstatus_mapping} = {
            1 => 'up', 2 => 'down',
        };
        $self->{oid_opstatus} = '.1.3.6.1.4.1.6110.2.7.5.1.8';
        $self->{oid_opstatus_mapping} = {
            1 => 'up', 2 => 'down', 3 => 'oneWay', 4 => 'twoWay', 5 => 'fastProtected',
        };
    } else {
        $self->{oid_adminstatus} = '.1.3.6.1.4.1.6110.2.2.1.1.3';
        $self->{oid_adminstatus_mapping} = {
            2 => 'off', # off
            3 => 'on', # on
        };
        $self->{oid_opstatus} = '.1.3.6.1.4.1.6110.2.2.1.1.4';
        $self->{oid_opstatus_mapping} = {
            2 => 'off', 3 => 'systemBusy', 4 => 'dependencyBusy', 5 => 'inService', 6 => 'alterInService', 7 => 'failed',
            8 => 'mainInServiceViaCoreLinkProtec', 9 => 'alterInServiceViaCoreLinkProtec',
            10 => 'mainAndAltDownConnUpSendingToMain', 11 => 'mainAndAltDownConnUpSendingToAlt',
        };
    }
}

sub is_admin_status_down {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{use_adminstatus}) && defined($options{admin_status}) && 
        $self->{oid_adminstatus_mapping}->{$options{admin_status}} !~ /^up|on$/) {
        return 1;
    }
    return 0;
}

sub set_oids_label {
    my ($self, %options) = @_;

    $self->{oids_label} = {
        'atrconncepgendescr'    => '.1.3.6.1.4.1.6110.2.7.5.1.1',
        'atrconningdescr'       => '.1.3.6.1.4.1.6110.2.2.1.1.2',
    };
}

sub default_oid_filter_name {
    my ($self, %options) = @_;
    
    return 'atrConnCepGenDescr';
}

sub default_oid_display_name {
    my ($self, %options) = @_;
    
    return 'atrConnCepGenDescr';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, 
                                  no_speed => 1);
    bless $self, $class;    
    return $self;
}

1;

__END__

=head1 MODE

=over 8

=item B<--interface>

Set the interface (number expected) ex: 1,2,... (empty means 'check all interface').

=item B<--name>

Allows to use interface name with option --interface instead of interface oid index (Can be a regexp)

=item B<--speed>

Set interface speed (in Mb).

=item B<--skip-speed0>

Don't display interface with speed 0.

=item B<--filter-status>

Display interfaces matching the filter (example: 'up').

=item B<--use-adminstatus>

Display interfaces with AdminStatus 'up'.

=item B<--oid-filter>

Choose OID used to filter interface (default: atrConnCepGenDescr) (values: atrConnIngDescr, atrConnCepGenDescr).

=item B<--oid-display>

Choose OID used to display interface (default: atrConnCepGenDescr) (values: atrConnIngDescr, atrConnCepGenDescr).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=item B<--add-extra-oid>

Display an OID. Example: --add-extra-oid='alias,.1.3.6.1.2.1.31.1.1.1.18'

=back

=cut
