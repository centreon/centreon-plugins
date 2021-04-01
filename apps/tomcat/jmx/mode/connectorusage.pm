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

package apps::tomcat::jmx::mode::connectorusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tomcatconnector', type => 1, cb_prefix_output => 'prefix_connector_output', message_multiple => 'All connectors are ok' },
    ];
    
    $self->{maps_counters}->{tomcatconnector} = [
        { label => 'threads-count', set => {
                key_values => [ { name => 'currentThreadCount' }, { name => 'maxThreads' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), 
                closure_custom_calc_extra_options => { label_ref => 'currentThreadCount', message => 'Current Threads' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'threads-busy', set => {
                key_values => [ { name => 'currentThreadsBusy' }, { name => 'maxThreads' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), 
                closure_custom_calc_extra_options => { label_ref => 'currentThreadsBusy', message => 'Current Busy Threads' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'request-count', set => {
                key_values => [ { name => 'requestCount', diff => 1 }, { name => 'display' } ],
                output_template => 'Request Count : %s',
                perfdatas => [
                    { label => 'request_count', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'bytesReceived', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic In : %s %s/s',
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'bytesSent', per_second => 1 }, { name => 'display' } ],
                output_change_bytes => 2,
                output_template => 'Traffic Out : %s %s/s',
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f',
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        }
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
        $msg = sprintf("%s Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $self->{result_values}->{message}, $self->{result_values}->{max},
                   $self->{result_values}->{used}, $self->{result_values}->{prct_used},
                   $self->{result_values}->{max} - $self->{result_values}->{used}, 100 - $self->{result_values}->{prct_used});
    } else {
        $msg = sprintf("%s : %s", $self->{result_values}->{message}, $self->{result_values}->{used});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{message} = $options{extra_options}->{message};
    $self->{result_values}->{max} = $options{new_datas}->{$self->{instance} . '_maxThreads'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref}};
    if ($self->{result_values}->{max} > 0) {
        $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{max};
    }

    return 0;
}

sub prefix_connector_output {
    my ($self, %options) = @_;

    return "Connector '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
        'units:s'       => { name => 'units', default => '%' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # Tomcat: Catalina
    # Jboss: jboss.web
    $self->{request} = [
         { mbean => "*:name=*,type=ThreadPool", attributes => [ { name => 'currentThreadCount' }, { name => 'currentThreadsBusy' }, { name => 'maxThreads' } ] },
         { mbean => "*:name=*,type=GlobalRequestProcessor", attributes => [ { name => 'bytesReceived' }, { name => 'bytesSent' }, { name => 'requestCount' } ] }
    ];
    
    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 1);

    $self->{tomcatconnector} = {};
    foreach my $key (keys %$result) {         
        $key =~ /name=(.*?),type=(.*)/;
        my ($connector, $type) = ($1, $2); # double quote nivo du name si existe
        $connector =~ s/^"(.*)"$/$1/g;
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $connector !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $connector . "': no matching filter.", debug => 1);
            next;
        }
     
        $result->{$key}->{bytesSent} *= 8 if (defined($result->{$key}->{bytesSent}));
        $result->{$key}->{bytesReceived} *= 8 if (defined($result->{$key}->{bytesReceived}));
        $self->{tomcatconnector}->{$connector} = { display => $connector }
            if (!defined($self->{tomcatconnector}->{$connector}));
        $self->{tomcatconnector}->{$connector} = { %{$self->{tomcatconnector}->{$connector}}, %{$result->{$key}} };
    }
    
    $self->{cache_name} = "tomcat_" . $self->{mode} . '_' . md5_hex($options{custom}->get_connection_info()) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check connector usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='threads-busy'

=item B<--filter-name>

Filter connector name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'threads-count', 'threads-busy', 'request-count', 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'threads-count', 'threads-busy', 'request-count', 'traffic-in', 'traffic-out'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'absolute').

=back

=cut
