#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::plugins::output;

use centreon::plugins::misc;
use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;
    # $options->{options} = options object
    if (!defined($options{options})) {
        print "Class Output: Need to specify 'options' argument to load.\n";
        exit 3;
    }

    $options{options}->add_options(arguments =>
                                {
                                  "explode-perfdata-max:s@" => { name => 'explode_perfdata_max' },
                                  "range-perfdata:s"        => { name => 'range_perfdata' },
                                  "filter-perfdata:s"       => { name => 'filter_perfdata' },
                                  "change-perfdata:s@"      => { name => 'change_perfdata' },
                                  "filter-uom:s"            => { name => 'filter_uom' },
                                  "verbose"                 => { name => 'verbose' },
                                  "debug"                   => { name => 'debug' },
                                  "opt-exit:s"              => { name => 'opt_exit', default => 'unknown' },
                                  "output-xml"              => { name => 'output_xml' },
                                  "output-json"             => { name => 'output_json' },
                                  "disco-format"            => { name => 'disco_format' },
                                  "disco-show"              => { name => 'disco_show' },
                                });
    %{$self->{option_results}} = ();

    $self->{option_msg} = [];
    
    $self->{is_output_xml} = 0;
    $self->{is_output_json} = 0;
    $self->{errors} = {OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3, PENDING => 4};
    $self->{errors_num} = {0 => 'OK', 1 => 'WARNING', 2 => 'CRITICAL', 3 => 'UNKNOWN', 4 => 'PENDING'};
    $self->{myerrors} = {0 => "OK", 1 => "WARNING", 3 => "UNKNOWN", 7 => "CRITICAL"};
    $self->{myerrors_mask} = {CRITICAL => 7, WARNING => 1, UNKNOWN => 3, OK => 0};
    $self->{global_short_concat_outputs} = {OK => undef, WARNING => undef, CRITICAL => undef, UNKNOWN => undef, UNQUALIFIED_YET => undef};
    $self->{global_short_outputs} = {OK => [], WARNING => [], CRITICAL => [], UNKNOWN => [], UNQUALIFIED_YET => []};
    $self->{global_long_output} = [];
    $self->{perfdatas} = [];
    $self->{explode_perfdatas} = {};
    $self->{change_perfdata} = {};
    $self->{explode_perfdata_total} = 0;
    $self->{range_perfdata} = 0;
    $self->{global_status} = 0;
    $self->{encode_utf8_import} = 0;
    $self->{perlqq} = 0;

    $self->{disco_elements} = [];
    $self->{disco_entries} = [];

    $self->{plugin} = '';
    $self->{mode} = '';

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    # $options{option_results} = ref to options result

    %{$self->{option_results}} = %{$options{option_results}};
    $self->{option_results}->{opt_exit} = lc($self->{option_results}->{opt_exit});
    if (!$self->is_litteral_status(status => $self->{option_results}->{opt_exit})) {
        $self->add_option_msg(short_msg => "Unknown value '" . $self->{option_results}->{opt_exit}  . "' for --opt-exit.");
        $self->option_exit(exit_litteral => 'unknown');
    }
    # Go in XML Mode
    if ($self->is_disco_show() || $self->is_disco_format()) {
        # By Default XML
        if (!defined($self->{option_results}->{output_json})) {
            $self->{option_results}->{output_xml} = 1;
        }
    }
    
    if (defined($self->{option_results}->{range_perfdata})) {
        $self->{range_perfdata} = $self->{option_results}->{range_perfdata};
        $self->{range_perfdata} = 1 if ($self->{range_perfdata} eq '');
        if ($self->{range_perfdata} !~ /^[012]$/) {
            $self->add_option_msg(short_msg => "Wrong range-perfdata option '" . $self->{range_perfdata} . "'");
            $self->option_exit();
        }
    }
    
    if (defined($self->{option_results}->{explode_perfdata_max})) {
        if (${$self->{option_results}->{explode_perfdata_max}}[0] eq '') {
            $self->{explode_perfdata_total} = 2;
        } else {
            $self->{explode_perfdata_total} = 1;
            foreach (@{$self->{option_results}->{explode_perfdata_max}}) {
                my ($perf_match, $perf_result) = split /,/;
                if (!defined($perf_result)) {
                    $self->add_option_msg(short_msg => "Wrong explode-perfdata-max option '" . $_ . "' (syntax: match,value)");
                    $self->option_exit();
                }
                $self->{explode_perfdatas}->{$perf_match} = $perf_result;
            }
        }
    }
    
    if (defined($self->{option_results}->{change_perfdata})) {
        foreach (@{$self->{option_results}->{change_perfdata}}) {
            if (! /^(.+?),(.+)$/) {
                $self->add_option_msg(short_msg => "Wrong change-perfdata option '" . $_ . "' (syntax: match,substitute)");
                $self->option_exit();
            }
            $self->{change_perfdata}->{$1} = $2;
        }
    }
}

