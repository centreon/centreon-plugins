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

package centreon::plugins::output;

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{options})) {
        print "Class Output: Need to specify 'options' argument to load.\n";
        exit 3;
    }

    $options{options}->add_options(arguments => {
        'explode-perfdata-max:s@' => { name => 'explode_perfdata_max' },
        'range-perfdata:s'        => { name => 'range_perfdata' },
        'filter-perfdata:s'       => { name => 'filter_perfdata' },
        'change-perfdata:s@'      => { name => 'change_perfdata' },
        'extend-perfdata:s@'      => { name => 'extend_perfdata' },
        'extend-perfdata-group:s@'=> { name => 'extend_perfdata_group' },
        'change-short-output:s@'  => { name => 'change_short_output' },
        'use-new-perfdata'        => { name => 'use_new_perfdata' },
        'filter-uom:s'            => { name => 'filter_uom' },
        'verbose'                 => { name => 'verbose' },
        'debug'                   => { name => 'debug' },
        'opt-exit:s'              => { name => 'opt_exit', default => 'unknown' },
        'output-xml'              => { name => 'output_xml' },
        'output-json'             => { name => 'output_json' },
        'output-ignore-perfdata'  => { name => 'output_ignore_perfdata' },
        'output-ignore-label'     => { name => 'output_ignore_label' },
        'output-openmetrics'      => { name => 'output_openmetrics' },
        'output-file:s'           => { name => 'output_file' },
        'disco-format'            => { name => 'disco_format' },
        'disco-show'              => { name => 'disco_show' },
        'float-precision:s'       => { name => 'float_precision', default => 8 },
        'source-encoding:s'       => { name => 'source_encoding' , default => 'UTF-8' }
    });

    $self->{option_results} = {};

    $self->{option_msg} = [];

    $self->{nodisplay} = 0;
    $self->{noexit_die} = 0;

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
    $self->{encode_import} = 0;
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

    $self->load_perfdata_extend_args();
    $self->{option_results}->{use_new_perfdata} = 1 if (defined($self->{option_results}->{output_openmetrics}));

    $self->{source_encoding} = (!defined($self->{option_results}->{source_encoding}) || $self->{option_results}->{source_encoding} eq '') ?
        'UTF-8' : $self->{option_results}->{source_encoding};
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
        long_msg => undef,
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
    my $perfdata = {
        label => '', value => '', unit => '', warning => '', critical => '', min => '', max => '', mode => $self->{mode},
    };
    foreach (keys %options) {
        next if (!defined($options{$_}));
        $perfdata->{$_} = $options{$_};
    }

    if (defined($self->{option_results}->{use_new_perfdata}) && defined($options{nlabel})) {
        $perfdata->{label} = $options{nlabel};
    }
    if (defined($options{instances})) {
        $options{instances} = [$options{instances}] if (!ref($options{instances}));
        my ($external_instance_separator, $internal_instance_separator) = ('#', '~');
        if (defined($self->{option_results}->{use_new_perfdata})) {
            $perfdata->{label} = join('~', @{$options{instances}}) . '#' . $perfdata->{label};
        } else {
            $perfdata->{label} .= '_' . join('_', @{$options{instances}});
        }
    }

    $perfdata->{label} =~ s/'/''/g;
    push @{$self->{perfdatas}}, $perfdata;
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
    my $json_content = {
        plugin => {
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
        $self->change_perfdata();
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

    $child_plugin_name = $self->{xml_output}->createElement('name');
    $child_plugin_name->appendText($self->{plugin});

    $child_plugin_mode = $self->{xml_output}->createElement('mode');
    $child_plugin_mode->appendText($self->{mode});

    $child_plugin_exit = $self->{xml_output}->createElement('exit');
    $child_plugin_exit->appendText($options{exit_litteral});

    $child_plugin_output = $self->{xml_output}->createElement('outputs');
    $child_plugin_perfdata = $self->{xml_output}->createElement('perfdatas');

    $root->addChild($child_plugin_name);
    $root->addChild($child_plugin_mode);
    $root->addChild($child_plugin_exit);
    $root->addChild($child_plugin_output);
    $root->addChild($child_plugin_perfdata);

    foreach my $code_litteral (keys %{$self->{global_short_outputs}}) {
        foreach (@{$self->{global_short_outputs}->{$code_litteral}}) {
            my ($child_output, $child_type, $child_msg, $child_exit);
            my $lcode_litteral = ($code_litteral eq 'UNQUALIFIED_YET' ? uc($options{exit_litteral}) : $code_litteral);

            $child_output = $self->{xml_output}->createElement('output');
            $child_plugin_output->addChild($child_output);

            $child_type = $self->{xml_output}->createElement('type');
            $child_type->appendText(1); # short

            $child_msg = $self->{xml_output}->createElement('msg');
            $child_msg->appendText(($options{nolabel} == 0 ? ($lcode_litteral . ': ') : '') . $_);
            $child_exit = $self->{xml_output}->createElement('exit');
            $child_exit->appendText($lcode_litteral);

            $child_output->addChild($child_type);
            $child_output->addChild($child_exit);
            $child_output->addChild($child_msg);
        }
    }

    if (defined($self->{option_results}->{verbose}) || $force_long_output == 1) {
        foreach (@{$self->{global_long_output}}) {
            my ($child_output, $child_type, $child_msg);

            $child_output = $self->{xml_output}->createElement('output');
            $child_plugin_output->addChild($child_output);

            $child_type = $self->{xml_output}->createElement('type');
            $child_type->appendText(2); # long

            $child_msg = $self->{xml_output}->createElement('msg');
            $child_msg->appendText($_);

            $child_output->addChild($child_type);
            $child_output->addChild($child_msg);
        }
    }

    if ($options{force_ignore_perfdata} == 0) {
        $self->change_perfdata();
        foreach my $perf (@{$self->{perfdatas}}) {
            next if (defined($self->{option_results}->{filter_perfdata}) &&
                     $perf->{label} !~ /$self->{option_results}->{filter_perfdata}/);
            $self->range_perfdata(ranges => [\$perf->{warning}, \$perf->{critical}]);
        
            my ($child_perfdata);
            $child_perfdata = $self->{xml_output}->createElement('perfdata');
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

sub output_openmetrics {
    my ($self, %options) = @_;

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'Time::HiRes',
        error_msg => "Cannot load module 'Time::HiRes'."
    );

    my $time_ms = int(Time::HiRes::time() * 1000);
    $self->change_perfdata();

    foreach my $perf (@{$self->{perfdatas}}) {
        next if (defined($self->{option_results}->{filter_perfdata}) &&
                 $perf->{label} !~ /$self->{option_results}->{filter_perfdata}/);
        $perf->{unit} = '' if (defined($self->{option_results}->{filter_uom}) &&
            $perf->{unit} !~ /$self->{option_results}->{filter_uom}/);
        $self->range_perfdata(ranges => [\$perf->{warning}, \$perf->{critical}]);
        my $label = $perf->{label};
        my $instance;
        if ($label =~ /^(.*?)#(.*)$/) {
            ($perf->{instance}, $label) = ($1, $2);
        }
        my ($bucket, $append) = ('{plugin="' . $self->{plugin} . '",mode="' . $perf->{mode} . '"', '');
        foreach ('unit', 'warning', 'critical', 'min', 'max', 'instance') {
            if (defined($perf->{$_}) && $perf->{$_} ne '') {
                $bucket .= ',' . $_ . '="' . $perf->{$_} . '"';
            }
        }
        $bucket .= '}';

        print $label . $bucket . ' ' . $perf->{value} . ' ' . $time_ms . "\n";
    }
}

sub output_txt_short_display {
    my ($self, %options) = @_;

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
}

sub output_txt_short {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{change_short_output})) {
        $self->output_txt_short_display(%options);
        return ;
    }

    my $stdout = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        $self->output_txt_short_display(%options);
    }

    foreach (@{$self->{option_results}->{change_short_output}}) {
         my ($pattern, $replace, $modifier) = split /~/;
         next if (!defined($pattern));
         $replace = '' if (!defined($replace));
         $modifier = '' if (!defined($modifier));
         eval "\$stdout =~ s{$pattern}{$replace}$modifier";
    }

    print $stdout;
}

