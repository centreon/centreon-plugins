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

package network::microsens::g6::snmp::mode::sfp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub sfp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking sfp port '%s'%s",
        $options{instance},
        $options{instance_value}->{location} ne '' ? ' [location: ' . $options{instance_value}->{location} . ']' : ''
    );
}

sub prefix_sfp_output {
    my ($self, %options) = @_;

    return sprintf(
        "sfp port '%s'%s ",
        $options{instance},
        $options{instance_value}->{location} ne '' ? ' [location: ' . $options{instance_value}->{location} . ']' : ''
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sfp', type => 3, cb_prefix_output => 'prefix_sfp_output', cb_long_output => 'sfp_long_output', indent_long_output => '    ', message_multiple => 'All sfp ports are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'power', type => 0, skipped_code => { -10 => 1 } },
                { name => 'temperature', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{status} = [
        { label => 'status', type => 2, critical_default => '%{status} =~ /txFailure|lossOfSignal|readError/', set => {
                key_values => [ { name => 'status' }, { name => 'location' }, { name => 'port' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{power} = [
        { label => 'input-power', nlabel => 'port.input.power.dbm', set => {
                key_values => [ { name => 'input' } ],
                output_template => 'input power: %s dBm',
                perfdatas => [
                    { template => '%s', unit => 'dBm', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'output-power', nlabel => 'port.output.power.dbm', set => {
                key_values => [ { name => 'output' } ],
                output_template => 'output power: %s dBm',
                perfdatas => [
                    { template => '%s', unit => 'dBm', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'temperature', nlabel => 'port.temperature.celsius', set => {
                key_values => [ { name => 'temperature' } ],
                output_template => 'temperature: %.2f C',
                perfdatas => [
                    { template => '%s', unit => 'C', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-port:s' => { name => 'filter_port' }
    });

    return $self;
}

my $map_status = {
    0 => 'ok', 1 => 'laserDisabled', 2 => 'lossOfSignal',
    3 => 'txFailure', 4 => 'readError'
};
my $mapping = {
    location     => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.3' }, # informationLocation
    status       => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.4', map => $map_status }, # informationStatus
    output_power => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.18' }, # informationTxPower
    input_power  => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.19' }, # informationRxPower
    temperature  => { oid => '.1.3.6.1.4.1.3181.10.6.1.34.100.1.20' }  # informationTemperature
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_port = '.1.3.6.1.4.1.3181.10.6.1.34.100.1.2'; # informationPort
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_port,
        nothing_quit => 1
    );

    $self->{sfp} = {};
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_port\.(.*)$/;
        my $instance = $1;

        my $port = $snmp_result->{$oid};
        next if ($port == 0);

        if (defined($self->{option_results}->{filter_port}) && $self->{option_results}->{filter_port} ne '' &&
            $port !~ /$self->{option_results}->{filter_port}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $port . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{sfp}->{$port} = {
            instance => $instance,
            status => { port => $port },
            power => {},
            temperature => {}
        };
    }

    if (scalar(keys %{$self->{sfp}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No sfp port found.');
        $self->{output}->option_exit();
    }

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [ map($_->{instance}, values(%{$self->{sfp}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{sfp}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{sfp}->{$_}->{instance});
        $self->{sfp}->{$_}->{status}->{status} = $result->{status};
        $self->{sfp}->{$_}->{location} = $result->{location};
        $self->{sfp}->{$_}->{status}->{location} = $result->{location};

        $self->{sfp}->{$_}->{power}->{output} = $1 if ($result->{output_power} =~ /([0-9\.]+)/);
        $self->{sfp}->{$_}->{power}->{input} = $1 if ($result->{input_power} =~ /([0-9\.]+)/);
        $self->{sfp}->{$_}->{temperature}->{temperature} = $1 if ($result->{temperature} =~ /([0-9\.]+)\s*C/);     
    }
}

1;

__END__

=head1 MODE

Check sfp ports.

=over 8

=item B<--filter-port>

Filter ports by index (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}, %{location}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /txFailure|lossOfSignal|readError/').
You can use the following variables: %{status}, %{port}, %{location}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'temperature', 'input-power', 'output-power'.

=back

=cut