sub add_option_msg {
    my ($self, %options) = @_;
    # $options{short_msg} = string msg
    # $options{long_msg} = string msg
    $options{severity} = 'UNQUALIFIED_YET';
    
    $self->output_add(%options);
}

sub set_status {
    my ($self, %options) = @_;
    # $options{exit_litteral} = string litteral exit

    # Nothing to do for 'UNQUALIFIED_YET'
    if (!$self->{myerrors_mask}->{uc($options{exit_litteral})}) {
        return ;
    }
    $self->{global_status} |= $self->{myerrors_mask}->{uc($options{exit_litteral})};
}

sub output_add {
    my ($self, %params) = @_;
    my %args = (
                severity => 'OK',
                separator => ' - ',
                debug => 0,
                short_msg => undef,
                long_msg => undef
                );
    my $options = {%args, %params};
    
    if (defined($options->{short_msg})) {
        chomp $options->{short_msg};
        if (defined($self->{global_short_concat_outputs}->{uc($options->{severity})})) {
            $self->{global_short_concat_outputs}->{uc($options->{severity})} .= $options->{separator} . $options->{short_msg};
        } else {
            $self->{global_short_concat_outputs}->{uc($options->{severity})} = $options->{short_msg};
        }
        
        push @{$self->{global_short_outputs}->{uc($options->{severity})}}, $options->{short_msg};
        $self->set_status(exit_litteral => $options->{severity});
    }
    if (defined($options->{long_msg}) && 
        ($options->{debug} == 0 || defined($self->{option_results}->{debug}))) {
        chomp $options->{long_msg};
        push @{$self->{global_long_output}}, $options->{long_msg};
    }
}

sub perfdata_add {
    my ($self, %options) = @_;
    my $perfdata = {label => '', value => '', unit => '', warning => '', critical => '', min => '', max => ''}; 
    foreach (keys %options) {
        next if (!defined($options{$_}));
        $perfdata->{$_} = $options{$_};
    }
    $perfdata->{label} =~ s/'/''/g;
    push @{$self->{perfdatas}}, $perfdata;
}

sub change_perfdatas {
    my ($self, %options) = @_;
    
    if ($self->{option_results}->{change_perfdata}) {
        foreach (@{$self->{perfdatas}}) {
            foreach my $filter (keys %{$self->{change_perfdata}}) {
                if ($_->{label} =~ /$filter/) {
                    eval "\$_->{label} =~ s{$filter}{$self->{change_perfdata}->{$filter}}";
                    last;
                }
            }
        }
    }
    
    return if ($self->{explode_perfdata_total} == 0);
    foreach (@{$self->{perfdatas}}) {
        next if ($_->{max} eq '');
        if ($self->{explode_perfdata_total} == 2) {
            $self->perfdata_add(label => $_->{label} . '_max', value => $_->{max});
            next;
        }
        foreach my $regexp (keys %{$self->{explode_perfdatas}}) {
            if ($_->{label} =~ /$regexp/) {
                $self->perfdata_add(label => $self->{explode_perfdatas}->{$regexp}, value => $_->{max});
                last;
            }
        }
    }
}