sub output_txt {
    my ($self, %options) = @_;
    my $force_ignore_perfdata = (defined($options{force_ignore_perfdata}) && $options{force_ignore_perfdata} == 1) ? 1 : 0;
    my $force_long_output = (defined($options{force_long_output}) && $options{force_long_output} == 1) ? 1 : 0;

    return if ($self->{nodisplay} == 1);
    if (defined($self->{global_short_concat_outputs}->{UNQUALIFIED_YET})) {
        $self->output_add(severity => uc($options{exit_litteral}), short_msg => $self->{global_short_concat_outputs}->{UNQUALIFIED_YET});
    }

    $self->output_txt_short(%options);

    if ($force_ignore_perfdata == 1) {
        print "\n";
    } else {
        print '|';
        $self->change_perfdata();
        foreach my $perf (@{$self->{perfdatas}}) {
            next if (defined($self->{option_results}->{filter_perfdata}) &&
                     $perf->{label} !~ /$self->{option_results}->{filter_perfdata}/);
            $perf->{unit} = '' if (defined($self->{option_results}->{filter_uom}) &&
                $perf->{unit} !~ /$self->{option_results}->{filter_uom}/);
            $self->range_perfdata(ranges => [\$perf->{warning}, \$perf->{critical}]);
            print " '" . $perf->{label} . "'=" . $perf->{value} . $perf->{unit} . ';' . $perf->{warning} . ';' . $perf->{critical} . ';' . $perf->{min} . ';' . $perf->{max};
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
    my $nolabel = (defined($options{nolabel}) || defined($self->{option_results}->{output_ignore_label})) ? 1 : 0;
    my $force_ignore_perfdata = ((defined($options{force_ignore_perfdata}) && $options{force_ignore_perfdata} == 1) || $self->{option_results}->{output_ignore_perfdata}) ? 1 : 0;
    my $force_long_output = (defined($options{force_long_output}) && $options{force_long_output} == 1) ? 1 : 0;
    $force_long_output = 1 if (defined($self->{option_results}->{debug}));

    if (defined($self->{option_results}->{output_openmetrics})) {
        $self->perfdata_add(nlabel => 'plugin.mode.status', value => $self->{errors}->{$self->{myerrors}->{$self->{global_status}}});
    }

    return if ($self->{nodisplay} == 1);

    if (defined($self->{option_results}->{output_file})) {
        if (!open (STDOUT, '>', $self->{option_results}->{output_file})) {
            $self->output_add(
                severity => 'UNKNOWN',
                short_msg => "cannot open file  '" . $self->{option_results}->{output_file} . "': $!"
            );
        }
    }
    if (defined($self->{option_results}->{output_xml})) {
        $self->create_xml_document();
        if ($self->{is_output_xml}) {
            $self->output_xml(
                exit_litteral => $self->get_litteral_status(), 
                nolabel => $nolabel, 
                force_ignore_perfdata => $force_ignore_perfdata, force_long_output => $force_long_output
            );
            return ;
        }
    } elsif (defined($self->{option_results}->{output_json})) {
        $self->create_json_document();
        if ($self->{is_output_json}) {
            $self->output_json(
                exit_litteral => $self->get_litteral_status(), 
                nolabel => $nolabel,
                force_ignore_perfdata => $force_ignore_perfdata, force_long_output => $force_long_output
            );
            return ;
        }
    } elsif (defined($self->{option_results}->{output_openmetrics})) {
        $self->output_openmetrics();
        return ;
    }

    $self->output_txt(
        exit_litteral => $self->get_litteral_status(), 
        nolabel => $nolabel,
        force_ignore_perfdata => $force_ignore_perfdata, force_long_output => $force_long_output
    );
}

sub die_exit {
    my ($self, %options) = @_;
    # $options{exit_litteral} = string litteral exit
    # $options{nolabel} = interger label display
    my $exit_litteral = defined($options{exit_litteral}) ? $options{exit_litteral} : $self->{option_results}->{opt_exit};
    my $nolabel = (defined($options{nolabel}) || defined($self->{option_results}->{output_ignore_label})) ? 1 : 0;
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
    my $nolabel = (defined($options{nolabel}) || defined($self->{option_results}->{output_ignore_label})) ? 1 : 0;

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
    } elsif (defined($self->{option_results}->{output_openmetrics})) {
        $self->set_status(exit_litteral => $exit_litteral);
        $self->output_openmetrics();
        $self->exit(exit_litteral => $exit_litteral);
    }

    $self->output_txt(exit_litteral => $exit_litteral, nolabel => $nolabel, force_ignore_perfdata => 1, force_long_output => 1);
    $self->exit(exit_litteral => $exit_litteral);
}

sub exit {
    my ($self, %options) = @_;

    if ($self->{noexit_die} == 1) {
        die 'exit';
    }
    if (defined($options{exit_litteral})) {
        exit $self->{errors}->{uc($options{exit_litteral})};
    }
    exit $self->{errors}->{$self->{myerrors}->{$self->{global_status}}};
}

sub get_option {
    my ($self, %options) = @_;

    return $self->{option_results}->{$options{option}};
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

    if (centreon::plugins::misc::mymodule_load(
        no_quit => 1, module => 'JSON',
        error_msg => "Cannot load module 'JSON'.")
        ) {
        print "Cannot load module 'JSON'\n";
        $self->exit(exit_litteral => 'unknown');
    }
    $self->{is_output_json} = 1;
    $self->{json_output} = JSON->new->utf8();
}

sub create_xml_document {
    my ($self) = @_;

    if (centreon::plugins::misc::mymodule_load(
        no_quit => 1, module => 'XML::LibXML',
        error_msg => "Cannot load module 'XML::LibXML'.")
        ) {
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
            my $child = $self->{xml_output}->createElement('label');
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

sub decode {
    my ($self, $value) = @_;

    if ($self->{encode_import} == 0) {
        # Some Perl version dont have the following module (like Perl 5.6.x)
        my $rv = centreon::plugins::misc::mymodule_load(
            no_quit => 1,
            module => 'Encode',
            error_msg => "Cannot load module 'Encode'."
        );
        return $value if ($rv);

        $self->{encode_import} = 1;
        eval '$self->{perlqq} = Encode::PERLQQ';
    }

    return centreon::plugins::misc::trim(Encode::decode($self->{source_encoding}, $value, $self->{perlqq}));
}

sub parameter {
    my ($self, %options) = @_;

    if (defined($options{attr})) {
        $self->{$options{attr}} = $options{value};
    }
    return $self->{$options{attr}};
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

sub is_verbose {
    my ($self) = @_;

    if (defined($self->{option_results}->{verbose})) {
        return 1;
    }
    return 0;
}

sub is_debug {
    my ($self) = @_;

    if (defined($self->{option_results}->{debug})) {
        return 1;
    }
    return 0;
}

sub use_new_perfdata {
    my ($self, %options) = @_;

    $self->{option_results}->{use_new_perfdata} = $options{value}
        if (defined($options{value}));
    if (defined($self->{option_results}->{use_new_perfdata})) {
        return 1;
    }
    return 0;
}

sub get_instance_perfdata_separator {
    my ($self) = @_;

    if (defined($self->{option_results}->{use_new_perfdata})) {
        return '~';
    }
    return '_';
}

sub parse_pfdata_scale {
    my ($self, %options) = @_;

    # --extend-perfdata=traffic_in,,scale(Mbps),mbps
    my $args = { unit => 'auto' };
    if ($options{args} =~ /^([KMGTPEkmgtpe])?(B|b|bps|Bps|b\/s|auto)$/) {
        $args->{quantity} = defined($1) ? $1 : '';
        $args->{unit} = $2;
    } elsif ($options{args} ne '') {
        return 1;
    }

    return (0, $args);
}

sub parse_pfdata_math {
    my ($self, %options) = @_;

    # --extend-perfdata=perfx,,math(current + 10 - 100, 1)
    my $args = { math => undef, apply_threshold => 0 };
    my ($math, $apply_threshold) = split /\|/, $options{args};
    if ($math =~ /^((?:[\s\.\-\+\*\/0-9\(\)]|current)+)$/) {
        $args->{math} = $1;
    } elsif ($options{args} ne '') {
        return 1;
    }

    if (defined($apply_threshold) && $apply_threshold =~ /^\s*(0|1)\s*$/ ) {
        $args->{apply_threshold} = $1;
    }

    return (0, $args);
}

sub parse_group_pfdata {
    my ($self, %options) = @_;

    $options{args} =~ s/^\s+//;
    $options{args} =~ s/\s+$//;
    my $args = { pattern_pf => $options{args} };
    return $args;
}

sub parse_pfdata_min {
    my ($self, %options) = @_;

    my $args = $self->parse_group_pfdata(%options);
    return (0, $args);
}

sub parse_pfdata_max {
    my ($self, %options) = @_;

    my $args = $self->parse_group_pfdata(%options);
    return (0, $args);
}

sub parse_pfdata_average {
    my ($self, %options) = @_;

    my $args = $self->parse_group_pfdata(%options);
    return (0, $args);
}

sub parse_pfdata_sum {
    my ($self, %options) = @_;

    my $args = $self->parse_group_pfdata(%options);
    return (0, $args);
}

sub apply_pfdata_scale {
    my ($self, %options) = @_;

    return if (${$options{perf}}->{unit} !~ /^([KMGTPEkmgtpe])?(B|b|bps|Bps|b\/s)$/);

    my ($src_quantity, $src_unit) = ($1, $2);
    my ($value, $dst_quantity, $dst_unit) = centreon::plugins::misc::scale_bytesbit(value => ${$options{perf}}->{value},
        src_quantity => $src_quantity, src_unit => $src_unit, dst_quantity => $options{args}->{quantity}, dst_unit => $options{args}->{unit});
    ${$options{perf}}->{value} = sprintf("%.2f", $value);
    if (defined($dst_unit)) {
       ${$options{perf}}->{unit} = $dst_quantity . $dst_unit;
    } else {
        ${$options{perf}}->{unit} = $options{args}->{quantity} . $options{args}->{unit};
    }

    if (defined(${$options{perf}}->{max}) && ${$options{perf}}->{max} ne '') {
        ($value) = centreon::plugins::misc::scale_bytesbit(value => ${$options{perf}}->{max},
            src_quantity => $src_quantity, src_unit => $src_unit, 
            dst_quantity => defined($dst_unit) ? $dst_quantity : $options{args}->{quantity}, 
            dst_unit => defined($dst_unit) ? $dst_unit : $options{args}->{unit});
        ${$options{perf}}->{max} = sprintf('%.2f', $value);
    }

    foreach my $threshold ('warning', 'critical') {
        next if (${$options{perf}}->{$threshold} eq '');
        my ($status, $result) = centreon::plugins::misc::parse_threshold(threshold => ${$options{perf}}->{$threshold});
        next if ($status == 0);

        if ($result->{start} ne '' && $result->{infinite_neg} == 0) {
            ($result->{start}) = centreon::plugins::misc::scale_bytesbit(value => $result->{start},
                src_quantity => $src_quantity, src_unit => $src_unit, 
                dst_quantity => defined($dst_unit) ? $dst_quantity : $options{args}->{quantity}, 
                dst_unit => defined($dst_unit) ? $dst_unit : $options{args}->{unit});
        }
        if ($result->{end} ne '' && $result->{infinite_pos} == 0) {
            ($result->{end}) = centreon::plugins::misc::scale_bytesbit(value => $result->{end},
                src_quantity => $src_quantity, src_unit => $src_unit, 
                dst_quantity => defined($dst_unit) ? $dst_quantity : $options{args}->{quantity}, 
                dst_unit => defined($dst_unit) ? $dst_unit : $options{args}->{unit});
        }

        ${$options{perf}}->{$threshold} = centreon::plugins::misc::get_threshold_litteral(%$result);
    }
}

sub apply_pfdata_invert {
    my ($self, %options) = @_;

    return if (!defined(${$options{perf}}->{max}) || ${$options{perf}}->{max} eq '');

    ${$options{perf}}->{value} = ${$options{perf}}->{max} - ${$options{perf}}->{value};
    foreach my $threshold ('warning', 'critical') {
        next if (${$options{perf}}->{$threshold} eq '');
        my ($status, $result) = centreon::plugins::misc::parse_threshold(threshold => ${$options{perf}}->{$threshold});
        next if ($status == 0);

        my $tmp = { arobase => $result->{arobase}, infinite_pos => 0, infinite_neg => 0, start => $result->{start}, end => $result->{end} };
        $tmp->{infinite_neg} = 1 if ($result->{infinite_pos} == 1);
        $tmp->{infinite_pos} = 1 if ($result->{infinite_neg} == 1);

        if ($result->{start} ne '' && $result->{infinite_neg} == 0) {
            $tmp->{end} = ${$options{perf}}->{max} - $result->{start};
        }
        if ($result->{end} ne '' && $result->{infinite_pos} == 0) {
            $tmp->{start} = ${$options{perf}}->{max} - $result->{end};
        }

        ${$options{perf}}->{$threshold} = centreon::plugins::misc::get_threshold_litteral(%$tmp);
    }
}

sub apply_pfdata_percent {
    my ($self, %options) = @_;

    return if (!defined(${$options{perf}}->{max}) || ${$options{perf}}->{max} eq '');

    ${$options{perf}}->{value} = sprintf('%.2f', ${$options{perf}}->{value} * 100 / ${$options{perf}}->{max});
    ${$options{perf}}->{unit} = '%';
    foreach my $threshold ('warning', 'critical') {
        next if (${$options{perf}}->{$threshold} eq '');
        my ($status, $result) = centreon::plugins::misc::parse_threshold(threshold => ${$options{perf}}->{$threshold});
        next if ($status == 0);

        if ($result->{start} ne '' && $result->{infinite_neg} == 0) {
            $result->{start} = sprintf('%.2f', $result->{start} * 100 / ${$options{perf}}->{max});
        }
        if ($result->{end} ne '' && $result->{infinite_pos} == 0) {
            $result->{end} = sprintf('%.2f', $result->{end} * 100 / ${$options{perf}}->{max});
        }

        ${$options{perf}}->{$threshold} = centreon::plugins::misc::get_threshold_litteral(%$result);
    }

    ${$options{perf}}->{max} = 100; 
}

sub apply_pfdata_math {
    my ($self, %options) = @_;

    my $math = $options{args}->{math};
    $math =~ s/current/\$value/g;

    my $value = ${$options{perf}}->{value};
    eval "\${\$options{perf}}->{value} = $math";

    return if ($options{args}->{apply_threshold} == 0);

    foreach my $threshold ('warning', 'critical') {
        next if (${$options{perf}}->{$threshold} eq '');
        my ($status, $result) = centreon::plugins::misc::parse_threshold(threshold => ${$options{perf}}->{$threshold});
        next if ($status == 0);

        if ($result->{start} ne '' && $result->{infinite_neg} == 0) {
            $value = $result->{start};
            eval "\$result->{start} = $math";
        }
        if ($result->{end} ne '' && $result->{infinite_pos} == 0) {
            $value = $result->{end};
            eval "\$result->{end} = $math";
        }

        ${$options{perf}}->{$threshold} = centreon::plugins::misc::get_threshold_litteral(%$result);
    }

    ${$options{perf}}->{max} = 100;
}

sub apply_pfdata_min {
    my ($self, %options) = @_;

    my $pattern_pf;
    eval "\$pattern_pf = \"$options{args}->{pattern_pf}\"";
    my $min;
    for (my $i = 0; $i < scalar(@{$self->{perfdatas}}); $i++) {
        next if ($self->{perfdatas}->[$i]->{label} !~ /$pattern_pf/);
        next if ($self->{perfdatas}->[$i]->{value} !~ /\d+/);
        $min = $self->{perfdatas}->[$i]->{value}
            if (!defined($min) || $min > $self->{perfdatas}->[$i]->{value});
    }

    ${$options{perf}}->{value} = $min
        if (defined($min));
}

sub apply_pfdata_max {
    my ($self, %options) = @_;

    my $pattern_pf;
    eval "\$pattern_pf = \"$options{args}->{pattern_pf}\"";
    my $max;
    for (my $i = 0; $i < scalar(@{$self->{perfdatas}}); $i++) {
        next if ($self->{perfdatas}->[$i]->{label} !~ /$pattern_pf/);
        next if ($self->{perfdatas}->[$i]->{value} !~ /\d+/);
        $max = $self->{perfdatas}->[$i]->{value}
            if (!defined($max) || $max < $self->{perfdatas}->[$i]->{value});
    }

    ${$options{perf}}->{value} = $max
        if (defined($max));
}

sub apply_pfdata_sum {
    my ($self, %options) = @_;

    my $pattern_pf;
    eval "\$pattern_pf = \"$options{args}->{pattern_pf}\"";
    my ($sum, $num) = (0, 0);
    for (my $i = 0; $i < scalar(@{$self->{perfdatas}}); $i++) {
        next if ($self->{perfdatas}->[$i]->{label} !~ /$pattern_pf/);
        next if ($self->{perfdatas}->[$i]->{value} !~ /\d+/);
        $sum += $self->{perfdatas}->[$i]->{value};
        $num++;
    }

    ${$options{perf}}->{value} = $sum
        if ($num > 0);
}

sub apply_pfdata_average {
    my ($self, %options) = @_;

    my $pattern_pf;
    eval "\$pattern_pf = \"$options{args}->{pattern_pf}\"";
    my ($sum, $num) = (0, 0);
    for (my $i = 0; $i < scalar(@{$self->{perfdatas}}); $i++) {
        next if ($self->{perfdatas}->[$i]->{label} !~ /$pattern_pf/);
        next if ($self->{perfdatas}->[$i]->{value} !~ /\d+/);
        $sum += $self->{perfdatas}->[$i]->{value};
        $num++;
    }

    ${$options{perf}}->{value} = sprintf("%.2f", ($sum / $num))
        if ($num > 0);
}

sub apply_perfdata_thresholds {
    my ($self, %options) = @_;

    foreach (('warning', 'critical')) {
        next if (!defined($options{$_}));

        my @thresholds = split(':', $options{$_}, -1);
        for (my $i = 0; $i < scalar(@thresholds); $i++) {
            if ($thresholds[$i] =~ /(\d+(?:\.\d+)?)\s*%/) {
                if (!defined($options{max}) || $options{max} eq '') {
                    $thresholds[$i] = '';
                    next;
                }
                $thresholds[$i] = $1 * $options{max} / 100;
            } elsif ($thresholds[$i] =~ /(\d+(?:\.\d+)?)/) {
                $thresholds[$i] = $1;
            } else {
                $thresholds[$i] = '';
            }
        }

        ${$options{perf}}->{$_} = join(':', @thresholds);
    }
}

sub load_perfdata_extend_args {
    my ($self, %options) = @_;

    foreach (
        [$self->{option_results}->{change_perfdata}, 1],
        [$self->{option_results}->{extend_perfdata}, 2],
        [$self->{option_results}->{extend_perfdata_group}, 3],
    ) {
        next if (!defined($_->[0]));
        foreach my $arg (@{$_->[0]}) {
            $self->parse_perfdata_extend_args(arg => $arg, type => $_->[1]);
        }
    }
}

sub parse_perfdata_extend_args {
    my ($self, %options) = @_;

    # --extend-perfdata=searchlabel,newlabel,method[,[newuom],[min],[max],[warning],[critical]]
    my ($pfdata_match, $pfdata_substitute, $method, $uom_sub, $min_sub, $max_sub, $warn_sub, $crit_sub) = 
        split /,/, $options{arg};
    return if ((!defined($pfdata_match) || $pfdata_match eq '') && $options{type} != 3);

    $self->{pfdata_extends} = [] if (!defined($self->{pfdata_extends}));
    my $pfdata_extends = {
        pfdata_match => defined($pfdata_match) && $pfdata_match ne '' ? $pfdata_match : undef,
        pfdata_substitute => defined($pfdata_substitute) && $pfdata_substitute ne '' ? $pfdata_substitute : undef,
        uom_sub => defined($uom_sub) && $uom_sub ne '' ? $uom_sub : undef,
        min_sub => defined($min_sub) && $min_sub ne '' ? $min_sub : undef,
        max_sub => defined($max_sub) && $max_sub ne '' ? $max_sub : undef,
        warn_sub => defined($warn_sub) && $warn_sub ne '' ? $warn_sub : undef,
        crit_sub => defined($crit_sub) && $crit_sub ne '' ? $crit_sub : undef,
        type => $options{type}
    };

    if (defined($method) && $method ne '') {
        if ($method !~ /^\s*(invert|percent|scale|math|min|max|average|sum)\s*\(\s*(.*?)\s*\)\s*$/) {
            $self->output_add(long_msg => "method in argument '$options{arg}' is unknown", debug => 1);
            return ;
        }

        $pfdata_extends->{method_name} = $1;
        my $args = $2;
        if (my $func = $self->can('parse_pfdata_' . $pfdata_extends->{method_name})) {
            (my $status, $pfdata_extends->{method_args}) = $func->($self, args => $args);
            if ($status == 1) {
                $self->output_add(long_msg => "argument in method '$options{arg}' is unknown", debug => 1);
                return ;
            }
        }
    }

    push  @{$self->{pfdata_extends}}, $pfdata_extends;
}

sub apply_perfdata_explode {
    my ($self, %options) = @_;

    return if ($self->{explode_perfdata_total} == 0);
    foreach (@{$self->{perfdatas}}) {
        next if ($_->{max} eq '');
        if ($self->{explode_perfdata_total} == 2) {
            $self->perfdata_add(label => $_->{label} . '_max', value => $_->{max}, unit => $_->{unit});
            next;
        }
        foreach my $regexp (keys %{$self->{explode_perfdatas}}) {
            if ($_->{label} =~ /$regexp/) {
                $self->perfdata_add(label => $self->{explode_perfdatas}->{$regexp}, value => $_->{max}, unit => $_->{unit});
                last;
            }
        }
    }
}

sub apply_perfdata_extend {
    my ($self, %options) = @_;

    foreach my $extend (@{$self->{pfdata_extends}}) {
        my $new_pfdata = [];

        # Manage special case when type group and pfdata_match empty
        if ($extend->{type} == 3 && (!defined($extend->{pfdata_match}) || $extend->{pfdata_match} eq '')) {
            next if (!defined($extend->{pfdata_substitute}) || $extend->{pfdata_substitute} eq '');
            my $new_perf = {
                label => $extend->{pfdata_substitute}, value => '',
                unit => defined($extend->{uom_sub}) ? $extend->{uom_sub} : '',
                warning => '', critical => '',
                min => defined($extend->{min_sub}) ? $extend->{min_sub} : '',
                max => defined($extend->{max_sub}) ? $extend->{max_sub} : ''
            };

            if (defined($extend->{method_name})) {
                my $func = $self->can('apply_pfdata_' . $extend->{method_name});
                $func->($self, perf => \$new_perf, args => $extend->{method_args});
            }

            $self->apply_perfdata_thresholds(
                perf => \$new_perf,
                warning => $extend->{warn_sub},
                critical => $extend->{crit_sub},
                max => $new_perf->{max}
            );
            if (length($new_perf->{value})) {
                push @{$self->{perfdatas}}, $new_perf;
            }
            next;
        }

        for (my $i = 0; $i < scalar(@{$self->{perfdatas}}); $i++) {
            next if ($self->{perfdatas}->[$i]->{label} !~ /$extend->{pfdata_match}/);

            my $new_perf = { %{$self->{perfdatas}->[$i]} };
            if ($extend->{type} == 3) {
                $new_perf = { label => $self->{perfdatas}->[$i]->{label}, value => '', unit => '', warning => '', critical => '', min => '', max => '' };
            }

            if (defined($extend->{pfdata_substitute})) {
                eval "\$new_perf->{label} =~ s{$extend->{pfdata_match}}{$extend->{pfdata_substitute}}";
            }

            if (defined($extend->{method_name})) {
                my $func = $self->can('apply_pfdata_' . $extend->{method_name});
                $func->($self, perf => \$new_perf, args => $extend->{method_args});
            }

            $new_perf->{unit} = $extend->{uom_sub} if (defined($extend->{uom_sub}));
            $new_perf->{min} = $extend->{min_sub} if (defined($extend->{min_sub}));
            $new_perf->{max} = $extend->{max_sub} if (defined($extend->{max_sub}));
            $self->apply_perfdata_thresholds(
                perf => \$new_perf,
                warning => $extend->{warn_sub},
                critical => $extend->{crit_sub},
                max => $new_perf->{max}
            );

            if ($extend->{type} == 1) {
                $self->{perfdatas}->[$i] = $new_perf;
            } else {
                push @$new_pfdata, $new_perf if (length($new_perf->{value}));
            }
        }

        push @{$self->{perfdatas}}, @$new_pfdata;
    }
}

sub change_perfdata {
    my ($self, %options) = @_;

    $self->apply_perfdata_extend();
    $self->apply_perfdata_explode();
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

=item B<--change-perfdata> B<--extend-perfdata> 

Change or extend perfdata. 
Syntax: --extend-perfdata=searchlabel,newlabel,target[,[newuom],[min],[max]]

Common examples:

=over 4

Change storage free perfdata in used: --change-perfdata=free,used,invert()

Change storage free perfdata in used: --change-perfdata=used,free,invert()

Scale traffic values automaticaly: --change-perfdata=traffic,,scale(auto)

Scale traffic values in Mbps: --change-perfdata=traffic_in,,scale(Mbps),mbps

Change traffic values in percent: --change-perfdata=traffic_in,,percent()

=back

=item B<--extend-perfdata-group> 

Extend perfdata from multiple perfdatas (methods in target are: min, max, average, sum)
Syntax: --extend-perfdata-group=searchlabel,newlabel,target[,[newuom],[min],[max]]

Common examples:

=over 4

Sum wrong packets from all interfaces (with interface need  --units-errors=absolute): --extend-perfdata-group=',packets_wrong,sum(packets_(discard|error)_(in|out))'

Sum traffic by interface: --extend-perfdata-group='traffic_in_(.*),traffic_$1,sum(traffic_(in|out)_$1)'

=back

=item B<--change-short-output>

Change short output display. --change-short-output=pattern~replace~modifier

=item B<--range-perfdata>

Change perfdata range thresholds display: 
1 = start value equals to '0' is removed, 2 = threshold range is not display.

=item B<--filter-uom>

Filter UOM that match the regexp.

=item B<--opt-exit>

Optional exit code for an execution error (i.e. wrong option provided,
SSH connection refused, timeout, etc)
(Default: unknown).

=item B<--output-ignore-perfdata>

Remove perfdata from output.

=item B<--output-ignore-label>

Remove label status from output.

=item B<--output-xml>

Display output in XML format.

=item B<--output-json>

Display output in JSON format.

=item B<--output-openmetrics>

Display metrics in OpenMetrics format.

=item B<--output-file>

Write output in file (can be used with json and xml options)

=item B<--disco-format>

Display discovery arguments (if the mode manages it).

=item B<--disco-show>

Display discovery values (if the mode manages it).

=item B<--float-precision>

Set the float precision for thresholds (Default: 8).

=item B<--source-encoding>

Set encoding of monitoring sources (In some case. Default: 'UTF-8').

=head1 DESCRIPTION

B<output>.

=cut
