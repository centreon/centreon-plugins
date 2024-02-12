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

package hardware::sensors::rittal::cmc3::snmp::mode::listdevices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $map_status = {
    1 => 'Device not available',
    2 => 'OK',
    3 => 'Device detected, confirmation required',
    4 => 'Device lost (disconnected), confirmation required',
    5 => 'Device changed',
    6 => 'Error',
    7 => 'Firmware update pending',
    8 => 'Firmware update runnning'
};

my $mapping = {
    dev_name        => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.2' },
    dev_alias       => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.3' },
    dev_status      => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.6', map => $map_status },
    dev_status_text => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.19' }
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'filter-name:s'  => { name => 'filter_name' },
                'filter-alias:s' => { name => 'filter_alias' }
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

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $mapping->{dev_name}->{oid} },
            { oid => $mapping->{dev_alias}->{oid} },
            { oid => $mapping->{dev_status}->{oid} },
            { oid => $mapping->{dev_status_text}->{oid} }
        ],
        return_type  => 1,
        nothing_quit => 1
    );

    my $results = {};
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{dev_name}->{oid}\.(.*)$/);
        my $instance = $1;
        my $data = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $data->{dev_name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_alias}) && $self->{option_results}->{filter_alias} ne '' &&
            $data->{dev_alias} !~ /$self->{option_results}->{filter_alias}/);

        $results->{$instance} = {
            index      => $instance,
            name       => $data->{dev_name},
            alias      => $data->{dev_alias},
            status     => $data->{dev_status},
            statusText => $data->{dev_status_text}
        };
    }

    return $results;
}

sub run {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $instance (sort keys %$results) {
        $self->{output}->output_add(long_msg => sprintf(
            "[index: %d] [name: %s] [alias: %s] [status: %s] [statusText: '%s']",
            $results->{$instance}->{index},
            $results->{$instance}->{name},
            $results->{$instance}->{alias},
            $results->{$instance}->{status},
            $results->{$instance}->{statusText}
        ));
    }

    $self->{output}->output_add(
        severity  => 'OK',
        short_msg => 'Devices list:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'index', 'name', 'alias', 'status', 'statusText' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $results = $self->manage_selection(%options);
    foreach my $instance (sort keys %$results) {
        $self->{output}->add_disco_entry(%{$results->{$instance}});
    }
}

1;

__END__

=head1 MODE

List devices

=over 8

=item B<--filter-name>

Filter device name (can be a regexp).

=item B<--filter-alias>

Filter devices alias (can be a regexp).

=cut
