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

package apps::tomcat::jmx::mode::webappssessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'webapps', type => 1, cb_prefix_output => 'prefix_webapps_output', message_multiple => 'All webapp sessions are ok' },
    ];
    
    $self->{maps_counters}->{webapps} = [
        { label => 'sessions-active', set => {
                key_values => [ { name => 'activeSessions' }, { name => 'maxActiveSessions' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), 
                closure_custom_calc_extra_options => { label_ref => 'currentThreadCount', message => 'Current Threads' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'sessions-count', set => {
                key_values => [ { name => 'sessionCounter', diff => 1 }, { name => 'display' } ],
                output_template => 'Sessions Count : %s',
                perfdatas => [
                    { label => 'sessions_count', value => 'sessionCounter', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $use_th = 1;
    $use_th = 0 if ($self->{instance_mode}->{option_results}->{units} eq '%' && $self->{result_values}->{max} <= 0);
    
    my $value_perf = $self->{result_values}->{used};
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%' && $self->{result_values}->{max} > 0) {
        $total_options{total} = $self->{result_values}->{max};
        $total_options{cast_int} = 1;
    }

    my $label = $self->{label};
    $label =~ s/-/_/g;
    $self->{output}->perfdata_add(
        label => $label,
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $use_th == 1 ? $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options) : undef,
        critical => $use_th == 1 ? $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options) : undef,
        min => 0, max => $self->{result_values}->{max} > 0 ? $self->{result_values}->{max} : undef
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    # Cannot use percent without total
    return 'ok' if ($self->{result_values}->{max} <= 0 && $self->{instance_mode}->{option_results}->{units} eq '%');
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    if ($self->{result_values}->{max} > 0) {
        $msg = sprintf("Current Active Sessions  Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $self->{result_values}->{max},
                   $self->{result_values}->{used}, $self->{result_values}->{prct_used},
                   $self->{result_values}->{max} - $self->{result_values}->{used}, 100 - $self->{result_values}->{prct_used});
    } else {
        $msg = sprintf("Current Active Sessions : %s", $self->{result_values}->{used});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{max} = $options{new_datas}->{$self->{instance} . '_maxActiveSessions'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_activeSessions'};
    if ($self->{result_values}->{max} > 0) {
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{max};
    }

    return 0;
}

sub prefix_webapps_output {
    my ($self, %options) = @_;

    return "Webapp '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
        "units:s"       => { name => 'units', default => '%' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # can be path or context    
    # Tomcat: Catalina:context=/xxxxx,host=localhost,type=Manager
    # Jboss:  jboss.web:host=localhost,path=/invoker,type=Manager
    # maxActiveSessions = -1 (no limit)
    $self->{request} = [
         { mbean => "*:context=*,host=*,type=Manager", attributes => [ { name => 'activeSessions' }, { name => 'sessionCounter' }, { name => 'maxActiveSessions' } ] },
         { mbean => "*:path=*,host=*,type=Manager", attributes => [ { name => 'activeSessions' }, { name => 'sessionCounter' }, { name => 'maxActiveSessions' } ] },
    ];
    
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    $self->{webapps} = {};
    foreach my $key (keys %$result) {
        $key =~ /(?:[:,])host=(.*?)(?:,|$)/;
        my $webapps = $1;
        $key =~ /(?:[:,])(?:path|context)=(.*?)(?:,|$)/;
        $webapps .= '.' . $1;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $webapps !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $webapps . "': no matching filter.", debug => 1);
            next;
        }
     
        $self->{webapps}->{$webapps} = { 
            display => $webapps,
            %{$result->{$key}}
        };
    }
    
    $self->{cache_name} = "tomcat_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check webapps session usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='sessions-active'

=item B<--filter-name>

Filter webapps name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'sessions-count', 'sessions-active'.

=item B<--critical-*>

Threshold critical.
Can be: 'sessions-count', 'sessions-active'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'absolute').

=back

=cut
