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

package apps::haproxy::snmp::mode::frontendusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_frontend_output {
    my ($self, %options) = @_;

    return "Frontend '" . $options{instance_value}->{display} . "' ";
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("status : %s", $self->{result_values}->{status});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_alFrontendStatus'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'frontend', type => 1, cb_prefix_output => 'prefix_frontend_output', message_multiple => 'All frontends are ok' }
    ];
    
    $self->{maps_counters}->{frontend} = [
         {
            label => 'status', 
            type => 2, 
            critical_default => '%{status} !~ /OPEN/i',
            set => {
                key_values => [ { name => 'alFrontendStatus' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'current-sessions', nlabel => 'frontend.sessions.current.count', set => {
                key_values => [ { name => 'alFrontendSessionCur' }, { name => 'display' } ],
                output_template => 'Current sessions : %s',
                perfdatas => [
                    { label => 'current_sessions', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'total-sessions', nlabel => 'frontend.sessions.total.count', set => {
                key_values => [ { name => 'alFrontendSessionTotal', diff => 1 }, { name => 'display' } ],
                output_template => 'Total sessions : %s',
                perfdatas => [
                    { label => 'total_connections', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'frontend.traffic.in.bitpersecond', set => {
                key_values => [ { name => 'alFrontendBytesIN', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'frontend.traffic.out.bitpersecond', set => {
                key_values => [ { name => 'alFrontendBytesOUT', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

my $mapping = {
    entreprise => {
        alFrontendSessionCur    => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.4' },
        alFrontendSessionTotal  => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.7' },
        alFrontendBytesIN       => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.8' },
        alFrontendBytesOUT      => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.9' },
        alFrontendStatus        => { oid => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.13' }
    },
    csv => {
        alFrontendSessionCur     => { oid => '.1.3.6.1.4.1.29385.106.1.0.4' },
        alFrontendSessionTotal   => { oid => '.1.3.6.1.4.1.29385.106.1.0.7' },
        alFrontendBytesIN        => { oid => '.1.3.6.1.4.1.29385.106.1.0.8' },
        alFrontendBytesOUT       => { oid => '.1.3.6.1.4.1.29385.106.1.0.9' },
        alFrontendStatus         => { oid => '.1.3.6.1.4.1.29385.106.1.0.17' }
    },
};

my $mapping_name = {
    csv => '.1.3.6.1.4.1.29385.106.1.0.0',
    entreprise => '.1.3.6.1.4.1.23263.4.2.1.3.2.1.3' # alFrontendName
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_multiple_table(oids => [ { oid => $mapping_name->{csv} }, { oid => $mapping_name->{entreprise} } ], nothing_quit => 1);
    my $branch = 'entreprise';
    if (defined($snmp_result->{ $mapping_name->{csv} }) && scalar(keys %{$snmp_result->{ $mapping_name->{csv} }}) > 0) {
        $branch = 'csv';
    }

    $self->{frontend} = {};
    foreach my $oid (keys %{$snmp_result->{ $mapping_name->{$branch} }}) {
        $oid =~ /^$mapping_name->{$branch}\.(.*)$/;
        my $instance = $1;
        my $name = $snmp_result->{$mapping_name->{$branch}}->{$oid};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping frontend '" . $name . "'.", debug => 1);
            next;
        }

        $self->{frontend}->{$instance} = { display => $name };
    }

    if (scalar(keys %{$self->{frontend}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No frontend found.");
        $self->{output}->option_exit();
    }

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

        $result->{alFrontendBytesIN} *= 8;
        $result->{alFrontendBytesOUT} *= 8;

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

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /OPEN/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-sessions', 'current-sessions',
'traffic-in' (b/s), 'traffic-out' (b/s).

=back

=cut
