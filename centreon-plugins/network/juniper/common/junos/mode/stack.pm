#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package network::juniper::common::junos::mode::stack;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("role: %s",
        $self->{result_values}->{role});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{roleLast} = $options{old_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    if (!defined($options{old_datas}->{$self->{instance} . '_role'})) {
        $self->{error_msg} = "buffer creation";
        return -2;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'stack', type => 1, cb_prefix_output => 'prefix_stack_output', message_multiple => 'All stack members are ok' },
    ];
    
    $self->{maps_counters}->{stack} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'role' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_stack_output {
    my ($self, %options) = @_;

    return "Stack member '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-status:s'      => { name => 'unknown_status', default => '' },
        'warning-status:s'      => { name => 'warning_status', default => '' },
        'critical-status:s'     => { name => 'critical_status', default => '%{role} ne %{roleLast}' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my %map_role = (
    1 => 'master',
    2 => 'backup',
    3 => 'linecard',
);

my $mapping = {
    jnxVirtualChassisMemberSerialnumber => { oid => '.1.3.6.1.4.1.2636.3.40.1.4.1.1.1.2' },
    jnxVirtualChassisMemberRole         => { oid => '.1.3.6.1.4.1.2636.3.40.1.4.1.1.1.3', map => \%map_role },
};
my $oid_jnxVirtualChassisMemberEntry = '.1.3.6.1.4.1.2636.3.40.1.4.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{stack} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_jnxVirtualChassisMemberEntry,
        start => $mapping->{jnxVirtualChassisMemberSerialnumber}->{oid},
        end => $mapping->{jnxVirtualChassisMemberRole}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{jnxVirtualChassisMemberRole}->{oid}\.(.*)$/);
        my $instance_id = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance_id);

        $self->{stack}->{$instance_id} = {
            display => $result->{jnxVirtualChassisMemberSerialnumber}, 
            role => $result->{jnxVirtualChassisMemberRole},
        };
    }

    $self->{cache_name} = "juniper_junos_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check stack members.

=over 8

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{role}, %{roleLast}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{role}, %{roleLast}

=item B<--critical-status>

Set critical threshold for status (Default: '%{role} ne %{roleLast}').
Can used special variables like: %{role}, %{roleLast}

=back

=cut
