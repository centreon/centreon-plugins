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

package network::huawei::wlc::snmp::mode::listaps;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-name:s"    => { name => 'filter_name' },
        "filter-address:s" => { name => 'filter_address' },
        "filter-group:s"   => { name => 'filter_group' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    # Collecting all the relevant informations user may needs when using discovery function for AP in Huawei WLC controllers.
    # They had been select with https://support.huawei.com/enterprise/en/doc/EDOC1100306136/680fca71/huawei-wlan-ap-mib as support.
    my $mapping = {
        name     => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.4' },# hwWlanApName
        serial   => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.2' },# hwWlanApSn
        ap_group  => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.5' },# hwWlanApGroup
        address  => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.13' },# hwWlanApIpAddress
        software => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.22' },# hwWlanApSysSoftwareDesc
        run_time  => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.18' },# hwWlanApRunTime
        hardware => { oid => '.1.3.6.1.4.1.2011.6.139.13.3.3.1.23' }# hwWlanApSysHardwareDesc
    };
    # parent oid for all the mapping usage
    my $oid_bsnAPEntry = '.1.3.6.1.4.1.2011.6.139.13.3.3';

    my $snmp_result = $options{snmp}->get_table(
        oid   => $oid_bsnAPEntry,
        start => $mapping->{serial}->{oid},# First oid of the mapping => here : 2
        end   => $mapping->{hardware}->{oid}# Last oid of the mapping => here : 23
    );

    my $results = {};
    # Iterate for all oids catch in snmp result above
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{serial}->{oid}\.(.*)$/);
        my $oid_path = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $oid_path);

        if (!defined($result->{name}) || $result->{name} eq '') {
            $self->{output}->output_add(long_msg =>
                "skipping WLC '$oid_path': cannot get a name. please set it.",
                debug                            =>
                    1);
            next;
        }

        if (!defined($result->{address}) || $result->{address} eq '') {
            $self->{output}->output_add(long_msg =>
                "skipping WLC '$oid_path': cannot get a address. please set it.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{name} . "': no matching name filter.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_address}) && $self->{option_results}->{filter_address} ne '' &&
            $result->{address} !~ /$self->{option_results}->{filter_address}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{address} . "': no matching address filter.",
                debug                            =>
                    1);
            next;
        }

        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $result->{ap_group} !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg =>
                "skipping '" . $result->{ap_group} . "': no matching group filter.",
                debug                            =>
                    1);
            next;
        }

        $results->{$oid_path} = {
            name     => $result->{name},
            serial   => $result->{serial},
            address  => $result->{address},
            hardware => $result->{hardware},
            software => $result->{software},
            run_time  => $result->{run_time},
            ap_group  => $result->{ap_group}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[oid_path: %s] [name: %s] [serial: %s] [address: %s] [hardware: %s] [software: %s] [run_time: %s] [ap_group: %s]',
                $oid_path,
                $results->{$oid_path}->{name},
                $results->{$oid_path}->{serial},
                $results->{$oid_path}->{address},
                $results->{$oid_path}->{hardware},
                $results->{$oid_path}->{software},
                centreon::plugins::misc::change_seconds(value => $results->{$oid_path}->{run_time}),
                $results->{$oid_path}->{ap_group}
            )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List aps'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements =>
        [ 'name', 'serial', 'address', 'hardware', 'software', 'run_time', 'ap_group' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(snmp => $options{snmp});
    foreach my $oid_path (sort keys %$results) {
        $self->{output}->add_disco_entry(
            name     =>
                $results->{$oid_path}->{name},
            serial   =>
                $results->{$oid_path}->{serial},
            address  =>
                $results->{$oid_path}->{address},
            hardware =>
                $results->{$oid_path}->{hardware},
            software =>
                $results->{$oid_path}->{software},
            run_time  =>
                defined($results->{$oid_path}->{run_time}) ?
                    centreon::plugins::misc::change_seconds(value => $results->{$oid_path}->{run_time}) :
                    "",
            ap_group  =>
                $results->{$oid_path}->{ap_group}
        );
    }
}

1;

__END__

=head1 MODE

List wireless name.

=over 8

=item B<--filter-name>

Filter access points by name (can be a regexp).

=item B<--filter-address>

Filter access points by IP address (can be a regexp).

=item B<--filter-group>

Filter access point group (can be a regexp).

=back

=cut
