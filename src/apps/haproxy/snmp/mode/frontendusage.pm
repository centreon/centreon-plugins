#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::haproxy::snmp::mode::frontendusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:values :counters);
use centreon::plugins::misc qw(is_excluded);

sub prefix_frontend_output {
    my ($self, %options) = @_;

    return "Frontend '" . $options{instance_value}->{display} . "' ";
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status: %s", $self->{result_values}->{status});
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'frontend', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_frontend_output', message_multiple => 'All frontends are ok' }
    ];
    
    $self->{maps_counters}->{frontend} = [
         {
            label => 'status', 
            type => COUNTER_KIND_TEXT,
            critical_default => '%{status} !~ /OPEN/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current-sessions', nlabel => 'frontend.sessions.current.count', set => {
                key_values => [ { name => 'sessionCur' }, { name => 'display' } ],
                output_template => 'current sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'total-sessions', nlabel => 'frontend.sessions.total.count', set => {
                key_values => [ { name => 'sessionTotal', diff => 1 }, { name => 'display' } ],
                output_template => 'total sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'frontend.traffic.in.bitpersecond', set => {
                key_values => [ { name => 'bytesIN', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'frontend.traffic.out.bitpersecond', set => {
                key_values => [ { name => 'bytesOUT', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

my $mapping = {
    aloha => {
        sessionCur   => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.4' },
        sessionTotal => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.7' },
        bytesIN      => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.8' },
        bytesOUT     => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.9' },
        status       => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.13' }
    },
    csv => {
        sessionCur   => { oid => '.1.3.6.1.4.1.29385.106.1.0.4' },
        sessionTotal => { oid => '.1.3.6.1.4.1.29385.106.1.0.7' },
        bytesIN      => { oid => '.1.3.6.1.4.1.29385.106.1.0.8' },
        bytesOUT     => { oid => '.1.3.6.1.4.1.29385.106.1.0.9' },
        status       => { oid => '.1.3.6.1.4.1.29385.106.1.0.17' }
    },
    hapee_legacy => {
        sessionCur   => { oid => '.1.3.6.1.4.1.23263.4.3.1.3.2.1.4' },
        sessionTotal => { oid => '.1.3.6.1.4.1.23263.4.3.1.3.2.1.7' },
        bytesIN      => { oid => '.1.3.6.1.4.1.23263.4.3.1.3.2.1.8' },
        bytesOUT     => { oid => '.1.3.6.1.4.1.23263.4.3.1.3.2.1.9' },
        status       => { oid => '.1.3.6.1.4.1.23263.4.3.1.3.2.1.13' }
    },
    hapee => {
        sessionCur   => { oid => '.1.3.6.1.4.1.58750.4.3.1.3.2.1.4' },
        sessionTotal => { oid => '.1.3.6.1.4.1.58750.4.3.1.3.2.1.7' },
        bytesIN      => { oid => '.1.3.6.1.4.1.58750.4.3.1.3.2.1.8' },
        bytesOUT     => { oid => '.1.3.6.1.4.1.58750.4.3.1.3.2.1.9' },
        status       => { oid => '.1.3.6.1.4.1.58750.4.3.1.3.2.1.13' }
    }
};

my $mapping_name = {
    csv          => '.1.3.6.1.4.1.29385.106.1.0.0',
    aloha        => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.3', # alFrontendName
    hapee_legacy => '.1.3.6.1.4.1.23263.4.3.1.3.2.1.3', # lbFrontendName
    hapee        => '.1.3.6.1.4.1.58750.4.3.1.3.2.1.3'  # lbFrontendName
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{output}->option_exit(short_msg => "Need to use SNMP v2c or v3.")
        if $options{snmp}->is_snmpv1();

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ map { { oid => $_ } } values(%$mapping_name) ],
        nothing_quit => 1
    );

    my $branch = 'aloha';
    if (defined($snmp_result->{ $mapping_name->{csv} }) && keys %{$snmp_result->{ $mapping_name->{csv} }}) {
        $branch = 'csv';
    } elsif (defined($snmp_result->{ $mapping_name->{hapee} }) && keys %{$snmp_result->{ $mapping_name->{hapee} }}) {
        $branch = 'hapee';
    } elsif (defined($snmp_result->{ $mapping_name->{hapee_legacy} }) && keys %{$snmp_result->{ $mapping_name->{hapee_legacy} }}) {
        $branch = 'hapee_legacy';
    }

    $self->{frontend} = {};
    foreach my $oid (keys %{$snmp_result->{ $mapping_name->{$branch} }}) {
        $oid =~ /^$mapping_name->{$branch}\.(.*)$/;
        my $instance = $1;
        my $name = $snmp_result->{$mapping_name->{$branch}}->{$oid};

        if (is_excluded($name, $self->{option_results}->{filter_name})) {
            $self->{output}->output_add(long_msg => "skipping frontend '" . $name . "'.", debug => 1);
            next;
        }

        $self->{frontend}->{$instance} = { display => $name };
    }

    $self->{output}->option_exit(short_msg => "No frontend found.")
        unless keys %{$self->{frontend}};

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%{$mapping->{$branch}})) 
        ],
        instances => [keys %{$self->{frontend}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{frontend}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$branch}, results => $snmp_result, instance => $_);

        $result->{bytesIN} *= 8;
        $result->{bytesOUT} *= 8;

        $self->{frontend}->{$_} = { %{$self->{frontend}->{$_}}, %$result };
    }

    $self->{cache_name} = 'haproxy_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check frontend usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total-connections$'

=item B<--filter-name>

Filter backend name (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /OPEN/i').
You can use the following variables: %{status}, %{display}

=item B<--warning-current-sessions>

Threshold.

=item B<--critical-current-sessions>

Threshold.

=item B<--warning-total-sessions>

Threshold.

=item B<--critical-total-sessions>

Threshold.

=item B<--warning-traffic-in>

Threshold in b/s.

=item B<--critical-traffic-in>

Threshold in b/s.

=item B<--warning-traffic-out>

Threshold in b/s.

=item B<--critical-traffic-out>

Threshold in b/s.

=back

=cut
