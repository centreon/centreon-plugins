#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package os::windows::custom::openwsman;

use strict;
use warnings;
use JSON::XS;
use base qw(centreon::plugins::script_wsman);

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
          
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'OpenWSMAN OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{custommode_name} = $options{custommode_name};

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{custommode_name}) {
            if (ref($options{default}->{$_}) eq 'ARRAY') {
                for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                    foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                        if (!defined($self->{option_results}->{$opt}[$i])) {
                            $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                        }
                    }
                }
            }
            
            if (ref($options{default}->{$_}) eq 'HASH') {
                foreach my $opt (keys %{$options{default}->{$_}}) {
                    if (!defined($self->{option_results}->{$opt})) {
                        $self->{option_results}->{$opt} = $options{default}->{$_}->{$opt};
                    }
                }
            }
        }
    }  
}

sub wmi_request {
    my ($self, %options) = @_;
    
    
    my $array_result;
    eval {
        $array_result = $options{wsman}->request(
            uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
            wql_filter => $options{wql},
            result_type => 'array'
        );
    }
    my $raw_results = JSON::XS->new->utf8->encode(\@array_results);

    return $raw_result;
}