sub range_perfdata {
    my ($self, %options) = @_;
    
    return if ($self->{range_perfdata} == 0);
    if ($self->{range_perfdata} == 1) {
        for (my $i = 0; $i < scalar(@{$options{ranges}}); $i++) {
            ${${$options{ranges}}[$i]} =~ s/^(@?)-?[0\.]+:/$1/;
        }
    } else {
        for (my $i = 0; $i < scalar(@{$options{ranges}}); $i++) {
            ${${$options{ranges}}[$i]} = '';
        }
    }
}

sub output_json {
    my ($self, %options) = @_;
    my $force_ignore_perfdata = (defined($options{force_ignore_perfdata}) && $options{force_ignore_perfdata} == 1) ? 1 : 0;
    my $force_long_output = (defined($options{force_long_output}) && $options{force_long_output} == 1) ? 1 : 0;
    my $json_content = {plugin => {
                                   name => $self->{plugin},
                                   mode => $self->{mode},
                                   exit => $options{exit_litteral},
                                   outputs => [],
                                   perfdatas => []
                                  }
                        };    

    foreach my $code_litteral (keys %{$self->{global_short_outputs}}) {
        foreach (@{$self->{global_short_outputs}->{$code_litteral}}) {
            my ($child_output, $child_type, $child_msg, $child_exit);
            my $lcode_litteral = ($code_litteral eq 'UNQUALIFIED_YET' ? uc($options{exit_litteral}) : $code_litteral);

            push @{$json_content->{plugin}->{outputs}}, {
                                                           type => 1,
                                                           msg => ($options{nolabel} == 0 ? ($lcode_litteral . ': ') : '') . $_,
                                                           exit => $lcode_litteral
                                                        };
        }
    }

    if (defined($self->{option_results}->{verbose}) || $force_long_output == 1) {
        foreach (@{$self->{global_long_output}}) {
            push @{$json_content->{plugin}->{outputs}}, {
                                                           type => 2,
                                                           msg => $_,
                                                        };
        }
    }

    if ($options{force_ignore_perfdata} == 0) {
        $self->change_perfdatas();
        foreach my $perf (@{$self->{perfdatas}}) {
            next if (defined($self->{option_results}->{filter_perfdata}) &&
                     $perf->{label} !~ /$self->{option_results}->{filter_perfdata}/);
            $self->range_perfdata(ranges => [\$perf->{warning}, \$perf->{critical}]);
            
            my %values = ();
            foreach my $key (keys %$perf) {
                $perf->{$key} = '' if (defined($self->{option_results}->{filter_uom}) && $key eq 'unit' &&
                    $perf->{$key} !~ /$self->{option_results}->{filter_uom}/);
                $values{$key} = $perf->{$key};
            }
            
            push @{$json_content->{plugin}->{perfdatas}}, {
                                                           %values
                                                        };
        }
    }

    print $self->{json_output}->encode($json_content);
}

