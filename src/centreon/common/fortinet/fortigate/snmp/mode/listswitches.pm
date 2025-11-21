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

package centreon::common::fortinet::fortigate::snmp::mode::listswitches;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $mapping_status = { 0 => 'down', 1 => 'up' };
my $map_admin_connection_state = { 0 => 'discovered', 1 => 'disable', 2 => 'authorized' };

my $mapping = {
    serial  => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.3' },# fgSwDeviceSerialNum
    name    => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.4' },# fgSwDeviceName
    version => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.5' },# fgSwDeviceVersion
    admin   => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.6', map => $map_admin_connection_state },# fgSwDeviceAuthorized
    state   => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.7', map => $mapping_status },# fgSwDeviceStatus
    ip      => { oid => '.1.3.6.1.4.1.12356.101.24.1.1.1.9' },# fgSwDeviceIp
};
my $fgSwDeviceEntry = '.1.3.6.1.4.1.12356.101.24.1.1.1';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s'   => { name => 'filter_name' },
            'filter-status:s' => { name => 'filter_status' },
            'filter-admin:s'  => { name => 'filter_admin' },
            'filter-ip:s'     => { name => 'filter_ip' }
        }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid          => $fgSwDeviceEntry,
        start        => $mapping->{serial},
        end          => $mapping->{ip},
        nothing_quit => 1
    );

    foreach my $oid ($options{snmp}->oid_lex_sort(sort keys %{$snmp_result})) {
        next if ($oid !~ /^$mapping->{serial}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{name} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $result->{state} !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{state} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_admin}) && $self->{option_results}->{filter_admin} ne '' &&
            $result->{admin} !~ /$self->{option_results}->{filter_admin}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{admin} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        if (defined($self->{option_results}->{filter_ip}) && $self->{option_results}->{filter_ip} ne '' &&
            $result->{ip} !~ /$self->{option_results}->{filter_ip}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{ip} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        push @{$self->{switch}}, $result;
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    if (scalar(keys @{$self->{switch}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No switch found matching.");
        $self->{output}->option_exit();
    }

    foreach (sort @{$self->{switch}}) {
        $self->{output}->output_add(
            long_msg =>
                sprintf(
                    "[Name = %s] [Serial = %s] [IP = %s] [Version = %s] [State = %s] [Admin = %s]",
                    $_->{name},
                    $_->{serial},
                    $_->{ip},
                    $_->{version},
                    $_->{state},
                    $_->{admin},
                )
        );
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'List switches:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name', 'serial', 'ip', 'version', 'state', 'admin' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach (@{$self->{switch}}) {
        $self->{output}->add_disco_entry(
            name    => $_->{name},
            serial  => $_->{serial},
            ip      => $_->{ip},
            version => $_->{version},
            state   => $_->{state},
            admin   => $_->{admin}
        );
    }
}

1;

__END__

=head1 MODE

List switches managed through Fortigate Switch Controller.

=over 8

=item B<--filter-name>

Filter switch by name (can be a regexp).

=item B<--filter-status>

Filter switch by status

=item B<--filter-admin>

Filter switch by admin connection state

=item B<--filter-ip>

Filter switch by IP (can be a regexp).

=back

=cut