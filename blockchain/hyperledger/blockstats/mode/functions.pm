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

package blockchain::hyperledger::blockstats::mode::functions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

# [{"id":"lscc","version":"1.4.2","contractPath":"","nbCalls":1,"functions":[{"name":"deploy","nbCalls":1}]},
# {"id":"mycc","version":"1.0","contractPath":"","nbCalls":1,"functions":[{"name":"invoke","nbCalls":1}]}]

sub custom_output {
    my ($self, %options) = @_;
    my $msg = "Chaincode alias is '" .     $self->{result_values}->{chaincode} . "'";

    return $msg;
}

sub custom_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{chaincode} = $options{new_datas}->{$self->{instance} . '_chaincode_alias'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'functions', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All function metrics are ok' }
    ];

    $self->{maps_counters}->{functions} = [
        # { label => 'chaincode', nlabel => 'chaincode.alias', threshold => 0, set => {
        #         key_values => [ { name => 'chaincode' } ],
        #         closure_custom_calc => $self->can('custom_calc'),
        #         closure_custom_output => $self->can('custom_output'),
        #         closure_custom_perfdata => sub { return 0; },
        #         closure_custom_threshold_check => \&catalog_status_threshold,
        #     }
        # },
        { label => 'chaincode', nlabel => 'chaincode.name', set => {
                key_values => [ { name => 'chaincode' } ],
                output_template => 'Chaincode: %s',
                perfdatas => [
                    { label => 'chaincode', value => 'chaincode_absolute', template => '%s'},
                ],
            }
        },
        { label => 'function_calls', nlabel => 'function.calls.count', set => {
                key_values => [ { name => 'function_calls' } ],
                output_template => 'Function called: %d time(s)',
                perfdatas => [
                    { label => 'function_calls', value => 'function_calls_absolute', template => '%d'},
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Function '" . $options{instance_value}->{display} . "' ";
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

    $self->{functions} = {};

    my $results = $options{custom}->request_api(url_path => '/statistics/contracts');
    
    use Data::Dumper;
    # print Dumper($results);
     
    foreach my $contract (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $contract->{id} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $contract->{id} . "': no matching filter name.", debug => 1);
            next;
        }

        foreach my $function (@{$contract->{functions}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $function->{name} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $function->{name} . "': no matching filter name.", debug => 1);
                next;
            }
            print Dumper($contract->{id});
            $self->{functions}->{$function->{name}}->{display} = $function->{name};
            $self->{functions}->{$function->{name}}->{chaincode} = $contract->{id};
            $self->{functions}->{$function->{name}}->{function_calls} = $function->{nbCalls};
        }

    }
    
    if (scalar(keys %{$self->{functions}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No function found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check blockchain statistics

=cut
