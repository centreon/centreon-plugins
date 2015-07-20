# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets 
# the needs in IT infrastructure and application monitoring for 
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::cmdlistdatacenters;

use strict;
use warnings;
use centreon::vmware::common;

sub new {
    my $class = shift;
    my $self  = {};
    $self->{logger} = shift;
    $self->{commandName} = 'listdatacenters';
    
    bless $self, $class;
    return $self;
}

sub getCommandName {
    my $self = shift;
    return $self->{commandName};
}

sub checkArgs {
    my ($self, %options) = @_;

    if (defined($options{arguments}->{datacenter}) && $options{arguments}->{datacenter} eq "") {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Argument error: datacenter cannot be null");
        return 1;
    }
    return 0;
}

sub initArgs {
     my ($self, %options) = @_;
    
    foreach (keys %{$options{arguments}}) {
        $self->{$_} = $options{arguments}->{$_};
    }
    $self->{manager} = centreon::vmware::common::init_response();
    $self->{manager}->{output}->{plugin} = $options{arguments}->{identity};
}

sub set_connector {
    my ($self, %options) = @_;
    
    $self->{connector} = $options{connector};
}

sub run {
    my $self = shift;

    my %filters = ();
    my $multiple = 0;

    if (defined($self->{datacenter}) && !defined($self->{filter})) {
        $filters{name} = qr/^\Q$self->{datacenter}\E$/;
    } elsif (!defined($self->{datacenter})) {
        $filters{name} = qr/.*/;
    } else {
        $filters{name} = qr/$self->{datacenter}/;
    }
    my @properties = ('name');

    my $result = centreon::vmware::common::search_entities(command => $self, view_type => 'Datacenter', properties => \@properties, filter => \%filters);
    return if (!defined($result));

    if (!defined($self->{disco_show})) {
        $self->{manager}->{output}->output_add(severity => 'OK',
                                               short_msg => 'List datacenter(s):');
    }
    foreach my $datacenter (@$result) {
        if (defined($self->{disco_show})) {
            $self->{manager}->{output}->add_disco_entry(name => $datacenter->name);
        } else {
            $self->{manager}->{output}->output_add(long_msg => sprintf("  %s", 
                                                                        $datacenter->name));
        }
    }
    
    if (defined($self->{disco_show})) {
        my $stdout;
        {
            local *STDOUT;
            $self->{manager}->{output}->{option_results}->{output_xml} = 1;
            open STDOUT, '>', \$stdout;
            $self->{manager}->{output}->display_disco_show();
            delete $self->{manager}->{output}->{option_results}->{output_xml};
            $self->{manager}->{output}->output_add(severity => 'OK',
                                                   short_msg => $stdout);
        }
    }
}

1;
