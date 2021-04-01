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

package apps::pfsense::fauxapi::mode::rules;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_rule_output {
    my ($self, %options) = @_;
    
    return "Rule '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'rules', type => 1, cb_prefix_output => 'prefix_rule_output', message_multiple => 'All rules are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'rules.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'number of rules: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{rules} = [
        { label => 'traffic', nlabel => 'rule.traffic.bitspersecond', set => {
                key_values => [ { name => 'traffic', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(action => 'rule_get');

    $self->{global} = { total => 0 };
    $self->{rules} = {};
    if (defined($results->{data}->{rules})) {
        foreach (@{$results->{data}->{rules}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $_->{rule} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping rule '" . $_->{name} . "': no matching filter.", debug => 1);
                next;
            }

            $self->{rules}->{ $_->{number} } = {
                display => $_->{rule},
                traffic => $_->{bytes} * 8
            };

            $self->{global}->{total}++;
        }
    }

    $self->{cache_name} = 'pfsense_fauxapi_' . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check rules.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='traffic'

=item B<--filter-name>

Filter rule name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic' (b/s).

=back

=cut