sub output_xml {
    my ($self, %options) = @_;
    my $force_ignore_perfdata = (defined($options{force_ignore_perfdata}) && $options{force_ignore_perfdata} == 1) ? 1 : 0;
    my $force_long_output = (defined($options{force_long_output}) && $options{force_long_output} == 1) ? 1 : 0;
    my ($child_plugin_name, $child_plugin_mode, $child_plugin_exit, $child_plugin_output, $child_plugin_perfdata); 

    my $root = $self->{xml_output}->createElement('plugin');
    $self->{xml_output}->setDocumentElement($root);

    $child_plugin_name = $self->{xml_output}->createElement("name");
    $child_plugin_name->appendText($self->{plugin});

    $child_plugin_mode = $self->{xml_output}->createElement("mode");
    $child_plugin_mode->appendText($self->{mode});

    $child_plugin_exit = $self->{xml_output}->createElement("exit");
    $child_plugin_exit->appendText($options{exit_litteral});

    $child_plugin_output = $self->{xml_output}->createElement("outputs");
    $child_plugin_perfdata = $self->{xml_output}->createElement("perfdatas");

    $root->addChild($child_plugin_name);
    $root->addChild($child_plugin_mode);
    $root->addChild($child_plugin_exit);
    $root->addChild($child_plugin_output);
    $root->addChild($child_plugin_perfdata);

    foreach my $code_litteral (keys %{$self->{global_short_outputs}}) {
        foreach (@{$self->{global_short_outputs}->{$code_litteral}}) {
            my ($child_output, $child_type, $child_msg, $child_exit);
            my $lcode_litteral = ($code_litteral eq 'UNQUALIFIED_YET' ? uc($options{exit_litteral}) : $code_litteral);

            $child_output = $self->{xml_output}->createElement("output");
            $child_plugin_output->addChild($child_output);

            $child_type = $self->{xml_output}->createElement("type");
            $child_type->appendText(1); # short

            $child_msg = $self->{xml_output}->createElement("msg");
            $child_msg->appendText(($options{nolabel} == 0 ? ($lcode_litteral . ': ') : '') . $_);
            $child_exit = $self->{xml_output}->createElement("exit");
            $child_exit->appendText($lcode_litteral);

            $child_output->addChild($child_type);
            $child_output->addChild($child_exit);
            $child_output->addChild($child_msg);
        }
    }

    if (defined($self->{option_results}->{verbose}) || $force_long_output == 1) {
        foreach (@{$self->{global_long_output}}) {
            my ($child_output, $child_type, $child_msg);
        
            $child_output = $self->{xml_output}->createElement("output");
            $child_plugin_output->addChild($child_output);

            $child_type = $self->{xml_output}->createElement("type");
            $child_type->appendText(2); # long

            $child_msg = $self->{xml_output}->createElement("msg");
            $child_msg->appendText($_);

            $child_output->addChild($child_type);
            $child_output->addChild($child_msg);
        }
    }

    if ($options{force_ignore_perfdata} == 0) {
        $self->change_perfdatas();
        foreach my $perf (@{$self->{perfdatas}}) {
            next if (defined($self->{option_results}->{filter_perfdata}) &&
                     $perf->{label} !~ /$self->{option_results}->{filter_perfdata}/);
            $self->range_perfdata(ranges => [\$perf->{warning}, \$perf->{critical}]);
        
            my ($child_perfdata);
            $child_perfdata = $self->{xml_output}->createElement("perfdata");
            $child_plugin_perfdata->addChild($child_perfdata);
            foreach my $key (keys %$perf) {
                $perf->{$key} = '' if (defined($self->{option_results}->{filter_uom}) && $key eq 'unit' &&
                    $perf->{$key} !~ /$self->{option_results}->{filter_uom}/);
                my $child = $self->{xml_output}->createElement($key);
                $child->appendText($perf->{$key});
                $child_perfdata->addChild($child);
            }
        }
    }

    print $self->{xml_output}->toString(1);
}

sub output_txt {
    my ($self, %options) = @_;
    my $force_ignore_perfdata = (defined($options{force_ignore_perfdata}) && $options{force_ignore_perfdata} == 1) ? 1 : 0;
    my $force_long_output = (defined($options{force_long_output}) && $options{force_long_output} == 1) ? 1 : 0;

    if (defined($self->{global_short_concat_outputs}->{UNQUALIFIED_YET})) {
        $self->output_add(severity => uc($options{exit_litteral}), short_msg => $self->{global_short_concat_outputs}->{UNQUALIFIED_YET});
    }

    if (defined($self->{global_short_concat_outputs}->{CRITICAL})) {
        print (($options{nolabel} == 0 ? 'CRITICAL: ' : '') . $self->{global_short_concat_outputs}->{CRITICAL} . " ");
    }
    if (defined($self->{global_short_concat_outputs}->{WARNING})) {
        print (($options{nolabel} == 0 ? 'WARNING: ' : '') . $self->{global_short_concat_outputs}->{WARNING} . " ");
    }
    if (defined($self->{global_short_concat_outputs}->{UNKNOWN})) {
        print (($options{nolabel} == 0 ? 'UNKNOWN: ' : '') . $self->{global_short_concat_outputs}->{UNKNOWN} . " ");
    }
    if (uc($options{exit_litteral}) eq 'OK') {
        print (($options{nolabel} == 0 ? 'OK: ' : '') . (defined($self->{global_short_concat_outputs}->{OK}) ? $self->{global_short_concat_outputs}->{OK} : '') . " ");
    }

    if ($force_ignore_perfdata == 1) {
        print "\n";
    } else {
        print "|";
        $self->change_perfdatas();
        foreach my $perf (@{$self->{perfdatas}}) {
            next if (defined($self->{option_results}->{filter_perfdata}) &&
                     $perf->{label} !~ /$self->{option_results}->{filter_perfdata}/);
            $perf->{unit} = '' if (defined($self->{option_results}->{filter_uom}) &&
                $perf->{unit} !~ /$self->{option_results}->{filter_uom}/);
            $self->range_perfdata(ranges => [\$perf->{warning}, \$perf->{critical}]);
            print " '" . $perf->{label} . "'=" . $perf->{value} . $perf->{unit} . ";" . $perf->{warning} . ";" . $perf->{critical} . ";" . $perf->{min} . ";" . $perf->{max};
        }
        print "\n";
    }
    
    if (defined($self->{option_results}->{verbose}) || $force_long_output == 1) {
        if (scalar(@{$self->{global_long_output}})) {
            print join("\n", @{$self->{global_long_output}});
            print "\n";
        }
    }
}

