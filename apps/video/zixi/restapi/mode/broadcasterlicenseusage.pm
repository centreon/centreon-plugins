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

package apps::video::zixi::restapi::mode::broadcasterlicenseusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $info = $self->{result_values}->{info} eq '' ? '-' : $self->{result_values}->{info};
    my $error = $self->{result_values}->{error} eq '' ? '-' : $self->{result_values}->{error};
    my $msg = 'information : ' . $info . ' [error: ' . $error . ']';

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{info} = $options{new_datas}->{$self->{instance} . '_info'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{error} = $options{new_datas}->{$self->{instance} . '_error'};
    
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{result_values}->{total} =~ /[0-9]/ && $self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label,
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total} =~ /[0-9]/ ? $self->{result_values}->{total} : undef
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{result_values}->{total} =~ /[0-9]/ && $self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Total: %s Used: %s (%s) Free: %s (%s)",
                   $self->{result_values}->{total},
                   $self->{result_values}->{used}, 
                   defined($self->{result_values}->{prct_used}) ? sprintf("%.2f%%", $self->{result_values}->{prct_used}) : '-',
                   defined($self->{result_values}->{free}) ? $self->{result_values}->{free} : '-', 
                   defined($self->{result_values}->{prct_free}) ? sprintf("%.2f%%", $self->{result_values}->{prct_free}) : '-');
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    return -10 if ($options{new_datas}->{$self->{instance} . '_info'} =~ /disabled/i ||
        $options{new_datas}->{$self->{instance} . '_used'} eq '' ||
        ($options{new_datas}->{$self->{instance} . '_used'} =~ /^0$/ && $options{new_datas}->{$self->{instance} . '_limit'} =~ /^0$/));
    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_limit'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    
    # Can be 'unlimited'
    if ($self->{result_values}->{total} =~ /[0-9]/) {
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
        $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
        $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
        if ($self->{result_values}->{free} < 0) {
            $self->{result_values}->{free} = 0;
            $self->{result_values}->{prct_free} = 0;
        }
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'license', type => 1, cb_prefix_output => 'prefix_license_output', message_multiple => 'All licenses are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{license} = [
         { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'info' }, { name => 'name' }, { name => 'error' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'limit' }, { name => 'name' }, { name => 'info' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), 
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'days', set => {
                key_values => [ { name => 'days' } ],
                output_template => '%d days remaining before expiration',
                closure_custom_perfdata => sub { return 0; },
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
                                  "warning-status:s"    => { name => 'warning_status' },
                                  "critical-status:s"   => { name => 'critical_status' },
                                  "units:s"             => { name => 'units', default => '%' },
                                  "free"                => { name => 'free' },
                                });
    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Date::Parse',
                                           error_msg => "Cannot load module 'Date::Parse'.");
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_license_output {
    my ($self, %options) = @_;
    
    return "License '" . $options{instance_value}->{name} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
                                                           
    $self->{license} = {};
    my $result = $options{custom}->get(path => '/licensing_info');

    my $current_time = time();
    foreach my $entry (@{$result->{lics}}) {        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $entry->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $entry->{name} . "': no matching filter.", debug => 1);
            next;
        }
        
        # Format 09-dec-2017. Can be also 'permanent' (so dont care)
        my $days_remaining;
        if ($entry->{exp} =~ /\d+-\S+-\d+/) {
            my $create_time = Date::Parse::str2time($entry->{exp});
            $days_remaining = ($create_time - $current_time) / 86400;
        }
        
        $self->{license}->{$entry->{name}} = { %{$entry}, days => $days_remaining };
    }
    
    if (scalar(keys %{$self->{license}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No license found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check license usage.

=over 8

=item B<--filter-source>

Filter source (can be a regexp).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'days'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'days'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'absolute').

=item B<--free>

Thresholds are on free license left.

=item B<--warning-status>

Set warning threshold for status (Default: -)
Can used special variables like: %{name}, %{error}, %{info}.

=item B<--critical-status>

Set critical threshold for status (Default: -).
Can used special variables like: %{name}, %{error}, %{info}.

=back

=cut
