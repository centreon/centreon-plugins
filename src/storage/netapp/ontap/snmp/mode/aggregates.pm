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

package storage::netapp::ontap::snmp::mode::aggregates;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_agg_output {
    my ($self, %options) = @_;

    return "Aggregate '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'agg', type => 1, cb_prefix_output => 'prefix_agg_output', message_multiple => 'All aggregates are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{agg} = [
        { label => 'state', type => 2, critical_default => '%{state} =~ /offline/i',set => {
                key_values => [ { name => 'state' }, { name => 'name' } ],
                output_template => "state: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'status', type => 2, critical_default => '%{status} !~ /normal|mirrored/i', set => {
                key_values => [ { name => 'status' }, { name => 'name' } ],
                output_template => "status: '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    state  => { oid => '.1.3.6.1.4.1.789.1.5.11.1.5' }, # aggrState
    status => { oid => '.1.3.6.1.4.1.789.1.5.11.1.6' }  # aggrStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_aggrName = '.1.3.6.1.4.1.789.1.5.11.1.2';

    $self->{agg} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_aggrName, nothing_quit => 1);
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_aggrName\.(.*)$/;
        my $instance = $1;
        my $name = $snmp_result->{$oid};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping aggregatge '" . $name . "'.", debug => 1);
            next;
        }

        $self->{agg}->{$instance} = { name => $name };
    }

    if (scalar(keys %{$self->{agg}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No aggregate found");
        $self->{output}->option_exit();
    }
    
    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [keys %{$self->{agg}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    
    foreach (keys %{$self->{agg}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{agg}->{$_}->{state} = $result->{state};
        $self->{agg}->{$_}->{status} = $result->{status};
    }
}

1;

__END__

=head1 MODE

Check aggregates.

=over 8

=item B<--filter-name>

Filter aggregates by name.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /normal|mirrored/i').
You can use the following variables: %{status}, %{name}

=item B<--unknown-state>

Set unknown threshold for state.
You can use the following variables: %{state}, %{name}

=item B<--warning-state>

Set warning threshold for state.
You can use the following variables: %{state}, %{name}

=item B<--critical-state>

Set critical threshold for state (default: '%{state} =~ /offline/i').
You can use the following variables: %{state}, %{name}

=back

=cut
