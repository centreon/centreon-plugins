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

package hardware::sensors::rittal::cmc3::snmp::mode::devices;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my $map_status = {
    1 => 'notAvail',
    2 => 'ok',
    3 => 'detect',
    4 => 'lost',
    5 => 'changed',
    6 => 'error',
    7 => 'fwUpdate',
    8 => 'fwUpdateRun'
};

my $mapping = {
    status => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.6', map => $map_status },
    alias  => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.3' },
    name   => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.2' },
    text   => { oid => '.1.3.6.1.4.1.2606.7.4.1.2.1.19' }
};

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Device '%s' status: %s [alias: %s] [text: %s]",
        $self->{result_values}->{name},
        $self->{result_values}->{status},
        $self->{result_values}->{alias},
        $self->{result_values}->{text}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'devices', type => 1, message_multiple => 'All devices are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{devices} = [
        {
            label => 'status',
            warning_default  => '%{status} =~ /detect|changed|fwUpdate|fwUpdateRun/i',
            critical_default => '%{status} =~ /notAvail|lost|error/i',
            type  => 2,
            set   => {
                key_values                     => [
                    { name => 'status' },
                    { name => 'alias' },
                    { name => 'name' },
                    { name => 'text' },
                    { name => 'index' },
                ],
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_output          => $self->can('custom_status_output')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments =>
            {
                'filter-name:s'         => { name => 'filter_name' },
                'filter-alias:s'        => { name => 'filter_alias' },
                'index:s'               => { name => 'index' }
            }
    );

    return $self;
}


sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids         => [
            { oid => $mapping->{status}->{oid} },
            { oid => $mapping->{name}->{oid} },
            { oid => $mapping->{alias}->{oid} },
            { oid => $mapping->{text}->{oid} },
        ],
        return_type  => 1,
        nothing_quit => 1
    );

    $self->{devices} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)$/);
        my $instance = $1;
        my $data = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if (defined($self->{option_results}->{index}) && $self->{option_results}->{index} ne '' &&
            $instance != $self->{option_results}->{index});
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $data->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{filter_alias}) && $self->{option_results}->{filter_alias} ne '' &&
            $data->{alias} !~ /$self->{option_results}->{filter_alias}/);

        $self->{devices}->{$instance} = {
            index  => $instance,
            name   => $data->{name},
            status => $data->{status},
            alias  => $data->{alias},
            text   => $data->{text}
        };
    }

    if (scalar(keys %{$self->{devices}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No devices found.');
        $self->{output}->option_exit();
    }
};

1;

__END__

=head1 MODE

Check devices status.

=over 8

=item B<--filter-name>

Filter device name (can be a regexp).

=item B<--filter-alias>

Filter devices alias (can be a regexp).

=item B<--index>

Filter device index (exact match).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /detect|changed|fwUpdate|fwUpdateRun/i').
You can use the following variables: %{status}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /notAvail|lost|error/i').
You can use the following variables: %{status}

=back

=cut
