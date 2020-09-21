#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_service_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "health: %s",
        $self->{result_values}->{health}
    );
}

sub firewall_long_output {
    my ($self, %options) = @_;

    return "checking firewall '" . $options{instance_value}->{display} . "'";
}

sub prefix_firewall_output {
    my ($self, %options) = @_;

    return "firewall '" . $options{instance_value}->{display} . "' ";
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "service '" . $options{instance_value}->{service} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'firewalls', type => 3, cb_prefix_output => 'prefix_firewall_output', cb_long_output => 'firewall_long_output',
          indent_long_output => '    ', message_multiple => 'All firewalls are ok',
            group => [
                 { name => 'services', display_long => 1, cb_prefix_output => 'prefix_service_output',  message_multiple => 'All services are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{services} = [
        {
            label => 'service-status',
            type => 2,
            warning_default => '%{health} =~ /minor/i',
            critical_default => '%{health} =~ /major/i',
            set => {
                key_values => [ { name => 'health' }, { name => 'service' } ],
                closure_custom_output => $self->can('custom_service_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-serial:s' => { name => 'filter_serial' }
    });

    return $self;
}

my $mapping = {
    link            => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.4' },  # snsHaLinkHealth
    powersupply     => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.5' },  # snsPowerSupplyHealth
    fan             => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.6' },  # snsFanHealth
    cpu             => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.7' },  # snsFanHealth
    memory          => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.8' },  # snsMemHealth
    disk            => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.9' },  # snsDiskHealth
    raid            => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.10' }, # snsRaidHealth
    certificate     => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.11' }, # snsCertHealth
    CRL             => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.12' }, # snsCRLHealth
    #password        => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.13' }, # snsPasswdHealth
    #cpu_temperature => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.14' }, # snsCpuTempHealth
    #TPM             => { oid => '.1.3.6.1.4.1.11256.1.16.2.1.15' }  # snsTPMHealth
};
my $oid_snsSerialHealth = '.1.3.6.1.4.1.11256.1.16.2.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_snsSerialHealth,
        nothing_quit => 1
    );

    $self->{firewalls} = {};
    foreach (keys %$snmp_result) {
        /^$oid_snsSerialHealth\.(.*)/;
        my $instance = $1;

        my $serial = $snmp_result->{$_};
        if (defined($self->{option_results}->{filter_serial}) && $self->{option_results}->{filter_serial} ne '' &&
            $serial !~ /$self->{option_results}->{filter_serial}/) {
            $self->{output}->output_add(long_msg => "skipping firewall '" . $serial . "'.", debug => 1);
            next;
        }

        $self->{firewalls}->{$instance} = {
            display => $serial,
            services => {}
        };
    }

    return if (scalar(keys %{$self->{firewalls}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %{$self->{firewalls}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{firewalls}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        foreach my $service (keys %$result) {
            $self->{firewalls}->{$_}->{services}->{$service} = {
                service => $service,
                health => $result->{$service}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check health.

=over 8

=item B<--filter-serial>

Filter by firewall serial (can be a regexp).

=item B<--unknown-service-status>

Set unknown threshold for status.
Can used special variables like: %{health}, %{service}

=item B<--warning-service-status>

Set warning threshold for status (Default: '%{health} =~ /minor/i').
Can used special variables like: %{health}, %{service}

=item B<--critical-service-status>

Set critical threshold for status (Default: '%{health} =~ /major/i').
Can used special variables like: %{health}, %{service}

=back

=cut
