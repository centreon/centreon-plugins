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

package network::bluecoat::snmp::mode::clientrequests;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'hits', set => {
                key_values => [ { name => 'client_http_requests', diff => 1 }, { name => 'client_http_hits', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'hits' },
                output_template => 'Hits = %.2f %%', output_use => 'hits_prct',
                perfdatas => [
                    { label => 'hits', value => 'hits_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'partial-hits', set => {
                key_values => [ { name => 'client_http_requests', diff => 1 }, { name => 'client_http_partial_hits', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'partial_hits' },
                output_template => 'Partial Hits = %.2f %%', output_use => 'partial_hits_prct',
                perfdatas => [
                    { label => 'partial_hits', value => 'partial_hits_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'misses', set => {
                key_values => [ { name => 'client_http_requests', diff => 1 }, { name => 'client_http_misses', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'misses' },
                output_template => 'Misses = %.2f %%', output_use => 'misses_prct',
                perfdatas => [
                    { label => 'misses', value => 'misses_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'errors', set => {
                key_values => [ { name => 'client_http_requests', diff => 1 }, { name => 'client_http_errors', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'), closure_custom_calc_extra_options => { label_ref => 'errors' },
                output_template => 'Errors = %.2f %%', output_use => 'errors_prct',
                perfdatas => [
                    { label => 'errors', value => 'errors_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;
    
    return "Client Requests: ";
}

sub custom_data_calc {
    my ($self, %options) = @_;
    
    my $label = $options{extra_options}->{label_ref};
    my $delta_value = $options{new_datas}->{$self->{instance} . '_client_http_' . $label} - $options{old_datas}->{$self->{instance} . '_client_http_' . $label};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_client_http_requests'} - $options{old_datas}->{$self->{instance} . '_client_http_requests'};

    $self->{result_values}->{$label . '_prct'} = 0;
    if ($delta_total > 0) {
        $self->{result_values}->{$label . '_prct'} = $delta_value * 100 / $delta_total;
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    my $result = $options{snmp}->get_leef(oids => ['.1.3.6.1.4.1.3417.2.11.3.1.1.1.0', 
                                                   '.1.3.6.1.4.1.3417.2.11.3.1.1.2.0',
                                                   '.1.3.6.1.4.1.3417.2.11.3.1.1.3.0',
                                                   '.1.3.6.1.4.1.3417.2.11.3.1.1.4.0',
                                                   '.1.3.6.1.4.1.3417.2.11.3.1.1.5.0'], nothing_quit => 1);

    $self->{cache_name} = "bluecoat_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    $self->{global} = { client_http_requests => $result->{'.1.3.6.1.4.1.3417.2.11.3.1.1.1.0'},
                        client_http_hits => $result->{'.1.3.6.1.4.1.3417.2.11.3.1.1.2.0'},
                        client_http_partial_hits => $result->{'.1.3.6.1.4.1.3417.2.11.3.1.1.3.0'},
                        client_http_misses => $result->{'.1.3.6.1.4.1.3417.2.11.3.1.1.4.0'}, 
                        client_http_errors => $result->{'.1.3.6.1.4.1.3417.2.11.3.1.1.5.0'} };
}

1;

__END__

=head1 MODE

Check http client requests (in percent by type: hit, partial, misses, errors)

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='errors'

=item B<--warning-*>

Threshold warning.
Can be: errors (%), hits (%), partial-hits (%), misses (%).

=item B<--critical-*>

Threshold critical.
Can be: errors (%), hits (%), partial-hits (%), misses (%).

=back

=cut
