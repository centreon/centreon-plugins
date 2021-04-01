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

package centreon::common::cisco::standard::snmp::mode::configuration;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => 'running_last_changed', unit => 's',
                                  value => sprintf("%d", $self->{result_values}->{running_last_changed}),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'running_last_saved', unit => 's',
                                  value => sprintf("%d", $self->{result_values}->{running_last_saved}),
                                  min => 0);
    $self->{output}->perfdata_add(label => 'startup_last_changed', unit => 's',
                                  value => sprintf("%d", $self->{result_values}->{startup_last_changed}),
                                  min => 0);
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Configuration Running Last Changed: %s, Running Last Saved: %s, Startup Last Changed: %s",
        ($self->{result_values}->{running_last_changed} > 0) ? centreon::plugins::misc::change_seconds(value => $self->{result_values}->{running_last_changed}) : "-",
        ($self->{result_values}->{running_last_saved} > 0) ? centreon::plugins::misc::change_seconds(value => $self->{result_values}->{running_last_saved}) : "-",
        ($self->{result_values}->{startup_last_changed} > 0) ? centreon::plugins::misc::change_seconds(value => $self->{result_values}->{startup_last_changed}) : "-");
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{running_last_changed} = $options{new_datas}->{$self->{instance} . '_running_last_changed'};
    $self->{result_values}->{running_last_saved} = $options{new_datas}->{$self->{instance} . '_running_last_saved'};
    $self->{result_values}->{startup_last_changed} = $options{new_datas}->{$self->{instance} . '_startup_last_changed'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'running_last_changed' }, { name => 'running_last_saved' }, { name => 'startup_last_changed' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold,
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
                                  "warning-status:s"  => { name => 'warning_status', default => '' },
                                  "critical-status:s" => { name => 'critical_status', default => '%{running_last_changed} > %{running_last_saved}' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $oid_ccmHistoryRunningLastChanged = '.1.3.6.1.4.1.9.9.43.1.1.1.0';
my $oid_ccmHistoryRunningLastSaved = '.1.3.6.1.4.1.9.9.43.1.1.2.0';
my $oid_ccmHistoryStartupLastChanged = '.1.3.6.1.4.1.9.9.43.1.1.3.0';

sub manage_selection {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    $self->{global} = {};

    $self->{results} = $self->{snmp}->get_leef(oids => [ $oid_ccmHistoryRunningLastChanged, $oid_ccmHistoryRunningLastSaved,
                                                      $oid_ccmHistoryStartupLastChanged ], nothing_quit => 1);
   
    $self->{global} = {
        running_last_changed => $self->{results}->{$oid_ccmHistoryRunningLastChanged} / 100,
        running_last_saved => $self->{results}->{$oid_ccmHistoryRunningLastSaved} / 100,
        startup_last_changed => $self->{results}->{$oid_ccmHistoryStartupLastChanged} / 100,
    }
}

1;

__END__

=head1 MODE

Check Cisco changed and saved configurations (CISCO-CONFIG-MAN-MIB).

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{running_last_changed}, %{running_last_saved}, %{startup_last_changed}

=item B<--critical-status>

Set critical threshold for status (Default: '%{running_last_changed} > %{running_last_saved}').
Can used special variables like: %{running_last_changed}, %{running_last_saved}, %{startup_last_changed}

=back

=cut
    
