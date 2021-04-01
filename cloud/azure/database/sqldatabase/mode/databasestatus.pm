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

package cloud::azure::database::sqldatabase::mode::databasestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Status '%s'",
        $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub prefix_database_output {
    my ($self, %options) = @_;
    
    return "Database '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_database_output', message_multiple => 'All databases are ok' },
    ];

    $self->{maps_counters}->{databases} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
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
                                    "resource-group:s"      => { name => 'resource_group' },
                                    "server:s"              => { name => 'server' },
                                    "filter-name:s"         => { name => 'filter_name' },
                                    "warning-status:s"      => { name => 'warning_status', default => '' },
                                    "critical-status:s"     => { name => 'critical_status', default => '%{status} ne "Online"' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{resource_group}) || $self->{option_results}->{resource_group} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --resource-group option");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{server}) || $self->{option_results}->{server} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --server option");
        $self->{output}->option_exit();
    }

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{databases} = {};
    my $databases = $options{custom}->azure_list_sqldatabases(
        resource_group => $self->{option_results}->{resource_group},
        server => $self->{option_results}->{server}
    );
    foreach my $database (@{$databases}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $database->{name} !~ /$self->{option_results}->{filter_name}/);
        
        $self->{databases}->{$database->{id}} = {
            display => $database->{name},
            status => ($database->{status}) ? $database->{status} : $database->{properties}->{status},
        };
    }
    
    if (scalar(keys %{$self->{databases}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No SQL databases found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check SQL databases status.

Example: 
perl centreon_plugins.pl --plugin=cloud::azure::database::sqldatabase::plugin --custommode=azcli --mode=database-status
--resource-group='MYRESOURCEGROUP' --server='MyServer' --verbose

=over 8

=item B<--resource-group>

Set resource group (Required).

=item B<--server>

Set SQL server (Required).

=item B<--filter-name>

Filter database name (Can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} ne "Online"').
Can used special variables like: %{status}, %{display}

=back

=cut
