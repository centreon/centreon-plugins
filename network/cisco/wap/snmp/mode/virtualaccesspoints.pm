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

package network::cisco::wap::snmp::mode::virtualaccesspoints;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'operational status: %s [admin: %s]',
        $self->{result_values}->{operational_status},
        $self->{result_values}->{admin_status}
    );
}

sub prefix_vap_output {
    my ($self, %options) = @_;

    return sprintf(
        "Virtual access point '%s' ",
        $options{instance_value}->{description}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'vaps', type => 1, cb_prefix_output => 'prefix_vap_output', message_multiple => 'All virtual access points are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'virtual_access_points.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vaps} = [
        {
            label => 'status', type => 2, critical_default => '%{admin_status} eq "up" and %{operational_status} eq "down"',
            set => {
                key_values => [
                    { name => 'description' }, { name => 'admin_status' },
                    { name => 'operational_status' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
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
        'filter-description:s'  => { name => 'filter_description' }
    });

    return $self;
}

my $map_status = { 0 => 'down', 1 => 'up' };

my $mapping = {
    admin_status       => { oid => '.1.3.6.1.4.1.9.6.1.104.1.4.1.1.3', map => $map_status }, # apVapStatus
    operational_status => { oid => '.1.3.6.1.4.1.9.6.1.104.1.4.1.1.14', map => $map_status }, # apVapOperationalStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_description = '.1.3.6.1.4.1.9.6.1.104.1.4.1.1.5'; # apVapDescription
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_description,
        nothing_quit => 1
    );

    $self->{vaps} = {};
    foreach (keys %$snmp_result) {
        /^$oid_description\.(.*)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_description}) && $self->{option_results}->{filter_description} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_description}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$_} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vaps}->{$instance} = {
            description => $snmp_result->{$_}
        };
    }

    $self->{global} = { total => scalar(keys %{$self->{vaps}}) };

    return if (scalar(keys %{$self->{vaps}}) <= 0);

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [keys %{$self->{vaps}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{vaps}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{vaps}->{$_} = { %{$self->{vaps}->{$_}}, %$result };
    }
}

1;

__END__

=head1 MODE

Check virtual access points.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-description>

Filter virtual access points by description (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{description}, %{admin_status}, %{operational_status}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{description}, %{admin_status}, %{operational_status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{admin_status} eq "up" and %{operational_status} eq "down"').
Can used special variables like: %{description}, %{admin_status}, %{operational_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total'.

=back

=cut
