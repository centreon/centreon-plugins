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

package apps::inin::ig::snmp::mode::spanusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_i3IgSpanInfoSpanState'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'span', type => 1, cb_prefix_output => 'prefix_span_output', message_multiple => 'All spans are ok' }
    ];
    
    $self->{maps_counters}->{span} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'i3IgSpanInfoSpanState' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'active-channels', set => {
                key_values => [ { name => 'i3IgSpanInfoActiveChannels' }, { name => 'display' } ],
                output_template => 'Current Active Channels : %s',
                perfdatas => [
                    { label => 'active_channels', value => 'i3IgSpanInfoActiveChannels', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-name:s"       => { name => 'filter_name' },
                                  "warning-status:s"    => { name => 'warning_status', default => '' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{status} !~ /closed|ready/i' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_span_output {
    my ($self, %options) = @_;
    
    return "Span '" . $options{instance_value}->{display} . "' ";
}

my %map_state = (0 => 'closed', 1 => 'ready', 2 => 'alarm', 3 => 'error');
my $mapping = {
    i3IgSpanInfoSpanId          => { oid => '.1.3.6.1.4.1.2793.4.2.3.1.3' },
    i3IgSpanInfoActiveChannels  => { oid => '.1.3.6.1.4.1.2793.4.2.3.1.5' },
    i3IgSpanInfoSpanState       => { oid => '.1.3.6.1.4.1.2793.4.2.3.1.6', map => \%map_state },
};

my $oid_i3IgSpanInfoTableEntry = '.1.3.6.1.4.1.2793.4.2.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{span} = {};
    my $snmp_result = $options{snmp}->get_table(oid => $oid_i3IgSpanInfoTableEntry,
                                                nothing_quit => 1);

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{i3IgSpanInfoSpanState}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{i3IgSpanInfoSpanId} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{i3IgSpanInfoSpanId} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{span}->{$instance} = { 
            display => $result->{i3IgSpanInfoSpanId},
            %$result
        };
    }
    
    if (scalar(keys %{$self->{span}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No span found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check span usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter span name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /closed|ready/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'active-channels'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-channels'.

=back

=cut
