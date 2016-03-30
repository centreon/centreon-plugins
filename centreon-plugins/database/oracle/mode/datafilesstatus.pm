#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package database::oracle::mode::datafilesstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'df', type => 1, cb_prefix_output => 'prefix_df_output', message_multiple => 'All data files are ok' },
    ];

    $self->{maps_counters}->{df} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'online-status', threshold => 0, set => {
                key_values => [ { name => 'online_status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_online_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
    ];
}

my $instance_mode;

sub custom_threshold_output {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{'critical_' . $self->{result_values}->{label_th}}) && $instance_mode->{option_results}->{'critical_' . $self->{result_values}->{label_th}} ne '' &&
            eval "$instance_mode->{option_results}->{'critical_' . $self->{result_values}->{label_th}}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{'warning_' . $self->{result_values}->{label_th}}) && $instance_mode->{option_results}->{'warning_' . $self->{result_values}->{label_th}} ne '' &&
                 eval "$instance_mode->{option_results}->{'warning_' . $self->{result_values}->{label_th}}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg = $self->{result_values}->{label_display} . ' : ' . $self->{result_values}->{$self->{result_values}->{label_th}};

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{label_display} = 'Status';
    $self->{result_values}->{label_th} = 'status';
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub custom_online_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{label_display} = 'Online Status';
    $self->{result_values}->{label_th} = 'online_status';
    $self->{result_values}->{online_status} = $options{new_datas}->{$self->{instance} . '_online_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-tablespace:s"       => { name => 'filter_tablespace' },
                                "filter-data-file:s"        => { name => 'filter_data_file' },
                                "warning-status:s"          => { name => 'warning_status', default => '' },
                                "critical-status:s"         => { name => 'critical_status', default => '' },
                                "warning-online-status:s"   => { name => 'warning_online_status', default => '%{online_status} =~ /sysoff/i' },
                                "critical-online-status:s"  => { name => 'critical_online_status', default => '%{online_status} =~ /offline|recover/i' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
    $self->change_macros();
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_status', 'critical_status', 'warning_online_status', 'critical_online_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub prefix_df_output {
    my ($self, %options) = @_;

    return "Data file '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $options{sql}->connect();
    $options{sql}->query(query => "SELECT file_name, tablespace_name, status, online_status
                                  FROM dba_data_files");
    my $result = $options{sql}->fetchall_arrayref();
    
    $self->{df} = {};
    foreach my $row (@$result) {
        if (defined($self->{option_results}->{filter_data_file}) && $self->{option_results}->{filter_data_file} ne '' &&
            $$row[0] !~ /$self->{option_results}->{filter_data_file}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $$row[0] . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_tablespace}) && $self->{option_results}->{filter_tablespace} ne '' &&
            $$row[1] !~ /$self->{option_results}->{filter_tablespace}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $$row[1] . "': no matching filter.", debug => 1);
            next
        }
        $self->{df}->{$$row[1] . '/' . $$row[0]} = { status => $$row[2], online_status => $$row[3], display => $$row[1] . '/' . $$row[0] };
    }
}

1;

__END__

=head1 MODE

Check data files status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--filter-tablespace>

Filter tablespace name (can be a regexp).

=item B<--filter-data-file>

Filter data file name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: none).
Can used special variables like: %{display}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: none).
Can used special variables like: %{display}, %{status}

=item B<--warning-online-status>

Set warning threshold for online status (Default: '%{online_status} =~ /sysoff/i').
Can used special variables like: %{display}, %{online_status}

=item B<--critical-online-status>

Set critical threshold for online status (Default: '%{online_status} =~ /offline|recover/i').
Can used special variables like: %{display}, %{online_status}

=back

=cut
