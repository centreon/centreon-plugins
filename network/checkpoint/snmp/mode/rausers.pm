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

package network::checkpoint::snmp::mode::rausers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_ratunnel_output {
    my ($self, %options) = @_;

    return "Remote user '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ratunnel', type => 1, cb_prefix_output => 'prefix_ratunnel_output', message_multiple => 'All remote access users tunnel are OK' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'users-total', nlabel => 'remoteaccess.users.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'current total number of remote access users: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ratunnel} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'display' }, { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /down/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $map_state = {
    3 => 'active', 4 => 'destroy', 129 => 'idle', 130 => 'phase1',
    131 => 'down', 132 => 'init'
};

my $mapping = {
    raUserName         => { oid => '.1.3.6.1.4.1.2620.500.9000.1.2' },
    raUserState        => { oid => '.1.3.6.1.4.1.2620.500.9000.1.20', map => $map_state }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $mapping->{raUserName}->{oid} },
            { oid => $mapping->{raUserState}->{oid} }
        ],
        nothing_quit => 1,
        return_type => 1
    );

    $self->{ratunnel} = {};
    $self->{global} = { total => 0 };
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{raUserState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{raUserName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{raUserName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{ratunnel}->{$instance} = {
            display => $result->{raUserName}, 
            status => $result->{raUserState}
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check Remote Access users tunnel information

=over 8

=item B<--filter-name>

Filter on remote access users (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{display}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down/i').
Can used special variables like: %{display}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'users-total'.

=back

=cut
