#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    
    $self->{output}->perfdata_add(label => 'used' . $extra_label,
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
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
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

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_id'};
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

sub prefix_site_output {
    my ($self, %options) = @_;
    
    return "Site '" . $options{instance_value}->{url} . "' [ID: " . $options{instance_value}->{id} . "] ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sites', type => 1, cb_prefix_output => 'prefix_site_output', message_multiple => 'All sites usage are ok' },
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
        { label => 'file-count', set => {
                key_values => [ { name => 'file_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'File Count: %d',
                perfdatas => [
                    { label => 'file_count', value => 'file_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'active-file-count', set => {
                key_values => [ { name => 'active_file_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'Active File Count: %d',
                perfdatas => [
                    { label => 'active_file_count', value => 'active_file_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'visited-file-count', set => {
                key_values => [ { name => 'visited_file_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'Visited File Count: %d',
                perfdatas => [
                    { label => 'visited_file_count', value => 'visited_file_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'page-view-count', set => {
                key_values => [ { name => 'page_view_count' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'Page View Count: %d',
                perfdatas => [
                    { label => 'page_view_count', value => 'page_view_count_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'id_absolute' },
                ],
            }
        },
        { label => 'last-activity', threshold => 0, set => {
                key_values => [ { name => 'last_activity_date' }, { name => 'url' }, { name => 'id' } ],
                output_template => 'Last Activity: %s',
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-url:s"      => { name => 'filter_url' },
                                    "filter-id:s"       => { name => 'filter_id' },
                                    "units:s"           => { name => 'units', default => '%' },
                                    "free"              => { name => 'free' },
                                    "active-only"       => { name => 'active_only' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sites} = {};

    my $results = $options{custom}->office_get_sharepoint_site_usage();

    foreach my $site (@{$results}) {
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
        if ($self->{option_results}->{active_only} && defined($site->{'Last Activity Date'}) && $site->{'Last Activity Date'} eq '') {
            $self->{output}->output_add(long_msg => "skipping  '" . $site->{'Site URL'} . "': no activity.", debug => 1);
            next;
        }
        
        $self->{sites}->{$site->{'Site Id'}}->{id} = $site->{'Site Id'};
        $self->{sites}->{$site->{'Site Id'}}->{url} = $site->{'Site URL'};
        $self->{sites}->{$site->{'Site Id'}}->{file_count} = $site->{'File Count'};
        $self->{sites}->{$site->{'Site Id'}}->{active_file_count} = $site->{'Active File Count'};
        $self->{sites}->{$site->{'Site Id'}}->{visited_file_count} = $site->{'Visited Page Count'};
        $self->{sites}->{$site->{'Site Id'}}->{page_view_count} = $site->{'Page View Count'};
        $self->{sites}->{$site->{'Site Id'}}->{storage_used} = $site->{'Storage Used (Byte)'};
        $self->{sites}->{$site->{'Site Id'}}->{storage_allocated} = $site->{'Storage Allocated (Byte)'};
        $self->{sites}->{$site->{'Site Id'}}->{last_activity_date} = $site->{'Last Activity Date'};
    }
    
    if (scalar(keys %{$self->{sites}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check sites usage (reporting period over the last 7 days).

(See link for details about metrics :
https://docs.microsoft.com/en-us/office365/admin/activity-reports/sharepoint-site-usage?view=o365-worldwide)

=over 8

=item B<--filter-*>

Filter sites.
Can be: 'url', 'id' (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'file-count', 'active-file-count',
'visited-file-count', 'page-view-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'file-count', 'active-file-count',
'visited-file-count', 'page-view-count'.

=item B<--active-only>

Filter only active entries ('Last Activity' set).

=back

=cut
