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

package cloud::microsoft::office365::sharepoint::mode::siteusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::Local;

sub custom_active_perfdata {
    my ($self, %options) = @_;

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{result_values}->{report_date} =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/;
    $self->{output}->perfdata_add(label => 'perfdate', value => timelocal(0,0,12,$3,$2-1,$1-1900));

    $self->{output}->perfdata_add(label => 'active_sites', nlabel => 'sharepoint.sites.active.count',
                                  value => $self->{result_values}->{active},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  unit => 'sites', min => 0, max => $self->{result_values}->{total});
}

sub custom_active_threshold {
    my ($self, %options) = @_;

    my $threshold_value = $self->{result_values}->{active};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_active};
    }
    my $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;

}

sub custom_active_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Active sites on %s : %d/%d (%.2f%%)",
                        $self->{result_values}->{report_date},
                        $self->{result_values}->{active},
                        $self->{result_values}->{total},
                        $self->{result_values}->{prct_active});
    return $msg;
}

sub custom_active_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_active'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{report_date} = $options{new_datas}->{$self->{instance} . '_report_date'};
    $self->{result_values}->{prct_active} = ($self->{result_values}->{total} != 0) ? $self->{result_values}->{active} * 100 / $self->{result_values}->{total} : 0;

    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    
    $self->{output}->perfdata_add(label => 'used' . $extra_label, nlabel => $self->{result_values}->{display} . '#sharepoint.sites.usage.bytes', 
                                  unit => 'B',
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value,
                                               threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' },
                                                              { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($free_value, $free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)", 
            $total_value . " " . $total_unit, 
            $used_value . " " . $used_unit, $self->{result_values}->{prct_used}, 
            $free_value . " " . $free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_url'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_storage_allocated'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_storage_used'};

    if ($self->{result_values}->{total} != 0) {
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    } else {
        $self->{result_values}->{free} = '0';
        $self->{result_values}->{prct_used} = '0';
        $self->{result_values}->{prct_free} = '0';
    }

    return 0;
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total ";
}

sub prefix_site_output {
    my ($self, %options) = @_;
    
    return "Site '" . $options{instance_value}->{url} . "' [ID: " . $options{instance_value}->{id} . "] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'active', type => 0 },
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'sites', type => 1, cb_prefix_output => 'prefix_site_output', message_multiple => 'All sites usage are ok' },
    ];
    
    $self->{maps_counters}->{active} = [
        { label => 'active-sites', set => {
                key_values => [ { name => 'active' }, { name => 'total' }, { name => 'report_date' } ],
                closure_custom_calc => $self->can('custom_active_calc'),
                closure_custom_output => $self->can('custom_active_output'),
                closure_custom_threshold_check => $self->can('custom_active_threshold'),
                closure_custom_perfdata => $self->can('custom_active_perfdata')
            }
        },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total-usage-active', nlabel => 'sharepoint.sites.active.usage.total.bytes', set => {
                key_values => [ { name => 'storage_used_active' } ],
                output_template => 'Usage (active sites): %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_usage_active', value => 'storage_used_active', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'total-usage-inactive', nlabel => 'sharepoint.sites.inactive.usage.total.bytes', set => {
                key_values => [ { name => 'storage_used_inactive' } ],
                output_template => 'Usage (inactive sites): %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_usage_inactive', value => 'storage_used_inactive', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'total-file-count-active', nlabel => 'sharepoint.sites.active.files.total.count', set => {
                key_values => [ { name => 'file_count_active' } ],
                output_template => 'File Count (active sites): %d',
                perfdatas => [
                    { label => 'total_file_count_active', value => 'file_count_active', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-file-count-inactive', nlabel => 'sharepoint.sites.inactive.files.total.count', set => {
                key_values => [ { name => 'file_count_inactive' } ],
                output_template => 'File Count (inactive sites): %d',
                perfdatas => [
                    { label => 'total_file_count_inactive', value => 'file_count_inactive', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-active-file-count', nlabel => 'sharepoint.sites.files.active.total.count', set => {
                key_values => [ { name => 'active_file_count' } ],
                output_template => 'Active File Count (active sites): %d',
                perfdatas => [
                    { label => 'total_active_file_count', value => 'active_file_count', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-visited-page-count', nlabel => 'sharepoint.sites.pages.visited.total.count', set => {
                key_values => [ { name => 'visited_page_count' } ],
                output_template => 'Visited Page Count (active sites): %d',
                perfdatas => [
                    { label => 'total_visited_page_count', value => 'visited_page_count', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'total-page-view-count', nlabel => 'sharepoint.sites.pages.viewed.total.count', set => {
                key_values => [ { name => 'page_view_count' } ],
                output_template => 'Page View Count (active sites): %d',
                perfdatas => [
                    { label => 'total_page_view_count', value => 'page_view_count', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{sites} = [
        { label => 'usage', set => {
                key_values => [ { name => 'storage_used' }, { name => 'storage_allocated' }, { name => 'url' }, { name => 'id' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'file-count', nlabel => 'sharepoint.sites.files.count', set => {
                key_values => [ { name => 'file_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'File Count: %d',
                perfdatas => [
                    { label => 'file_count', value => 'file_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'url' },
                ],
            }
        },
        { label => 'active-file-count', nlabel => 'sharepoint.sites.files.active.count', set => {
                key_values => [ { name => 'active_file_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'Active File Count: %d',
                perfdatas => [
                    { label => 'active_file_count', value => 'active_file_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'url' },
                ],
            }
        },
        { label => 'visited-page-count', nlabel => 'sharepoint.sites.pages.visited.count', set => {
                key_values => [ { name => 'visited_page_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'Visited Page Count: %d',
                perfdatas => [
                    { label => 'visited_page_count', value => 'visited_page_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'url' },
                ],
            }
        },
        { label => 'page-view-count', nlabel => 'sharepoint.sites.pages.viewed.count', set => {
                key_values => [ { name => 'page_view_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'Page View Count: %d',
                perfdatas => [
                    { label => 'page_view_count', value => 'page_view_count', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'url' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-url:s"          => { name => 'filter_url' },
        "filter-id:s"           => { name => 'filter_id' },
        "units:s"               => { name => 'units', default => '%' },
        "free"                  => { name => 'free' },
        "filter-counters:s"     => { name => 'filter_counters', default => 'active-sites|total' }, 
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{active} = { active => 0, total => 0, report_date => '' };
    $self->{global} = { storage_used_active => 0, storage_used_inactive => 0,
                        file_count_active => 0, file_count_inactive => 0,
                        active_file_count => 0 , visited_page_count => 0 , page_view_count => 0 };
    $self->{sites} = {};

    my $results = $options{custom}->office_get_sharepoint_site_usage(param => "period='D7'");
    my $results_daily = [];
    if (scalar(@{$results})) {
       $self->{active}->{report_date} = @{$results}[0]->{'Report Refresh Date'};
       $results_daily = $options{custom}->office_get_sharepoint_site_usage(param => "date=" . $self->{active}->{report_date});
    }

    foreach my $site (@{$results}, @{$results_daily}) {
        if (defined($self->{option_results}->{filter_url}) && $self->{option_results}->{filter_url} ne '' &&
            $site->{'Site URL'} !~ /$self->{option_results}->{filter_url}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $site->{'Site URL'} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_id}) && $self->{option_results}->{filter_id} ne '' &&
            $site->{'Site Id'} !~ /$self->{option_results}->{filter_id}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $site->{'Site Id'} . "': no matching filter name.", debug => 1);
            next;
        }

        if ($site->{'Report Period'} != 1) {
            if (!defined($site->{'Last Activity Date'}) || ($site->{'Last Activity Date'} ne $self->{active}->{report_date})) {
                $self->{global}->{storage_used_inactive} += ($site->{'Storage Used (Byte)'} ne '') ? $site->{'Storage Used (Byte)'} : 0;
                $self->{global}->{file_count_inactive} += ($site->{'File Count'} ne '') ? $site->{'File Count'} : 0;
                $self->{output}->output_add(long_msg => "skipping '" . $site->{'Site URL'} . "': no activity.", debug => 1);
            }
            $self->{active}->{total}++;
            next;
        }

        $self->{active}->{active}++;

        $self->{global}->{storage_used_active} += ($site->{'Storage Used (Byte)'} ne '') ? $site->{'Storage Used (Byte)'} : 0;
        $self->{global}->{file_count_active} += ($site->{'File Count'} ne '') ? $site->{'File Count'} : 0;
        $self->{global}->{active_file_count} += ($site->{'Active File Count'} ne '') ? $site->{'Active File Count'} : 0;
        $self->{global}->{visited_page_count} += ($site->{'Visited Page Count'} ne '') ? $site->{'Visited Page Count'} : 0;
        $self->{global}->{page_view_count} += ($site->{'Page View Count'} ne '') ? $site->{'Page View Count'} : 0;
        
        $self->{sites}->{$site->{'Site URL'}}->{url} = $site->{'Site URL'};
        $self->{sites}->{$site->{'Site URL'}}->{id} = $site->{'Site Id'};
        $self->{sites}->{$site->{'Site URL'}}->{file_count} = $site->{'File Count'};
        $self->{sites}->{$site->{'Site URL'}}->{active_file_count} = $site->{'Active File Count'};
        $self->{sites}->{$site->{'Site URL'}}->{visited_page_count} = $site->{'Visited Page Count'};
        $self->{sites}->{$site->{'Site URL'}}->{page_view_count} = $site->{'Page View Count'};
        $self->{sites}->{$site->{'Site URL'}}->{storage_used} = $site->{'Storage Used (Byte)'};
        $self->{sites}->{$site->{'Site URL'}}->{storage_allocated} = $site->{'Storage Allocated (Byte)'};
        $self->{sites}->{$site->{'Site URL'}}->{last_activity_date} = $site->{'Last Activity Date'};
    }
}

1;

__END__

=head1 MODE

Check sites usage (reporting period over the last refreshed day).

(See link for details about metrics :
https://docs.microsoft.com/en-us/microsoft-365/admin/activity-reports/sharepoint-site-usage?view=o365-worldwide)

=over 8

=item B<--filter-*>

Filter sites.
Can be: 'url', 'id' (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'active-sites',
'total-usage-active' (count), 'total-usage-inactive' (count),
'total-file-count-active' (count), 'total-file-count-inactive' (count),
'total-active-file-count' (count), 'total-visited-page-count' (count),
'total-page-view-count' (count),
'usage' (count), 'file-count' (count), 'active-file-count' (count),
'visited-page-count' (count), 'page-view-count' (count).

=item B<--critical-*>

Threshold critical.
Can be: 'active-sites',
'total-usage-active' (count), 'total-usage-inactive' (count),
'total-file-count-active' (count), 'total-file-count-inactive' (count),
'total-active-file-count' (count), 'total-visited-page-count' (count),
'total-page-view-count' (count),
'usage' (count), 'file-count' (count), 'active-file-count' (count),
'visited-page-count' (count), 'page-view-count' (count).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to hide per user counters: --filter-counters='active-sites|total'
(Default: 'active-sites|total')

=item B<--units>

Unit of thresholds (Default: '%') ('%', 'count').

=back

=cut