sub display {
    my ($self, %options) = @_;
    my $nolabel = defined($options{nolabel}) ? 1 : 0;
    my $force_ignore_perfdata = (defined($options{force_ignore_perfdata}) && $options{force_ignore_perfdata} == 1) ? 1 : 0;
    my $force_long_output = (defined($options{force_long_output}) && $options{force_long_output} == 1) ? 1 : 0;
    $force_long_output = 1 if (defined($self->{option_results}->{debug}));

    if (defined($self->{option_results}->{output_xml})) {
        $self->create_xml_document();
        if ($self->{is_output_xml}) {
            $self->output_xml(exit_litteral => $self->get_litteral_status(), 
                              nolabel => $nolabel, 
                              force_ignore_perfdata => $force_ignore_perfdata, force_long_output => $force_long_output);
            return ;
        }
    } elsif (defined($self->{option_results}->{output_json})) {
        $self->create_json_document();
        if ($self->{is_output_json}) {
            $self->output_json(exit_litteral => $self->get_litteral_status(), 
                               nolabel => $nolabel,
                               force_ignore_perfdata => $force_ignore_perfdata, force_long_output => $force_long_output);
            return ;
        }
    } 
    
    $self->output_txt(exit_litteral => $self->get_litteral_status(), 
                      nolabel => $nolabel,
                      force_ignore_perfdata => $force_ignore_perfdata, force_long_output => $force_long_output);
}

sub die_exit {
    my ($self, %options) = @_;
    # $options{exit_litteral} = string litteral exit
    # $options{nolabel} = interger label display
    my $exit_litteral = defined($options{exit_litteral}) ? $options{exit_litteral} : $self->{option_results}->{opt_exit};
    my $nolabel = defined($options{nolabel}) ? 1 : 0;
    # ignore long output in the following case
    $self->{option_results}->{verbose} = undef;

    if (defined($self->{option_results}->{output_xml})) {
        $self->create_xml_document();
        if ($self->{is_output_xml}) {
            $self->output_xml(exit_litteral => $exit_litteral, nolabel => $nolabel, force_ignore_perfdata => 1);
            $self->exit(exit_litteral => $exit_litteral);
        }
    } elsif (defined($self->{option_results}->{output_json})) {
        $self->create_json_document();
        if ($self->{is_output_json}) {
            $self->output_json(exit_litteral => $exit_litteral, nolabel => $nolabel, force_ignore_perfdata => 1);
            $self->exit(exit_litteral => $exit_litteral);
        }
    } 

    $self->output_txt(exit_litteral => $exit_litteral, nolabel => $nolabel, force_ignore_perfdata => 1);
    $self->exit(exit_litteral => $exit_litteral);
}

