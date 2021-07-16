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

package blockchain::hyperledger::blockstats::mode::endorsers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'endorsers', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All endorser metrics are ok' }
    ];

    $self->{maps_counters}->{endorsers} = [
        { label => 'endorsments', nlabel => 'endorser.endorsments.count', set => {
                key_values => [ { name => 'endorsments' }, { name => 'display' } ],
                output_template => 'Endorsments: %d',
                perfdatas => [
                    { label => 'endorsments', value => 'endorsments_absolute', template => '%d',
                      min => 0, label_extra_instance => 1, instance_use => 'display_absolute' },
                ],
            }
        },
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Endorser '" . $options{instance_value}->{display} . "' ";
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

    $self->{endorsers} = {};

    my $results = $options{custom}->request_api(url_path => '/statistics/endorsers');

    foreach my $endorser (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $endorser->{mspid} !~ /$self->{option_results}->{filter_name}/) {
            $endorser->{output}->output_add(long_msg => "skipping '" . $endorser->{mspid} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{endorsers}->{$endorser->{mspid}}->{display} = $endorser->{mspid};
        $self->{endorsers}->{$endorser->{mspid}}->{endorsments} = $endorser->{nbEndorsments};
    }
    
    if (scalar(keys %{$self->{endorsers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No endorser found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check blockchain statistics

=cut
