#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package blockchain::hyperledger::blockstats::mode::contracts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

# [{"id":"lscc","version":"1.4.2","contractPath":"","nbCalls":1,"functions":[{"name":"deploy","nbCalls":1}]},
# {"id":"mycc","version":"1.0","contractPath":"","nbCalls":1,"functions":[{"name":"invoke","nbCalls":1}]}]

# sub custom_output {
#     my ($self, %options) = @_;
#     my $msg = "Chaincode version is '" .     $self->{result_values}->{status} . "'";

#     return $msg;
# }

# sub custom_calc {
#     my ($self, %options) = @_;

#     $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_chaincode_version'};
#     return 0;
# }

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'contracts', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All contract metrics are ok' }
    ];

    $self->{maps_counters}->{contracts} = [
        # { label => 'version', threshold => 0, set => {
        #         key_values => [ { name => 'chaincode_version' } ],
        #         closure_custom_calc => $self->can('custom_calc'),
        #         closure_custom_output => $self->can('custom_output'),
        #         closure_custom_perfdata => sub { return 0; },
        #         closure_custom_threshold_check => \&catalog_status_threshold,
        #     }
        # },
        { label => 'version', nlabel => 'chaincode.version', set => {
                key_values => [ { name => 'version' }, { name => 'display' } ],
                output_template => 'Version: %s',
                perfdatas => [
                    { label => 'version', value => 'version_absolute', template => '%s',
                      label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
        { label => 'path', nlabel => 'chaincode.path', set => {
                key_values => [ { name => 'path' } ],
                output_template => 'Path: %s',
                perfdatas => [
                    { label => 'path', value => 'path_absolute', template => '%s'},
                ],
            }
        },
        { label => 'calls', nlabel => 'chaincode.calls.count', set => {
                key_values => [ { name => 'calls' } ],
                output_template => 'Called: %d time(s)',
                perfdatas => [
                    { label => 'calls', value => 'calls_absolute', template => '%d'},
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Contract '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{contracts} = {};

    my $results = $options{custom}->request_api(url_path => '/statistics/contracts');
    
    use Data::Dumper;
    print Dumper($results);

    foreach my $contract (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $contract->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $contract->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{contracts}->{$contract->{id}}->{display} = $contract->{id};
        $self->{contracts}->{$contract->{id}}->{version} = $contract->{version};
        $self->{contracts}->{$contract->{id}}->{calls} = $contract->{nbCalls};

    }
    
    if (scalar(keys %{$self->{contracts}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No contract found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check blockchain statistics

=cut
