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

package database::oracle::mode::datafilesstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_traffic_calc {
    my ($self, %options) = @_;

    my $total_traffic = -1;
    foreach (keys %{$options{new_datas}}) {
        if (/^(.*)_(phyrds|phywrts)$/) {
            my $new_total = $options{new_datas}->{$_};
            next if (!defined($options{old_datas}->{$_}));
            $total_traffic = 0 if ($total_traffic == -1);

            my $old_total = $options{old_datas}->{$_};
            if ($old_total > $new_total) {
                $options{old_datas}->{$_} = 0;
                $old_total = 0;
            }

            my $diff_total = $new_total - $old_total;
            $total_traffic += $diff_total;
        }
    }

    if ($total_traffic == -1) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    $self->{result_values}->{traffic} = $total_traffic  / $options{delta_time};
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'df', type => 1, cb_prefix_output => 'prefix_df_output', message_multiple => 'All data files are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-traffic', nlabel => 'datafiles.traffic.io.usage.iops', set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_traffic_calc'),
                threshold_use => 'traffic', output_use => 'traffic',
                output_template => 'Total Traffic IOPs %.2f',
                perfdatas => [
                    { label => 'total_traffic', value => 'traffic', template => '%.2f', min => 0 , unit => 'iops' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{df} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'online-status', threshold => 0, set => {
                key_values => [ { name => 'online_status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_online_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
    ];
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-tablespace:s'       => { name => 'filter_tablespace' },
        'filter-data-file:s'        => { name => 'filter_data_file' },
        'warning-status:s'          => { name => 'warning_status', default => '' },
        'critical-status:s'         => { name => 'critical_status', default => '%{status} =~ /offline|invalid/i' },
        'warning-online-status:s'   => { name => 'warning_online_status', default => '%{online_status} =~ /sysoff/i' },
        'critical-online-status:s'  => { name => 'critical_online_status', default => '%{online_status} =~ /offline|recover/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'warning_online_status', 'critical_online_status']);
}

sub prefix_df_output {
    my ($self, %options) = @_;

    return "Data file '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $options{sql}->connect();
    
    if ($options{sql}->is_version_minimum(version => '10')) {
        $options{sql}->query(query => q{
            SELECT a.file_name, a.tablespace_name, a.status, b.phyrds, b.phywrts, a.online_status
                FROM dba_data_files a, v$filestat b
                WHERE a.file_id = b.file#
            UNION
            SELECT a.name, c.name, a.status, b.phyrds, b.phywrts, NULL
                FROM v$tempfile a, v$tablespace c, v$tempstat b
                WHERE a.ts#= c.ts# AND a.file# = b.file#
        });
    } else {
        $options{sql}->query(query => q{
            SELECT a.file_name, a.tablespace_name, a.status, b.phyrds, b.phywrts
                FROM dba_data_files a, v$filestat b
                WHERE a.file_id = b.file#
            UNION
            SELECT a.name, c.name, a.status, b.phyrds, b.phywrts
                FROM v$tempfile a, v$tablespace c, v$tempstat b
                WHERE a.ts#= c.ts# AND a.file# = b.file#
         });
    }
    my $result = $options{sql}->fetchall_arrayref();
    $options{sql}->disconnect();

    $self->{global} = {};
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
        
        my $name = $$row[1] . '/' . $$row[0];
        $self->{df}->{$name} = { 
            status => $$row[2], 
            online_status => defined($$row[5]) ? $$row[5] : undef, 
            display => $name
        };
        $self->{global}->{$name . '_phyrds'} = $$row[3];
        $self->{global}->{$name . '_phywrts'} = $$row[4];
    }

    if (scalar(keys %{$self->{df}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No data file found");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "oracle_" . $self->{mode} . '_' . $options{sql}->get_unique_id4save() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_tablespace}) ? md5_hex($self->{option_results}->{filter_tablespace}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_data_file}) ? md5_hex($self->{option_results}->{filter_data_file}) : md5_hex('all'));
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

Set critical threshold for status (Default: '%{status} =~ /offline|invalid/i').
Can used special variables like: %{display}, %{status}

=item B<--warning-online-status>

Set warning threshold for online status (Default: '%{online_status} =~ /sysoff/i').
Can used special variables like: %{display}, %{online_status}

=item B<--critical-online-status>

Set critical threshold for online status (Default: '%{online_status} =~ /offline|recover/i').
Can used special variables like: %{display}, %{online_status}

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'total-traffic'.

=back

=cut
