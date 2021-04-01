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

package storage::netapp::ontap::snmp::mode::temperature;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %mapping_temperature = (
    1 => 'no',
    2 => 'yes'
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_envOverTemperature = '.1.3.6.1.4.1.789.1.2.4.1';
    my $oid_nodeName = '.1.3.6.1.4.1.789.1.25.2.1.1';
    my $oid_nodeEnvOverTemperature = '.1.3.6.1.4.1.789.1.25.2.1.18';
    my $results = $self->{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_envOverTemperature },
            { oid => $oid_nodeName },
            { oid => $oid_nodeEnvOverTemperature },
        ],
        nothing_quit => 1
    );
    
    if (defined($results->{$oid_envOverTemperature}->{$oid_envOverTemperature . '.0'})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Hardware temperature is ok.');
        if ($mapping_temperature{$results->{$oid_envOverTemperature}->{$oid_envOverTemperature . '.0'}} eq 'yes') {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => 'Hardware temperature is over temperature range.');
        }
    } else {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Hardware temperature are ok on all nodes');
        foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$results->{$oid_nodeEnvOverTemperature}})) {
            $oid =~ /^$oid_nodeEnvOverTemperature\.(.*)$/;
            my $instance = $1;
            my $name = $results->{$oid_nodeName}->{$oid_nodeName . '.' . $instance};
            my $temp = $results->{$oid_nodeEnvOverTemperature}->{$oid};
            $self->{output}->output_add(long_msg => sprintf("hardware temperature on node '%s' is over range: '%s'", 
                                                            $name, $mapping_temperature{$temp}));
            if ($mapping_temperature{$temp} eq 'yes') {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Hardware temperature is over temperature range on node '%s'", $name));
            }
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check if hardware is currently operating outside of its recommended temperature range.

=over 8

=back

=cut
    
