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

package centreon::common::airespace::snmp::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-admin-down' => { name => 'filter_admin_down' },
        'prettify'          => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $map_admin_status = {
    1 => 'enable',
    2 => 'disable'
};
my $map_operation_status = {
    1 => 'associated',
    2 => 'disassociating',
    3 => 'downloading'
};

my $mapping = {
    ap_name      => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.3' }, # bsnAPName
    ap_location  => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.4' }, # bsnAPLocation
    ap_opstatus  => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.6', map => $map_operation_status }, # bsnAPOperationStatus
    ap_model     => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.16' }, # bsnAPModel
    ap_ipaddr    => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.19' }, # bsnApIpAddress
    ap_admstatus => { oid => '.1.3.6.1.4.1.14179.2.2.1.1.37', map => $map_admin_status } # bsnAPAdminStatus
};

sub run {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $request = [
        { oid => $mapping->{ap_name}->{oid} },
        { oid => $mapping->{ap_location}->{oid} },
        { oid => $mapping->{ap_opstatus}->{oid} },
        { oid => $mapping->{ap_model}->{oid} },
        { oid => $mapping->{ap_ipaddr}->{oid} },
        { oid => $mapping->{ap_admstatus}->{oid} }
    ];
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => $request,
        return_type => 1,
        nothing_quit => 1
    );

    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{ap_name}->{oid}\.(.*)/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance);

        next if (defined($self->{option_results}->{filter_admin_down}) && $result->{ap_admstatus} eq 'disable');

        my $ap = {
            name => $result->{ap_name},
            instance => $instance,
            location => $result->{ap_location},
            model => $result->{ap_model},
            ip => $result->{ap_ipaddr},
            admstatus => $result->{ap_admstatus},
            opstatus => $result->{ap_opstatus}
        };

        push @disco_data, $ap;
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Cisco WLC/Airspace AP discovery.

Note: When the IP Address is 0, that means the switch is operating in layer2 mode
Ref: https://cric.grenoble.cnrs.fr/Administrateurs/Outils/MIBS/?oid=1.3.6.1.4.1.14179.2.2.1.1.19

=over 8

=item B<--prettify>

Prettify JSON output.

=item B<--filter-admin-down>

Exclude administratively down access points from the discovery result

=back

=cut
