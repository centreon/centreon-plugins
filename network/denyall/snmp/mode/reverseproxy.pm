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

package network::denyall::snmp::mode::reverseproxy;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub rp_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking reverse proxy '%s'",
        $options{instance_value}->{uid}
    );
}

sub prefix_rp_output {
    my ($self, %options) = @_;

    return sprintf(
        "reverse proxy '%s' ",
        $options{instance_value}->{uid}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'rps', type => 3, cb_prefix_output => 'prefix_rp_output', cb_long_output => 'rp_long_output',
          indent_long_output => '    ', message_multiple => 'All reverse proxies are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', type => 0, skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status', type => 2, critical_default => '%{status} =~ /down/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'uid' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
         { label => 'cpu-utilization', nlabel => 'reverse_proxy.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' } ],
                output_template => 'cpu usage: %.2f %%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
         { label => 'memory-usage', nlabel => 'reverse_proxy.memory.usage.bytes', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'memory used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
         { label => 'requests', nlabel => 'reverse_proxy.requests.persecond', set => {
                key_values => [ { name => 'requests_psec' } ],
                output_template => 'requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1 }
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
        'filter-uid:s' => { name => 'filter_uid' }
    });

    return $self;
}

my $map_status = { 0 => 'down', 1 => 'ok' };

my $mapping = {
    status        => { oid => '.1.3.6.1.4.1.18433.10.1.1.1.8.2.1.3', map => $map_status }, # rpStatus
    cpu_usage     => { oid => '.1.3.6.1.4.1.18433.10.1.1.1.8.2.1.4' }, # rpCpuUsage
    memory_used   => { oid => '.1.3.6.1.4.1.18433.10.1.1.1.8.2.1.5' }, # rpMemoryUsage (MB)
    requests_psec => { oid => '.1.3.6.1.4.1.18433.10.1.1.1.8.2.1.11' } # rpRqstsPrSecond
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_uid = '.1.3.6.1.4.1.18433.10.1.1.1.8.2.1.2'; # rpUid
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_uid,
        nothing_quit => 1
    );

    $self->{rps} = {};
    foreach (keys %$snmp_result) {
        /\.(\d+)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_uid}) && $self->{option_results}->{filter_uid} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_uid}/) {
            $self->{output}->output_add(long_msg => "skipping reverse proxy '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{rps}->{ $snmp_result->{$_} } = {
            uid => $snmp_result->{$_},
            instance => $instance
        };
    }

    return if (scalar(keys %{$self->{rps}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{rps}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{rps}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{rps}->{$_}->{instance});

        $self->{rps}->{$_}->{memory} = { memory_used => $result->{memory_used} * 1024 * 1024 };
        $self->{rps}->{$_}->{cpu} = { cpu_usage => $result->{cpu_usage} };
        $self->{rps}->{$_}->{status} = { status => $result->{status}, uid => $_ };
        $self->{rps}->{$_}->{traffic} = { requests_psec => $result->{requests_psec} };
    }
}

1;

__END__

=head1 MODE

Check reverse proxies.

=over 8

=item B<--filter-uid>

Filter reverse proxy by UID (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{uid}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{uid}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down/i').
Can used special variables like: %{status}, %{uid}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'cpu-utilization', 'memory-usage', 'requests'.

=back

=cut
