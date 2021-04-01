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

package storage::hp::eva::cli::mode::components::psu;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    
    $self->{ssu_commands}->{'ls diskshelf full xml'} = 1;
    $self->{ssu_commands}->{'ls controller full xml'} = 1;
}

sub psu_ctrl {
    my ($self) = @_;
    
    # <object>
    #    <objecttype>controller</objecttype>
    #    <objectname>\Hardware\Rack 1\Controller Enclosure 7\Controller B</objectname>
    #     <powersources>
    #        <powerlevel>12.32</powerlevel>
    #        <source>
    #            <type>powersupply0</type>
    #            <state>good</state>
    #        </source>
    foreach my $object (@{$self->{xml_result}->{object}}) {
        next if ($object->{objecttype} ne 'controller');
        
        $object->{objectname} =~ s/\\/\//g;
        foreach my $result (@{$object->{powersources}->{source}}) {
            next if ($result->{type} eq '');
            my $instance = $object->{objectname} . '/' . $result->{type};

            next if ($self->check_filter(section => 'psu', instance => $instance));
            next if ($result->{state} =~ /notinstalled/i &&
                     $self->absent_problem(section => 'psu', instance => $instance));

            $self->{components}->{psu}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s]",
                                        $instance, $result->{state}, $instance, 
                                        ));
            
            my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{state});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' status is '%s'", $instance, $result->{state}));
            }
        }
    }
}

sub psu_diskshelf {
    my ($self) = @_;
        
    # <object>
    #    <objecttype>diskshelf</objecttype>
    #    <objectname>\Hardware\Rack 1\Disk Enclosure 3</objectname>
    #    <powersupplies>
    #        <powersupply>
    #          <name>powersupply1</name>
    #          <operationalstate>good</operationalstate>
    #          <failurepredicted>No</failurepredicted>
    #          <vdcoutputs>
    #            <vdcoutput>
    #              <type>vdc5output</type>
    #              <voltage>5.5</voltage>
    #              <current>6.7</current>
    #            </vdcoutput>
    #            <vdcoutput>
    #              <type>vdc12output</type>
    #              <voltage>12.5</voltage>
    #              <current>4.1</current>
    #            </vdcoutput>
    #          </vdcoutputs>
    foreach my $object (@{$self->{xml_result}->{object}}) {
        next if ($object->{objecttype} ne 'diskshelf');
        
        $object->{objectname} =~ s/\\/\//g;
        foreach my $result (@{$object->{powersupplies}->{powersupply}}) {
            my $instance = $object->{objectname} . '/' . $result->{name};
            
            next if ($self->check_filter(section => 'psu', instance => $instance));
            next if ($result->{operationalstate} =~ /notinstalled/i &&
                     $self->absent_problem(section => 'psu', instance => $instance));

            $self->{components}->{psu}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("power suuply '%s' status is '%s' [instance = %s]",
                                        $instance, $result->{operationalstate}, $instance, 
                                        ));
            
            my $exit = $self->get_severity(label => 'default', section => 'psu', value => $result->{operationalstate});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Power supply '%s' status is '%s'", $instance, $result->{operationalstate}));
            }
            
            foreach my $voltage (@{$result->{vdcoutputs}->{vdcoutput}}) {
                next if ($voltage->{current} !~ /[0-9]/);
                my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'psu', instance => $instance . '/' . $voltage->{type}, value => $voltage->{current});        
                if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit2,
                                                short_msg => sprintf("Power supply '%s' is %s V", $instance, $voltage->{current}));
                }
                $self->{output}->perfdata_add(
                    label => 'voltage', unit => 'V',
                    nlabel => 'hardware.powersupply.diskshelf.voltage.volt',
                    instances => [$instance, $voltage->{type}],
                    value => $voltage->{current},
                    warning => $warn,
                    critical => $crit,
                );
            }
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    psu_ctrl($self);
    psu_diskshelf($self);
}

1;
