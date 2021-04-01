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

package apps::backup::rapidrecovery::snmp::mode::repository;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_space_output {
    my ($self, %options) = @_;

    my $msg = sprintf(
        "space total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'repository', type => 1, cb_prefix_output => 'prefix_repository_output', message_multiple => 'All repositories are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{repository} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'space-usage', nlabel => 'repository.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_space_output'),
                perfdatas => [
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'space-usage-free', display_ok => 0, nlabel => 'repository.space.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_space_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'space-usage-prct', display_ok => 0, nlabel => 'repository.space.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'space used: %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%',
                      label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '%{status} =~ /unknown/i' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /error/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub prefix_repository_output {
    my ($self, %options) = @_;
    
    return "Repository '" . $options{instance_value}->{display} . "' ";
}

my $map_status = {
    0 => 'unknown', 1 => 'unmounting',
    2 => 'unmounted', 3 => 'mounting',
    4 => 'mounted', 5 => 'maintenance',
    6 => 'error'
};

my $mapping = {
    repositoryName   => { oid => '.1.3.6.1.4.1.674.11000.1000.200.100.200.1.3' },
    repositoryStatus => { oid => '.1.3.6.1.4.1.674.11000.1000.200.100.200.1.5', map => $map_status },
    repositorySizeMB => { oid => '.1.3.6.1.4.1.674.11000.1000.200.100.200.1.6' },
    repositoryFreeMB => { oid => '.1.3.6.1.4.1.674.11000.1000.200.100.200.1.7' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_repositoryEntry = '.1.3.6.1.4.1.674.11000.1000.200.100.200.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_repositoryEntry,
        start => $mapping->{repositoryName}->{oid},
        nothing_quit => 1
    );

    $self->{repository} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{repositoryName}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{repositoryName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{repositoryName} . "': no matching filter.", debug => 1);
            next;
        }

        my $total = $result->{repositorySizeMB} * 1024 * 1024;
        my $free = $result->{repositoryFreeMB} * 1024 * 1024;
        $self->{repository}->{$instance} = {
            display => $result->{repositoryName},
            status => $result->{repositoryStatus},
            free => $free,
            used => $total - $free,
            prct_used => ($total - $free) * 100 / $total,
            prct_free => $free * 100 / $total,
            total => $total,
        };
    }
    
    if (scalar(keys %{$self->{repository}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No repository found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check repositories.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /error/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'space-usage' (B), 'space-usage-free' (B), 'space-usage-prct' (%).

=item B<--filter-name>

Filter repository name (can be a regexp).

=back

=cut
