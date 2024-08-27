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

package network::oneaccess::snmp::mode::rttprobes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_signal_perfdata {
    my ($self) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [
            $self->{result_values}->{cellId},
            $self->{result_values}->{operator}
        ],
        value => $self->{result_values}->{ $self->{key_values}->[0]->{name} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [admin: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{adminStatus}
    );
}

sub prefix_probe_output {
    my ($self, %options) = @_;

    return sprintf(
        "rtt probe '%s' [type: %s] ",
        $options{instance_value}->{tag}, 
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'probes', type => 1, cb_prefix_output => 'prefix_probe_output', message_multiple => 'All rtt probes are ok' }
    ];

    $self->{maps_counters}->{probes} = [
        {
            label => 'probe-status',
            type => 2,
            critical_default => '%{adminStatus} eq "active" and %{status} ne "ok"',
            set => {
                key_values => [
                    { name => 'adminStatus' }, { name => 'status' },
                    { name => 'tag' }, { name => 'type' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'probe-completion-time', nlabel => 'probe.completion.time.milliseconds', set => {
                key_values => [ { name => 'completionTime' }, { name => 'tag' } ],
                output_template => 'completion time: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'tag' }
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
        'filter-tag:s'  => { name => 'filter_tag' }
    });

    return $self;
}

my $map_admin_status = {
    1 => 'active', 2 => 'notInService', 3 => 'notReady', 
    4 => 'createAndGo', 5 => 'createAndWait', 6 => 'destroy'
};
my $map_type = {
    0 => 'unknown', 1 => 'echo', 2 => 'pathEcho', 4 => 'http', 10 => 'pathJitter'
};
my $map_status = {
    1 => 'ok', 2 => 'disconnected', 3 => 'overThreshold',
    4 => 'timeout', 5 => 'busy', 6 => 'notConnected',
    7 => 'dropped', 8 => 'sequenceError', 9 => 'verifyError',
    10 => 'applicationSpecific', 16 => 'error'
};

my $mapping = {
    adminStatus    => { oid => '.1.3.6.1.4.1.13191.10.3.4.1223.1.1.1.1.2', map => $map_admin_status }, # oacRttControlStatus
    type           => { oid => '.1.3.6.1.4.1.13191.10.3.4.1223.1.1.1.1.5', map => $map_type }, # oacRttControlRttType
    threshold      => { oid => '.1.3.6.1.4.1.13191.10.3.4.1223.1.1.1.1.8' }, # oacRttControlThreshold
    status         => { oid => '.1.3.6.1.4.1.13191.10.3.4.1223.1.1.10.1.2', map => $map_status }, # oacRttLatestRttOperSense
    completionTime => { oid => '.1.3.6.1.4.1.13191.10.3.4.1223.1.1.10.1.5' } # oacRttLatestRttOperCompletionTime
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{probes} = {};

    my $oid_tag = '.1.3.6.1.4.1.13191.10.3.4.1223.1.1.1.1.3'; # oacRttControlTag
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_tag,
        nothing_quit => 1
    );
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_tag\.(.*)$/;
        my $instance = $1;

        next if (defined($self->{option_results}->{filter_tag}) && $self->{option_results}->{filter_tag} ne '' &&
            $snmp_result->{$oid} !~ /$self->{option_results}->{filter_tag}/);

        $self->{probes}->{$instance} = {
            tag => $snmp_result->{$oid}
        };
    }

    return if (scalar(keys %{$self->{probes}}) <= 0);
    
    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_, keys %{$self->{probes}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();

    foreach (keys %{$self->{probes}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{probes}->{$_}->{adminStatus} = $result->{adminStatus};
        $self->{probes}->{$_}->{type} = $result->{type};
        $self->{probes}->{$_}->{status} = $result->{status};
        $self->{probes}->{$_}->{completionTime} = $result->{completionTime};

        if (!defined($self->{option_results}->{'critical-instance-probe-completion-time-milliseconds'}) || $self->{option_results}->{'critical-instance-probe-completion-time-milliseconds'} eq '') {
            $self->{perfdata}->threshold_validate(label => 'critical-instance-probe-completion-time-milliseconds', value => $result->{threshold});
        }
    }
}

1;

__END__

=head1 MODE

Check round-trip time probes.

=over 8

=item B<--filter-tag>

Filter probes by name.

=item B<--unknown-probe-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{adminStatus}, %{status}, %{type}, %{tag}

=item B<--warning-probe-estatus>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{adminStatus}, %{status}, %{type}, %{tag}

=item B<--critical-probe-status>

Define the conditions to match for the status to be CRITICAL (default: '%{adminStatus} eq "active" and %{status} ne "ok"').
You can use the following variables: %{adminStatus}, %{status}, %{type}, %{tag}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'probe-completion-time'.

=back

=cut