sub option_exit {
    my ($self, %options) = @_;
    # $options{exit_litteral} = string litteral exit
    # $options{nolabel} = interger label display
    my $exit_litteral = defined($options{exit_litteral}) ? $options{exit_litteral} : $self->{option_results}->{opt_exit};
    my $nolabel = defined($options{nolabel}) ? 1 : 0;

    if (defined($self->{option_results}->{output_xml})) {
        $self->create_xml_document();
        if ($self->{is_output_xml}) {
            $self->output_xml(exit_litteral => $exit_litteral, nolabel => $nolabel, force_ignore_perfdata => 1, force_long_output => 1);
            $self->exit(exit_litteral => $exit_litteral);
        }
    } elsif (defined($self->{option_results}->{output_json})) {
        $self->create_json_document();
        if ($self->{is_output_json}) {
            $self->output_json(exit_litteral => $exit_litteral, nolabel => $nolabel, force_ignore_perfdata => 1, force_long_output => 1);
            $self->exit(exit_litteral => $exit_litteral);
        }
    } 

    $self->output_txt(exit_litteral => $exit_litteral, nolabel => $nolabel, force_ignore_perfdata => 1, force_long_output => 1);
    $self->exit(exit_litteral => $exit_litteral);
}

sub exit {
    my ($self, %options) = @_;
    # $options{exit_litteral} = exit
    
    if (defined($options{exit_litteral})) {
        exit $self->{errors}->{uc($options{exit_litteral})};
    }
    exit $self->{errors}->{$self->{myerrors}->{$self->{global_status}}};
}

sub get_most_critical {
    my ($self, %options) = @_;
    my $current_status = 0; # For 'OK'

    foreach (@{$options{status}}) {
        if ($self->{myerrors_mask}->{uc($_)} > $current_status) {
            $current_status = $self->{myerrors_mask}->{uc($_)};
        }
    }
    return $self->{myerrors}->{$current_status};
}

sub get_litteral_status {
    my ($self, %options) = @_;
    
    if (defined($options{status})) {
        if (defined($self->{errors_num}->{$options{status}})) {
            return $self->{errors_num}->{$options{status}};
        }
        return $options{status};
    } else {
        return $self->{myerrors}->{$self->{global_status}};
    }
}

sub is_status {
    my ($self, %options) = @_;
    # $options{value} = string status 
    # $options{litteral} = value is litteral
    # $options{compare} = string status 

    if (defined($options{litteral})) {
        my $value = defined($options{value}) ? $options{value} : $self->get_litteral_status();
    
        if (uc($value) eq uc($options{compare})) {
            return 1;
        }
        return 0;
    }

    my $value = defined($options{value}) ? $options{value} : $self->{global_status};
    my $dec_val = $self->{myerrors_mask}->{$value};
    my $lresult = $value & $dec_val;
    # Need to manage 0
    if ($lresult > 0 || ($dec_val == 0 && $value == 0)) {
        return 1;
    }
    return 0;
}

sub is_litteral_status {
    my ($self, %options) = @_;
    # $options{status} = string status

    if (defined($self->{errors}->{uc($options{status})})) {
        return 1;
    }

    return 0;
}

sub create_json_document {
    my ($self) = @_;

    if (centreon::plugins::misc::mymodule_load(no_quit => 1, module => 'JSON',
                                           error_msg => "Cannot load module 'JSON'.")) {
        print "Cannot load module 'JSON'\n";
        $self->exit(exit_litteral => 'unknown');
    }
    $self->{is_output_json} = 1;
    $self->{json_output} = JSON->new->utf8();
}

sub create_xml_document {
    my ($self) = @_;

    if (centreon::plugins::misc::mymodule_load(no_quit => 1, module => 'XML::LibXML',
                                           error_msg => "Cannot load module 'XML::LibXML'.")) {
        print "Cannot load module 'XML::LibXML'\n";
        $self->exit(exit_litteral => 'unknown');
    }
    $self->{is_output_xml} = 1;
    $self->{xml_output} = XML::LibXML::Document->new('1.0', 'utf-8');
}

sub plugin {
    my ($self, %options) = @_;
    # $options{name} = string name
    
    if (defined($options{name})) {
        $self->{plugin} = $options{name};
    }
    return $self->{plugin};
}

sub mode {
    my ($self, %options) = @_;
    # $options{name} = string name

    if (defined($options{name})) {
        $self->{mode} = $options{name};
    }
    return $self->{mode};
}

sub add_disco_format {
    my ($self, %options) = @_;

    push @{$self->{disco_elements}}, @{$options{elements}};
}

sub display_disco_format {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{output_xml})) {
        $self->create_xml_document();
    
        my $root = $self->{xml_output}->createElement('data');
        $self->{xml_output}->setDocumentElement($root);

        foreach (@{$self->{disco_elements}}) {
            my $child = $self->{xml_output}->createElement("element");
            $child->appendText($_);
            $root->addChild($child);
        }

        print $self->{xml_output}->toString(1);
    } elsif (defined($self->{option_results}->{output_json})) {
        $self->create_json_document();
        my $json_content = {data => [] };
        foreach (@{$self->{disco_elements}}) {
            push @{$json_content->{data}}, $_;
        }
        
        print $self->{json_output}->encode($json_content);
    }
}

sub display_disco_show {
    my ($self, %options) = @_;
    
     if (defined($self->{option_results}->{output_xml})) {
        $self->create_xml_document();
        
        my $root = $self->{xml_output}->createElement('data');
        $self->{xml_output}->setDocumentElement($root);

        foreach (@{$self->{disco_entries}}) {
            my $child = $self->{xml_output}->createElement("label");
            foreach my $key (keys %$_) {
                $child->setAttribute($key, $_->{$key});
            }
            $root->addChild($child);
        }

        print $self->{xml_output}->toString(1);
    } elsif (defined($self->{option_results}->{output_json})) {
        $self->create_json_document();
        my $json_content = {data => [] };
        foreach (@{$self->{disco_entries}}) {
            my %values = ();
            foreach my $key (keys %$_) {
                $values{$key} = $_->{$key};
            }
            push @{$json_content->{data}}, {%values};
        }
        
        print $self->{json_output}->encode($json_content);
    }
}

sub to_utf8 {
    my ($self, $value) = @_;
    
    if ($self->{encode_utf8_import} == 0) {
        
        
        # Some Perl version dont have the following module (like Perl 5.6.x)
        if (centreon::plugins::misc::mymodule_load(no_quit => 1, module => 'Encode',
                                                   error_msg => "Cannot load module 'Encode'.")) {
            print "Cannot load module 'Encode'\n";
            $self->exit(exit_litteral => 'unknown');
        }
        
        $self->{encode_utf8_import} = 1;
        eval '$self->{perlqq} = Encode::PERLQQ';
    }
    
    return centreon::plugins::misc::trim(Encode::decode('UTF-8', $value, $self->{perlqq}));
}

sub add_disco_entry {
    my ($self, %options) = @_;
    
    push @{$self->{disco_entries}}, {%options};
}

sub is_disco_format {
    my ($self) = @_;

    if (defined($self->{option_results}->{disco_format})) {
        return 1;
    }
    return 0;
}

sub is_disco_show {
    my ($self) = @_;

    if (defined($self->{option_results}->{disco_show})) {
        return 1;
    }
    return 0;
}

1;

__END__

=head1 NAME

Output class

=head1 SYNOPSIS

-

=head1 OUTPUT OPTIONS

=over 8

=item B<--verbose>

Display long output.

=item B<--debug>

Display also debug messages.

=item B<--filter-perfdata>

Filter perfdata that match the regexp.

=item B<--explode-perfdata-max>

Put max perfdata (if it exist) in a specific perfdata 
(without values: same with '_max' suffix) (Multiple options)

=item B<--change-perfdata>

Change perfdata name (Multiple option)
Syntax: regexp_matching,regexp_substitute

=item B<--range-perfdata>

Change perfdata range thresholds display: 
1 = start value equals to '0' is removed, 2 = threshold range is not display.

=item B<--filter-uom>

Filter UOM that match the regexp.

=item B<--opt-exit>

Exit code for an option error, usage (default: unknown).

=item B<--output-xml>

Display output in XML Format.

=item B<--output-json>

Display output in JSON Format.

=item B<--disco-format>

Display discovery arguments (if the mode manages it).

=item B<--disco-show>

Display discovery values (if the mode manages it).

=head1 DESCRIPTION

B<output>.

=cut
