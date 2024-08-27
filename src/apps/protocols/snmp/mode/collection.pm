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

package apps::protocols::snmp::mode::collection;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use Safe;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub custom_select_threshold {
    my ($self, %options) = @_;

    my $status = 'ok';
    our $expand = $self->{result_values}->{expand};
    if (defined($self->{result_values}->{config}->{critical}) && $self->{result_values}->{config}->{critical} &&
        $self->{instance_mode}->{safe}->reval($self->{result_values}->{config}->{critical})) {
        $status = 'critical';
    } elsif (defined($self->{result_values}->{config}->{warning}) && $self->{result_values}->{config}->{warning} ne '' &&
        $self->{instance_mode}->{safe}->reval($self->{result_values}->{config}->{warning})) {
        $status = 'warning';
    } elsif (defined($self->{result_values}->{config}->{unknown}) && $self->{result_values}->{config}->{unknown} &&
        $self->{instance_mode}->reval($self->{result_values}->{config}->{unknown})) {
        $status = 'unknown';
    }
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Unsafe code evaluation: ' . $@);
        $self->{output}->option_exit();
    }

    $self->{result_values}->{last_status} = $status;
    return $status;
}

sub custom_select_perfdata {
    my ($self, %options) = @_;

    return if (!defined($self->{result_values}->{config}->{perfdatas}));
    foreach (@{$self->{result_values}->{config}->{perfdatas}}) {
        next if (!defined($_->{value}) || $_->{value} !~ /^[+-]?\d+(?:\.\d+)?$/);
        $self->{output}->perfdata_add(%$_);
    }
}

sub custom_select_output {
    my ($self, %options) = @_;

    return '' if (
        $self->{result_values}->{last_status} eq 'ok' && defined($self->{result_values}->{config}->{formatting}) &&
        defined($self->{result_values}->{config}->{formatting}->{display_ok}) &&
        $self->{result_values}->{config}->{formatting}->{display_ok} =~ /^false|0$/
    );

    my $format;
    if (defined($self->{result_values}->{config}->{ 'formatting_' . $self->{result_values}->{last_status} })) {
        $format = $self->{result_values}->{config}->{ 'formatting_' . $self->{result_values}->{last_status} };
    } elsif (defined($self->{result_values}->{config}->{formatting})) {
        $format = $self->{result_values}->{config}->{formatting};
    }

    if (defined($format)) {
        return sprintf(
            $format->{printf_msg}, @{$format->{printf_var}} 
        );
    }

    # without formatting: [name: xxxxxx][test: xxxx][test2: xxx][mytable.plcRead: xxx][mytable.plcWrite: xxx]
    my $output = '';
    foreach (sort keys %{$self->{result_values}->{expand}}) {
        next if (/^(?:constants|builtin)\./);
        $output .= '[' . $_ . ': ' . $self->{result_values}->{expand}->{$_} . ']';
    }

    return $output;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'selections', type => 1, message_multiple => 'All selections are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{selections} = [
        { label => 'select', threshold => 0, set => {
                key_values => [ { name => 'expand' }, { name => 'config' } ],
                closure_custom_output => $self->can('custom_select_output'),
                closure_custom_perfdata => $self->can('custom_select_perfdata'),
                closure_custom_threshold_check => $self->can('custom_select_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'config:s'            => { name => 'config' },
        'filter-selection:s%' => { name => 'filter_selection' },
        'constant:s%'         => { name => 'constant' }
    });

    $self->{safe} = Safe->new();
    $self->{safe}->share('$expand');

    $self->{safe_func} = Safe->new();
    $self->{safe_func}->share('$assign_var');

    $self->{builtin} = {};

    $self->{snmp_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{config})) {
        $self->{output}->add_option_msg(short_msg => 'Please set config option');
        $self->{output}->option_exit();
    }
    $self->{snmp_cache}->check_options(option_results => $self->{option_results});
}

sub read_config {
    my ($self, %options) = @_;

    my $content;
    if ($self->{option_results}->{config} =~ /\n/m || ! -f "$self->{option_results}->{config}") {
        $content = $self->{option_results}->{config};
    } else {
        $content = do {
            local $/ = undef;
            if (!open my $fh, '<', $self->{option_results}->{config}) {
                $self->{output}->add_option_msg(short_msg => "Could not open file $self->{option_results}->{config} : $!");
                $self->{output}->option_exit();
            }
            <$fh>;
        };
    }

    eval {
        $self->{config} = JSON::XS->new->decode($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => "json config error: $@", debug => 1);
        $self->{output}->add_option_msg(short_msg => 'Cannot decode json config');
        $self->{output}->option_exit();
    }
}

sub get_map_value {
    my ($self, %options) = @_;

    return undef if (
        !defined($self->{config}->{mapping}) || 
        !defined($self->{config}->{mapping}->{ $options{map} })
    );
    return '' if (!defined($self->{config}->{mapping}->{ $options{map} }->{ $options{value} }));
    return $self->{config}->{mapping}->{ $options{map} }->{ $options{value} };
}

sub validate_name {
    my ($self, %options) = @_;

    if (!defined($options{name})) {
        $self->{output}->add_option_msg(short_msg => "name attribute is missing $options{section}");
        $self->{output}->option_exit();
    }
    if ($options{name} !~ /^[a-zA-Z0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => 'incorrect name attribute: ' . $options{name});
        $self->{output}->option_exit();
    }
}

sub collect_snmp_tables {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{snmp}->{tables}));
    foreach my $table (@{$self->{config}->{snmp}->{tables}}) {
        $self->validate_name(name => $table->{name}, section => "[snmp > tables]");
        if (!defined($table->{oid}) || $table->{oid} eq '') {
            $self->{output}->add_option_msg(short_msg => "oid attribute is missing [snmp > tables > $table->{name}]");
            $self->{output}->option_exit();
        }
        if (!defined($table->{entries})) {
            $self->{output}->add_option_msg(short_msg => "entries section is missing [snmp > tables > $table->{name}]");
            $self->{output}->option_exit();
        }

        my $mapping = {};
        my $sampling = {};
        foreach (@{$table->{entries}}) {
            $self->validate_name(name => $_->{name}, section => "[snmp > tables > $table->{name}]");
            if (!defined($_->{oid}) || $_->{oid} eq '') {
                $self->{output}->add_option_msg(short_msg => "oid attribute is missing [snmp > tables > $table->{name} >  $_->{name}]");
                $self->{output}->option_exit();
            }
            $mapping->{ $_->{name} } = { oid => $_->{oid} };
            $sampling->{ $_->{name} } = 1 if (defined($_->{sampling}) && $_->{sampling} == 1);
            if (defined($_->{map}) && $_->{map} ne '') {
                if (!defined($self->{config}->{mapping}) || !defined($self->{config}->{mapping}->{ $_->{map} })) {
                    $self->{output}->add_option_msg(short_msg => "unknown map attribute [snmp > tables > $table->{name} > $_->{name}]: $_->{map}");
                    $self->{output}->option_exit();
                }
                $mapping->{ $_->{name} }->{map} = $self->{config}->{mapping}->{ $_->{map} };
            }
        }

        if (scalar(keys %$mapping) <= 0) {
            $self->{output}->add_option_msg(short_msg => "entries section is empty [snmp > tables > $table->{name}]");
            $self->{output}->option_exit();
        }

        $self->{snmp_collected}->{tables}->{ $table->{name} } = {};
        my $used_instance = defined($table->{used_instance}) && $table->{used_instance} ne '' ? $table->{used_instance} : '\.(\d+)$';
        my $snmp_result = $options{snmp}->get_table(oid => $table->{oid});
        foreach (keys %$snmp_result) {
            /$used_instance/ or next;
            next if (defined($self->{snmp_collected}->{tables}->{ $table->{name} }->{$1}));
            my $instance = $1;
    
            $self->{snmp_collected}->{tables}->{ $table->{name} }->{$instance} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
            foreach my $sample_name (keys %$sampling) {
                $self->{snmp_collected_sampling}->{tables}->{ $table->{name} } = {}
                    if (!defined($self->{snmp_collected_sampling}->{tables}->{ $table->{name} }));
                $self->{snmp_collected_sampling}->{tables}->{ $table->{name} }->{$instance}->{$sample_name} = 
                    $self->{snmp_collected}->{tables}->{ $table->{name} }->{$instance}->{$sample_name};
            }

            if (defined($table->{instance_entries})) {
                my @matches = ($_ =~ /$table->{instance_entries}->{re}/);
                foreach my $entry (@{$table->{instance_entries}->{entries}}) {
                    next if ($entry->{capture} !~ /^[0-9]+$/);
                    
                    my $value = '';
                    if (defined($matches[ $entry->{capture} - 1])) {
                        $value = $matches[ $entry->{capture} - 1];
                    }

                    $self->{snmp_collected}->{tables}->{ $table->{name} }->{$instance}->{ $entry->{name} } = $value;
                }
            }
        }
    }
}

sub collect_snmp_leefs {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{snmp}->{leefs}));
    my $oids = [ map($_->{oid}, @{$self->{config}->{snmp}->{leefs}}) ];
    return if (scalar(@$oids) <= 0);

    my $snmp_result = $options{snmp}->get_leef(oids => $oids);
    foreach (@{$self->{config}->{snmp}->{leefs}}) {
        $self->validate_name(name => $_->{name}, section => "[snmp > leefs]");
        $self->{snmp_collected}->{leefs}->{ $_->{name} } = defined($_->{default}) ? $_->{default} : '';
        next if (!defined($_->{oid}) || !defined($snmp_result->{ $_->{oid } }));
        $self->{snmp_collected}->{leefs}->{ $_->{name} } = $snmp_result->{ $_->{oid } };
        if (defined($_->{sampling}) && $_->{sampling} == 1) {
            $self->{snmp_collected_sampling}->{leefs}->{ $_->{name} } = $snmp_result->{ $_->{oid } };
        }

        if (defined($_->{map}) && $_->{map} ne '') {
            my $value = $self->get_map_value(value => $snmp_result->{ $_->{oid } }, map => $_->{map});
            if (!defined($value)) {
                $self->{output}->add_option_msg(short_msg => "unknown map attribute [snmp > leefs > $_->{name}]: $_->{map}");
                $self->{output}->option_exit();
            }
            $self->{snmp_collected}->{leefs}->{ $_->{name} } = $value;
        }
    }
}

sub is_snmp_cache_enabled {
    my ($self, %options) = @_;

    return 0 if (
        !defined($self->{config}->{snmp}->{cache}) || 
        !defined($self->{config}->{snmp}->{cache}->{enable}) ||
        $self->{config}->{snmp}->{cache}->{enable} !~ /^true|1$/i
    );

    return 1;
}

sub use_snmp_cache {
    my ($self, %options) = @_;

    return 0 if ($self->is_snmp_cache_enabled() == 0);

    my $has_cache_file = $self->{snmp_cache}->read(
        statefile => 'cache_snmp_collection_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
            md5_hex($self->{option_results}->{config}) 
    );
    $self->{snmp_collected} = $self->{snmp_cache}->get(name => 'snmp_collected');
    my $reload = defined($self->{config}->{snmp}->{cache}->{reload}) && $self->{config}->{snmp}->{cache}->{reload} =~ /(\d+)/ ? 
        $self->{config}->{snmp}->{cache}->{reload} : 30;
    return 0 if (
        $has_cache_file == 0 || 
        !defined($self->{snmp_collected}) || 
        ((time() - $self->{snmp_collected}->{epoch}) > ($reload * 60))
    );

    return 1;
}

sub save_snmp_cache {
    my ($self, %options) = @_;

    return 0 if ($self->is_snmp_cache_enabled() == 0);
    $self->{snmp_cache}->write(data => { snmp_collected => $self->{snmp_collected} });
}

sub collect_snmp_sampling {
    my ($self, %options) = @_;

    return if ($self->{snmp_collected}->{sampling} == 0);

    my $has_cache_file = $self->{snmp_cache}->read(
        statefile => 'cache_snmp_collection_sampling_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
            md5_hex($self->{option_results}->{config})
    );
    my $snmp_collected_sampling_old = $self->{snmp_cache}->get(name => 'snmp_collected_sampling');
    # with cache, we need to load the sampling cache maybe. please a statefile-suffix to get uniq files.
    # sampling with a global cache can be a nonsense
    if (!defined($self->{snmp_collected_sampling})) {
        $self->{snmp_collected_sampling} = $snmp_collected_sampling_old;
    }

    my $delta_time;
    if (defined($snmp_collected_sampling_old->{epoch})) {
        $delta_time = $self->{snmp_collected_sampling}->{epoch} - $snmp_collected_sampling_old->{epoch};
        $delta_time = 1 if ($delta_time <= 0);
    }

    foreach (keys %{$self->{snmp_collected_sampling}->{leefs}}) {
        next if (!defined($snmp_collected_sampling_old->{leefs}->{$_}) || $snmp_collected_sampling_old->{leefs}->{$_} !~ /\d/);
        my $old = $snmp_collected_sampling_old->{leefs}->{$_};
        my $diff = $self->{snmp_collected_sampling}->{leefs}->{$_} - $old;
        my $diff_counter = $diff;
        $diff_counter = $self->{snmp_collected_sampling}->{leefs}->{$_} if ($diff_counter < 0);

        $self->{snmp_collected}->{leefs}->{ $_ . 'Diff' } = $diff;
        $self->{snmp_collected}->{leefs}->{ $_ . 'DiffCounter' } = $diff_counter;
        if (defined($delta_time)) {
            $self->{snmp_collected}->{leefs}->{ $_ . 'PerSeconds' } = $diff_counter / $delta_time;
            $self->{snmp_collected}->{leefs}->{ $_ . 'PerMinutes' } = $diff_counter / $delta_time / 60;
        }
    }

    foreach my $tbl_name (keys %{$self->{snmp_collected_sampling}->{tables}}) {
        foreach my $instance (keys %{$self->{snmp_collected_sampling}->{tables}->{$tbl_name}}) {
            foreach my $attr (keys %{$self->{snmp_collected_sampling}->{tables}->{$tbl_name}->{$instance}}) {
                next if (
                    !defined($snmp_collected_sampling_old->{tables}->{$tbl_name}) ||
                    !defined($snmp_collected_sampling_old->{tables}->{$tbl_name}->{$instance}) ||
                    !defined($snmp_collected_sampling_old->{tables}->{$tbl_name}->{$instance}->{$attr}) ||
                    $snmp_collected_sampling_old->{tables}->{$tbl_name}->{$instance}->{$attr} !~ /\d/
                );
                my $old = $snmp_collected_sampling_old->{tables}->{$tbl_name}->{$instance}->{$attr};
                my $diff = $self->{snmp_collected_sampling}->{tables}->{$tbl_name}->{$instance}->{$attr} - $old;
                my $diff_counter = $diff;
                $diff_counter = $self->{snmp_collected_sampling}->{tables}->{$tbl_name}->{$instance}->{$attr} if ($diff_counter < 0);

                $self->{snmp_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'Diff' } = $diff;
                $self->{snmp_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'DiffCounter' } = $diff_counter;
                if (defined($delta_time)) {
                    $self->{snmp_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'PerSeconds' } = $diff_counter / $delta_time;
                    $self->{snmp_collected}->{tables}->{$tbl_name}->{$instance}->{ $attr . 'PerMinutes' } = $diff_counter / $delta_time / 60;
                }
            }
        }
    }

    $self->{snmp_cache}->write(data => { snmp_collected_sampling => $self->{snmp_collected_sampling} });
}

sub display_variables {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => '======> variables', debug => 1);
    foreach my $tbl_name (keys %{$self->{snmp_collected}->{tables}}) {
        my $expr = 'snmp.tables.' . $tbl_name;
        foreach my $instance (keys %{$self->{snmp_collected}->{tables}->{$tbl_name}}) {
            foreach my $attr (keys %{$self->{snmp_collected}->{tables}->{$tbl_name}->{$instance}}) {
                $self->{output}->output_add(
                    long_msg => sprintf(
                        '    %s = %s',
                        $expr . ".[$instance].$attr",
                        $self->{snmp_collected}->{tables}->{$tbl_name}->{$instance}->{$attr}
                    ),
                    debug => 1
                );
            }
        }
    }
}

sub collect_snmp {
    my ($self, %options) = @_;

    if (!defined($self->{config}->{snmp})) {
        $self->{output}->add_option_msg(short_msg => 'please set snmp config');
        $self->{output}->option_exit();
    }

    $self->add_builtin(name => 'currentTime', value => time());
    if ($self->use_snmp_cache(snmp => $options{snmp}) == 0) {
        $self->{snmp_collected_sampling} = { tables => {}, leefs => {}, epoch => time() };
        $self->{snmp_collected} = { tables => {}, leefs => {}, epoch => time(), sampling => 0 };

        $self->collect_snmp_tables(snmp => $options{snmp});
        $self->collect_snmp_leefs(snmp => $options{snmp});

        $self->{snmp_collected}->{sampling} = 1 if (
            scalar(keys(%{$self->{snmp_collected_sampling}->{tables}})) > 0 ||
            scalar(keys(%{$self->{snmp_collected_sampling}->{leefs}})) > 0
        );
        $self->save_snmp_cache();
    }

    $self->collect_snmp_sampling(snmp => $options{snmp});

    if ($self->{output}->is_debug()) {
        $self->display_variables();
    }
}



sub exist_table_name {
    my ($self, %options) = @_;

    return 1 if (defined($self->{snmp_collected}->{tables}->{ $options{name} }));
    return 0;
}

sub get_local_variable {
    my ($self, %options) = @_;

    return $self->{expand}->{ $options{name} };
}

sub set_local_variable {
    my ($self, %options) = @_;

    $self->{expand}->{ $options{name} } = $options{value};
}

sub get_leef_variable {
    my ($self, %options) = @_;

    return $self->{snmp_collected}->{leefs}->{ $options{name} };
}

sub set_leef_variable {
    my ($self, %options) = @_;

    $self->{snmp_collected}->{leefs}->{ $options{name} } = $options{value};
}

sub get_table {
    my ($self, %options) = @_;

    return undef if (
        !defined($self->{snmp_collected}->{tables}->{ $options{table} })
    );
    return $self->{snmp_collected}->{tables}->{ $options{table} };
}

sub get_table_instance {
    my ($self, %options) = @_;

    return undef if (
        !defined($self->{snmp_collected}->{tables}->{ $options{table} }) ||
        !defined($self->{snmp_collected}->{tables}->{ $options{table} }->{ $options{instance} })
    );
    return $self->{snmp_collected}->{tables}->{ $options{table} }->{ $options{instance} };
}

sub get_table_attribute_value {
    my ($self, %options) = @_;

    return undef if (
        !defined($self->{snmp_collected}->{tables}->{ $options{table} }) ||
        !defined($self->{snmp_collected}->{tables}->{ $options{table} }->{ $options{instance} }) ||
        !defined($self->{snmp_collected}->{tables}->{ $options{table} }->{ $options{instance} }->{ $options{attribute} })
    );
    return $self->{snmp_collected}->{tables}->{ $options{table} }->{ $options{instance} }->{ $options{attribute} };
}

sub set_table_attribute_value {
    my ($self, %options) = @_;

    $self->{snmp_collected}->{tables}->{ $options{table} } = {}
        if (!defined($self->{snmp_collected}->{tables}->{ $options{table} }));
    $self->{snmp_collected}->{tables}->{ $options{table} } = {}
        if (!defined($self->{snmp_collected}->{tables}->{ $options{table} }->{ $options{instance} }));
    $self->{snmp_collected}->{tables}->{ $options{table} }->{ $options{instance} }->{ $options{attribute} } = $options{value};
}

sub get_special_variable_value {
    my ($self, %options) = @_;

    my $data;
    if ($options{type} == 0) {
        $data = $self->get_local_variable(name => $options{label});
    } elsif ($options{type} == 1) {
        $data = $self->get_leef_variable(name => $options{label});
    } elsif ($options{type} == 2) {
        $data = $self->get_table(table => $options{table});
    } elsif ($options{type} == 4) {
        $data = $self->get_table_attribute_value(
            table => $options{table},
            instance => $options{instance},
            attribute => $options{label}
        );
    }

    return $data;
}

sub set_special_variable_value {
    my ($self, %options) = @_;

    my $data;
    if ($options{type} == 0) {
        $data = $self->set_local_variable(name => $options{label}, value => $options{value});
    } elsif ($options{type} == 1) {
        $data = $self->set_leef_variable(name => $options{label}, value => $options{value});
    } elsif ($options{type} == 4) {
        $data = $self->set_table_attribute_value(
            table => $options{table},
            instance => $options{instance},
            attribute => $options{label},
            value => $options{value}
        );
    }

    return $data;
}

sub strcmp {
    my ($self, %options) = @_;

    my @cmp = split //, $options{test};
    for (my $i = 0; $i < scalar(@cmp); $i++) {
        return 0 if (
            !defined($options{chars}->[ $options{start} + $i ]) ||
            $options{chars}->[ $options{start} + $i ] ne $cmp[$i]
        );
    }

    return 1;
}

sub parse_forward {
    my ($self, %options) = @_;

    my ($string, $i) = ('', 0);
    while (1) {
        return (1, 'cannot find ' . $options{stop} . ' character')
            if (!defined($options{chars}->[ $options{start} + $i ]));
        last if ($options{chars}->[ $options{start} + $i ] =~ /$options{stop}/);
        return (1, "character '" . $options{chars}->[ $options{start} + $i ] . "' forbidden")
            if ($options{chars}->[ $options{start} + $i ] !~ /$options{allowed}/);

        $string .= $options{chars}->[ $options{start} + $i ];
        $i++;
    }

    return (0, undef, $options{start} + $i, $string);
}

=pod
managed variables:
    %(snmp.tables.plcData)
    %(snmp.tables.plcData.[1])
    %(snmp.tables.plcOther.[1].plop)
    %(snmp.tables.plcOther.[%(mytable.instance)]
    %(snmp.tables.plcOther.[%(snmp.tables.plcOther.[%(mytable.instance)].test)]
    %(test2)
    %(mytable.test)

result:
    - type:
        0=%(test) (label)
        1=%(snmp.leefs.variable)
        2=%(snmp.tables.test)
        3=%(snmp.tables.test.[2])
        4=%(snmp.tables.test.[2].attrname)
=cut
sub parse_snmp_tables {
    my ($self, %options) = @_;

    my ($code, $msg_error, $end, $table_label, $instance_label, $label);
    ($code, $msg_error, $end, $table_label) = $self->parse_forward(
        chars => $options{chars},
        start => $options{start}, 
        allowed => '[a-zA-Z0-9]',
        stop => '[).]'
    );
    if ($code) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
        $self->{output}->option_exit();
    }
    if (!$self->exist_table_name(name => $table_label)) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " unknown table '$table_label'");
        $self->{output}->option_exit();
    }
    if ($options{chars}->[$end] eq ')') {
        return { type => 2, end => $end, table => $table_label };
    }

    # instance part managenent
    if (!defined($options{chars}->[$end + 1]) || $options{chars}->[$end + 1] ne '[') {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable snmp.tables character '[' mandatory");
        $self->{output}->option_exit();
    }
    if ($self->strcmp(chars => $options{chars}, start => $end + 2, test => '%(')) {
        my $result = $self->parse_special_variable(chars => $options{chars}, start => $end + 2);
        # type allowed: 0,1,4
        if ($result->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable type not allowed');
            $self->{output}->option_exit();
        }
        $end = $result->{end} + 1;
        if ($result->{type} == 0) {
            $instance_label = $self->get_local_variable(name => $result->{label});
        } elsif ($result->{type} == 1) {
            $instance_label = $self->get_leef_variable(name => $result->{label});
        } elsif ($result->{type} == 4) {
            $instance_label = $self->get_table_attribute_value(
                table => $result->{table},
                instance => $result->{instance},
                attribute => $result->{label}
            );
        }
        $instance_label = defined($instance_label) ? $instance_label : '';
    } else {
        ($code, $msg_error, $end, $instance_label) = $self->parse_forward(
            chars => $options{chars},
            start => $end + 2, 
            allowed => '[0-9\.]',
            stop => '[\]]'
        );
        if ($code) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
            $self->{output}->option_exit();
        }
    }

    if (!defined($options{chars}->[$end + 1]) ||
        $options{chars}->[$end + 1] !~ /[.)]/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable snmp.tables character [.)] missing');
        $self->{output}->option_exit();
    }

    if ($options{chars}->[$end + 1] eq ')') {
        return { type => 3, end => $end + 1, table => $table_label, instance => $instance_label };
    }

    ($code, $msg_error, $end, $label) = $self->parse_forward(
        chars => $options{chars},
        start => $end + 2,
        allowed => '[a-zA-Z0-9]',
        stop => '[)]'
    );
    if ($code) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
        $self->{output}->option_exit();
    }

    return { type => 4, end => $end, table => $table_label, instance => $instance_label, label => $label };
}

sub parse_snmp_type {
    my ($self, %options) = @_;

    if ($self->strcmp(chars => $options{chars}, start => $options{start}, test => 'leefs.')) {
        my ($code, $msg_error, $end, $label) = $self->parse_forward(
            chars => $options{chars},
            start => $options{start} + 6,
            allowed => '[a-zA-Z0-9]',
            stop => '[)]'
        );
        if ($code) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
            $self->{output}->option_exit();
        }
        return { type => 1, end => $end, label => $label };
    } elsif ($self->strcmp(chars => $options{chars}, start => $options{start}, test => 'tables.')) {
        return $self->parse_snmp_tables(chars => $options{chars}, start => $options{start} + 7);
    } else {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable snmp not followed by leefs/tables');
        $self->{output}->option_exit();
    }
}

sub parse_special_variable {
    my ($self, %options) = @_;

    my $start = $options{start};
    if ($options{chars}->[$start] ne '%' || 
        $options{chars}->[$start + 1] ne '(') {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . ' special variable not starting by %(');
        $self->{output}->option_exit();
    }

    my $result = { start => $options{start} };
    if ($self->strcmp(chars => $options{chars}, start => $start + 2, test => 'snmp.')) {
        my $parse = $self->parse_snmp_type(chars => $options{chars}, start => $start + 2 + 5);
        $result = { %$parse, %$result };
    } else {
        my ($code, $msg_error, $end, $label) = $self->parse_forward(
            chars => $options{chars},
            start => $start + 2, 
            allowed => '[a-zA-Z0-9.]',
            stop => '[)]'
        );
        if ($code) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " $msg_error");
            $self->{output}->option_exit();
        }
        $result->{end} = $end;
        $result->{type} = 0;
        $result->{label} = $label;
    }

    return $result;
}

sub substitute_string {
    my ($self, %options) = @_;

    my $arr = [split //, $options{value}];
    my $results = {};
    my $last_end = -1;
    while ($options{value} =~ /\Q%(\E/g) {
        next if ($-[0] < $last_end);
        my $result = $self->parse_special_variable(chars => $arr, start => $-[0]);
        if ($result->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed");
            $self->{output}->option_exit();
        }
        $last_end = $result->{end};
        $results->{ $result->{start} } = $result;
    }

    my $end = -1;
    my $str = '';
    for (my $i = 0; $i < scalar(@$arr); $i++) {
        next if ($i <= $end);
        if (defined($results->{$i})) {
            my $data = $self->get_special_variable_value(%{$results->{$i}});
            $end = $results->{$i}->{end};
            $str .= defined($data) ? $data : '';
        } else {
            $str .= $arr->[$i];
        }
    }

    return $str;
}

sub add_builtin {
    my ($self, %options) = @_;

    $self->{builtin}->{ $options{name} } = $options{value};
}

sub set_builtin {
    my ($self, %options) = @_;

    foreach (keys %{$self->{builtin}}) {
        $self->{expand}->{ 'builtin.' . $_ } = $self->{builtin}->{$_};
    }
}

sub set_constants {
    my ($self, %options) = @_;

    my $constants = {};
    if (defined($self->{config}->{constants})) {
        foreach (keys %{$self->{config}->{constants}}) {
            $constants->{'constants.' . $_} = $self->{config}->{constants}->{$_};
        }
    }
    foreach (keys %{$self->{option_results}->{constant}}) {
        $constants->{'constants.' . $_} = $self->{option_results}->{constant}->{$_};
    }

    return $constants;
}

sub set_expand_table {
    my ($self, %options) = @_;

    return if (!defined($options{expand}));
    foreach my $name (keys %{$options{expand}}) {
        $self->{current_section} = '[' . $options{section} . ' > ' . $name . ']';
        my $result = $self->parse_special_variable(chars => [split //, $options{expand}->{$name}], start => 0);
        if ($result->{type} != 3) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed");
            $self->{output}->option_exit();
        }
        my $table = $self->get_table_instance(table => $result->{table}, instance => $result->{instance});
        next if (!defined($table));

        $self->{expand}->{ $name . '.instance' } = $result->{instance};
        foreach (keys %$table) {
            $self->{expand}->{ $name . '.' . $_ } = $table->{$_};
        }
    }
}

sub set_expand {
    my ($self, %options) = @_;

    return if (!defined($options{expand}));
    foreach my $name (keys %{$options{expand}}) {
        $self->{current_section} = '[' . $options{section} . ' > ' . $name . ']';
        $self->{expand}->{$name} = $self->substitute_string(value => $options{expand}->{$name});
    }
}

sub exec_func_map {
    my ($self, %options) = @_;

    if (!defined($options{map_name}) || $options{map_name} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set map_name attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my $value = $self->get_map_value(value => $data, map => $options{map_name});
    if (!defined($value)) {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} unknown map attribute: $options{map_name}");
        $self->{output}->option_exit();
    }
    my $save = $result;
    if (defined($options{save}) && $options{save} ne '') {
        $save = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($save->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
    } elsif (defined($options{dst}) && $options{dst} ne '') {
        $save = $self->parse_special_variable(chars => [split //, $options{dst}], start => 0);
        if ($save->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in dst attribute");
            $self->{output}->option_exit();
        }
    }

    $self->set_special_variable_value(value => $value, %$save);
}

sub scale {
    my ($self, %options) = @_;

    my ($src_quantity, $src_unit) = (undef, 'B');
    if ($options{src_unit} =~ /([kmgtpe])?(b)/i) {
        $src_quantity = $1;
        $src_unit = $2;
    }
    my ($dst_quantity, $dst_unit) = ('auto', $src_unit);
    if ($options{dst_unit} =~ /([kmgtpe])?(b)/i) {
        $dst_quantity = $1;
        $dst_unit = $2;
    }

    my $base = 1024;
    $options{value} *= 8 if ($dst_unit eq 'b' && $src_unit eq 'B');
    $options{value} /= 8 if ($dst_unit eq 'B' && $src_unit eq 'b');
    $base = 1000 if ($dst_unit eq 'b');

    my %expo = (k => 1, m => 2, g => 3, t => 4, p => 5, e => 6);
    my $src_expo = 0;
    $src_expo = $expo{ lc($src_quantity) } if (defined($src_quantity));

    if (defined($dst_quantity) && $dst_quantity eq 'auto') {
        my @auto = ('', 'k', 'm', 'g', 't', 'p', 'e');
        for (; $src_expo < scalar(@auto); $src_expo++) {
            last if ($options{value} < $base);
            $options{value} = $options{value} / $base;
        }

        return ($options{value}, uc($auto[$src_expo]) . $dst_unit);
    }

    my $dst_expo = 0;
    $dst_expo = $expo{ lc($dst_quantity) } if (defined($dst_quantity));
    if ($dst_expo - $src_expo > 0) {
        $options{value} = $options{value} / ($base ** ($dst_expo - $src_expo));
    } elsif ($dst_expo - $src_expo < 0) {
        $options{value} = $options{value} * ($base ** (($dst_expo - $src_expo) * -1));
    }

    return ($options{value}, $options{dst_unit});
}

sub exec_func_scale {
    my ($self, %options) = @_;

    #{
    #    "type": "scale",
    #    "src": "%(memoryUsed)",
    #    "src_unit": "KB", (default: 'B')
    #    "dst_unit": "auto", (default: 'auto')
    #    "save_value": "%(memoryUsedScaled)",
    #    "save_unit": "%(memoryUsedUnit)"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my ($save_value, $save_unit) = $self->scale(
        value => $data,
        src_unit => $options{src_unit},
        dst_unit => $options{dst_unit}
    );

    if (defined($options{save_value}) && $options{save_value} ne '') {
        my $var_save_value = $self->parse_special_variable(chars => [split //, $options{save_value}], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_value attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $save_value, %$var_save_value);
    }
    if (defined($options{save_unit}) && $options{save_unit} ne '') {
        my $var_save_unit = $self->parse_special_variable(chars => [split //, $options{save_unit}], start => 0);
        if ($var_save_unit->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_value attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $save_unit, %$var_save_unit);
    }
}

sub exec_func_second2human {
    my ($self, %options) = @_;

    #{
    #    "type": "second2human",
    #    "src": "%(duration)",
    #    "save_value": "%(humanDuration)",
    #    "start": "d",
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my ($str, $str_append) = ('', '');
    my $periods = [
        { unit => 'y', value => 31556926 },
        { unit => 'M', value => 2629743 },
        { unit => 'w', value => 604800 },
        { unit => 'd', value => 86400 },
        { unit => 'h', value => 3600 },
        { unit => 'm', value => 60 },
        { unit => 's', value => 1 },
    ];
    my %values = ('y' => 1, 'M' => 2, 'w' => 3, 'd' => 4, 'h' => 5, 'm' => 6, 's' => 7);
    my $sign = '';
    if ($data < 0) {
        $sign = '-';
        $data = abs($data);
    }
    
    foreach (@$periods) {
        next if (defined($options{start}) && $values{$_->{unit}} < $values{$options{start}});
        my $count = int($data / $_->{value});

        next if ($count == 0);
        $str .= $str_append . $count . $_->{unit};
        $data = $data % $_->{value};
        $str_append = ' ';
    }

    if ($str eq '') {
        $str = $data;
        $str .= $options{start} if (defined($options{start}));
    }

    if (defined($options{save_value}) && $options{save_value} ne '') {
        my $var_save_value = $self->parse_special_variable(chars => [split //, $options{save_value}], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_value attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $sign . $str, %$var_save_value);
    }
}

sub exec_func_date2epoch {
    my ($self, %options) = @_;

    if (!defined($self->{module_datetime_loaded})) {
        centreon::plugins::misc::mymodule_load(
            module => 'DateTime',
            error_msg => "Cannot load module 'DateTime'."
        );
        $self->{module_datetime_loaded} = 1;
    }

    #{
    #   "type": "date2epoch",
    #   "src": "%(dateTest)",
    #   "format": "DateAndTime",
    #   "timezone": "Europe/Paris",
    #   "save_epoch": "%(plopDateEpoch)",
    #   "save_diff1": "%(plopDateDiff1)",
    #   "save_diff2": "%(plopDateDiff2)"
    #},
    #{
    #   "type": "date2epoch",
    #   "src": "%(dateTest2)",
    #   "format_custom": "(\\d+)-(\\d+)-(\\d+)",
    #   "year": 1,
    #   "month": 2,
    #   "day": 3,
    #   "timezone": "Europe/Paris"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);

    my $tz = {};
    $tz->{time_zone} = $options{timezone} if (defined($options{timezone}) && $options{timezone} ne '');
    my $dt;
    if (defined($options{format}) && lc($options{format}) eq 'dateandtime') {
        my @date = unpack('n C6 a C2', $data);
        my $timezone;
        if (defined($date[7]) && !defined($tz->{time_zone})) {
            $tz->{time_zone} = sprintf('%s%02d%02d', $date[7], $date[8], $date[9]);
        }
        $dt = DateTime->new(
            year => $date[0],
            month => $date[1],
            day => $date[2],
            hour => $date[3],
            minute => $date[4],
            second => $date[5],
            %$tz
        );
    } elsif (defined($options{format_custom}) && $options{format_custom} ne '') {
        my @matches = ($data =~ /$options{format_custom}/);
        my $date = {};
        foreach (('year', 'month', 'day', 'hour', 'minute', 'second')) {
            $date->{$_} = $matches[ $options{$_} -1 ]
                if (defined($options{$_}) && $options{$_} =~ /^\d+$/ && defined($matches[ $options{$_} -1 ]));
        }

        foreach (('year', 'month', 'day')) {
            if (!defined($date->{$_})) {
                $self->{output}->add_option_msg(short_msg => "$self->{current_section} cannot find $_ attribute");
                $self->{output}->option_exit();
            }
        }
        $dt = DateTime->new(%$date, %$tz);
    } else {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set format or format_custom attribute");
        $self->{output}->option_exit();
    }

    my $results = {
        epoch => $dt->epoch(),
        diff1 => time() - $dt->epoch(),
        diff2 => $dt->epoch() - time()
    };
    foreach (keys %$results) {
        my $attr = '%(' . $result->{label} . ucfirst($_) . ')';
        $attr = $options{'save_' . $_}
            if (defined($options{'save_' . $_}) && $options{'save_' . $_} ne '');
        my $var_save_value = $self->parse_special_variable(chars => [split //, $attr], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save_$_ attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $results->{$_}, %$var_save_value);
    }
}

sub exec_func_epoch2date {
    my ($self, %options) = @_;

    if (!defined($self->{module_datetime_loaded})) {
        centreon::plugins::misc::mymodule_load(
            module => 'DateTime',
            error_msg => "Cannot load module 'DateTime'."
        );
        $self->{module_datetime_loaded} = 1;
    }

    #{
    #   "type": "epoch2date",
    #   "src": "%(dateTestEpoch)",
    #   "format": "%a %b %e %H:%M:%S %Y",
    #   "timezone": "Asia/Tokyo",
    #   "locale": "fr",
    #   "save": "%(dateTestReformat)"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);

    my $extras = {};
    $extras->{time_zone} = $options{timezone} if (defined($options{timezone}) && $options{timezone} ne '');
    $extras->{locale} = $options{locale} if (defined($options{locale}) && $options{locale} ne '');
    my $dt = DateTime->from_epoch(
        epoch => $data,
        %$extras
    );
    my $time_value = $dt->strftime($options{format});

    if (defined($options{save}) && $options{save} ne '') {
        my $var_save_value = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($var_save_value->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $time_value, %$var_save_value);
    }
}

sub exec_func_count {
    my ($self, %options) = @_;

    #{
    #   "type": "count",
    #   "src": "%(snmp.tables.test)",
    #   "save": "%(testCount)"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^2$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);
    my $value = 0;
    if (defined($data)) {
        if (defined($options{filter}) && $options{filter} ne '') {
            my $count = 0;
            foreach my $instance (keys %$data) {
                my $values = $self->{expand};
                foreach my $label (keys %{$data->{$instance}}) {
                    $values->{'src.' . $label} = $data->{$instance}->{$label};
                }
                $count++ unless ($self->check_filter(filter => $options{filter}, values => $values));
            }
            $value = $count;
        } else {
            $value = scalar(keys %$data);
        }
    }

    if (defined($options{save}) && $options{save} ne '') {
        my $save = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($save->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $value, %$save);
    }
}

sub exec_func_replace {
    my ($self, %options) = @_;

    #{
    #   "type": "replace",
    #   "src": "%(sql.tables.test)",
    #   "expression": "s/name/name is/"
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{expression}) || $options{expression} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set expression attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }
    my $data = $self->get_special_variable_value(%$result);

    if (defined($data)) {
        my $expression = $self->substitute_string(value => $options{expression});
        our $assign_var = $data;
        $self->{safe_func}->reval("\$assign_var =~ $expression", 1);
        if ($@) {
            die 'Unsafe code evaluation: ' . $@;
        }
        $self->set_special_variable_value(value => $assign_var, %$result);
    }
}

sub exec_func_assign {
    my ($self, %options) = @_;

    #{
    #   "type": "assign",
    #   "save": "%(sql.tables.test)",
    #   "expression": "'%(sql.tables.test)' . 'toto'"
    #}
    if (!defined($options{save}) || $options{save} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set save attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{expression}) || $options{expression} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set expression attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    }

    my $expression = $self->substitute_string(value => $options{expression});
    our $assign_var;
    $self->{safe_func}->reval("\$assign_var = $expression", 1);
    if ($@) {
        die 'Unsafe code evaluation: ' . $@;
    }
    $self->set_special_variable_value(value => $assign_var, %$result);
}

sub exec_func_capture {
    my ($self, %options) = @_;

    #{
    #    "type": "capture",
    #    "src": "%(snmp.leefs.content)",
    #    "pattern": "(?msi)Vertical BER Analysis.*?Bit Error Rate: (\S+)",
    #    "groups": [
    #        { "offset": 1, "save": "%(bitErrorRate)" }
    #    ]
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{pattern}) || $options{pattern} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set pattern attribute");
        $self->{output}->option_exit();
    }
    if (!defined($options{groups}) || ref($options{groups}) ne 'ARRAY') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set groups attribute");
        $self->{output}->option_exit();
    }

    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    } 
    my $data = $self->get_special_variable_value(%$result);

    my @matches = ($data =~ /$options{pattern}/);

    foreach (@{$options{groups}}) {
        next if ($_->{offset} !~ /^[0-9]+/);

        my $value = '';
        if (defined($matches[ $_->{offset} ])) {
            $value = $matches[ $_->{offset} ];
        }

        my $save = $self->parse_special_variable(chars => [split //, $_->{save}], start => 0);
        if ($save->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $value, %$save);
    }
}

sub exec_func_scientific2number {
    my ($self, %options) = @_;

    #{
    #    "type": "scientific2number",
    #    "src": "%(bitErrorRate)",
    #    "save": "%(bitErrorRate)",
    #}
    if (!defined($options{src}) || $options{src} eq '') {
        $self->{output}->add_option_msg(short_msg => "$self->{current_section} please set src attribute");
        $self->{output}->option_exit();
    }
    my $result = $self->parse_special_variable(chars => [split //, $options{src}], start => 0);
    if ($result->{type} !~ /^(?:0|1|4)$/) {
        $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in src attribute");
        $self->{output}->option_exit();
    } 
    my $data = $self->get_special_variable_value(%$result);

    $data = centreon::plugins::misc::expand_exponential(value => $data);

    if (defined($options{save}) && $options{save} ne '') {
        my $save = $self->parse_special_variable(chars => [split //, $options{save}], start => 0);
        if ($save->{type} !~ /^(?:0|1|4)$/) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed in save attribute");
            $self->{output}->option_exit();
        }
        $self->set_special_variable_value(value => $data, %$save);
    }
}

sub set_functions {
    my ($self, %options) = @_;

    return if (!defined($options{functions}));
    my $i = -1;
    foreach (@{$options{functions}}) {
        $i++;
        $self->{current_section} = '[' . $options{section} . ' > ' . $i . ']';
        next if (defined($_->{position}) && $options{position} ne $_->{position});
        next if (!defined($_->{position}) && !(defined($options{default}) && $options{default} == 1));
        
        next if (!defined($_->{type}));

        if ($_->{type} eq 'map') {
            $self->exec_func_map(%$_);
        } elsif ($_->{type} eq 'scale') {
            $self->exec_func_scale(%$_);
        } elsif ($_->{type} eq 'second2human') {
            $self->exec_func_second2human(%$_);
        } elsif (lc($_->{type}) eq 'date2epoch') {
            $self->exec_func_date2epoch(%$_);
        } elsif (lc($_->{type}) eq 'epoch2date') {
            $self->exec_func_epoch2date(%$_);
        } elsif (lc($_->{type}) eq 'count') {
            $self->exec_func_count(%$_);
        } elsif (lc($_->{type}) eq 'replace') {
            $self->exec_func_replace(%$_);
        } elsif (lc($_->{type}) eq 'assign') {
            $self->exec_func_assign(%$_);
        } elsif (lc($_->{type}) eq 'capture') {
            $self->exec_func_capture(%$_);
        } elsif (lc($_->{type}) eq 'scientific2number') {
            $self->exec_func_scientific2number(%$_);
        }
    }
}

sub prepare_variables {
    my ($self, %options) = @_;

    return undef if (!defined($options{value}));

    while ($options{value} =~ /%\(([a-zA-Z0-9\.]+?)\)/g) {
        next if ($1 =~ /^snmp\./);
        $options{value} =~ s/%\(($1)\)/\$expand->{'$1'}/g;
    }

    my $expression = $self->substitute_string(value => $options{value});
    return $expression;
}

sub check_filter {
    my ($self, %options) = @_;

    return 0 if (!defined($options{filter}) || $options{filter} eq '');
    our $expand = $options{values};
    $options{filter} =~ s/%\(([a-zA-Z0-9\.]+?)\)/\$expand->{'$1'}/g;
    my $result = $self->{safe}->reval("$options{filter}");
    if ($@) {
        $self->{output}->add_option_msg(short_msg => 'Unsafe code evaluation: ' . $@);
        $self->{output}->option_exit();
    }
    return 0 if ($result);
    return 1;
}

sub check_filter_option {
    my ($self, %options) = @_;

    foreach (keys %{$self->{option_results}->{filter_selection}}) {
        return 1 if (
            defined($self->{expand}->{$_}) && $self->{option_results}->{filter_selection}->{$_} ne '' &&
            $self->{expand}->{$_} !~ /$self->{option_results}->{filter_selection}->{$_}/
        );
    }

    return 0;
}

sub prepare_perfdatas {
    my ($self, %options) = @_;

    return undef if (!defined($options{perfdatas}));
    my $perfdatas = [];
    foreach (@{$options{perfdatas}}) {
        next if (!defined($_->{nlabel}) || $_->{nlabel} eq '');
        next if (!defined($_->{value}) || $_->{value} eq '');
        my $perf = {};
        $perf->{nlabel} = $self->substitute_string(value => $_->{nlabel});
        $perf->{value} = $self->substitute_string(value => $_->{value});
        foreach my $label (('warning', 'critical', 'min', 'max', 'unit')) {
            next if (!defined($_->{$label}));
            $perf->{$label} = $self->substitute_string(value => $_->{$label});
        }
        if (defined($_->{instances})) {
            $perf->{instances} = [];
            foreach my $instance (@{$_->{instances}}) {
                push @{$perf->{instances}}, $self->substitute_string(value => $instance);
            }
        }
        push @$perfdatas, $perf;
    }

    return $perfdatas;
}

sub prepare_formatting {
    my ($self, %options) = @_;

    return undef if (!defined($options{formatting}));
    my $format = {};
    $format->{printf_msg} = $options{formatting}->{printf_msg};
    $format->{display_ok} = $options{formatting}->{display_ok};
    if (defined($options{formatting}->{printf_var})) {
        $format->{printf_var} = [];
        foreach my $var (@{$options{formatting}->{printf_var}}) {
            push @{$format->{printf_var}}, $self->substitute_string(value => $var);
        }
    }

    return $format
}

sub add_selection {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{selection}));

    my $i = -1;
    foreach (@{$self->{config}->{selection}}) {
        $i++;
        my $config = {};
        $self->{expand} = $self->set_constants();
        $self->set_builtin();
        $self->{expand}->{name} = $_->{name} if (defined($_->{name}));
        $self->set_functions(section => "selection > $i > functions", functions => $_->{functions}, position => 'before_expand');
        $self->set_expand_table(section => "selection > $i > expand_table", expand => $_->{expand_table});
        $self->set_expand(section => "selection > $i > expand", expand => $_->{expand});
        $self->set_functions(section => "selection > $i > functions", functions => $_->{functions}, position => 'after_expand', default => 1);
        next if ($self->check_filter(filter => $_->{filter}, values => $self->{expand}));
        next if ($self->check_filter_option());
        $config->{unknown} = $self->prepare_variables(section => "selection > $i > unknown", value => $_->{unknown});
        $config->{warning} = $self->prepare_variables(section => "selection > $i > warning", value => $_->{warning});
        $config->{critical} = $self->prepare_variables(section => "selection > $i > critical", value => $_->{critical});
        $config->{perfdatas} = $self->prepare_perfdatas(section => "selection > $i > perfdatas", perfdatas => $_->{perfdatas});
        $config->{formatting} = $self->prepare_formatting(section => "selection > $i > formatting", formatting => $_->{formatting});
        $config->{formatting_unknown} = $self->prepare_formatting(section => "selection > $i > formatting_unknown", formatting => $_->{formatting_unknown});
        $config->{formatting_warning} = $self->prepare_formatting(section => "selection > $i > formatting_warning", formatting => $_->{formatting_warning});
        $config->{formatting_critical} = $self->prepare_formatting(section => "selection > $i > formatting_critical", formatting => $_->{formatting_critical});
        $self->{selections}->{'s' . $i} = { expand => $self->{expand}, config => $config };
    }
}

sub add_selection_loop {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{selection_loop}));
    my $i = -1;
    foreach (@{$self->{config}->{selection_loop}}) {
        $i++;

        next if (!defined($_->{source}) || $_->{source} eq '');
        $self->{current_section} = '[selection_loop > ' . $i . ' > source]';
        my $result = $self->parse_special_variable(chars => [split //, $_->{source}], start => 0);
        if ($result->{type} != 2) {
            $self->{output}->add_option_msg(short_msg => $self->{current_section} . " special variable type not allowed");
            $self->{output}->option_exit();
        }
        next if (!defined($self->{snmp_collected}->{tables}->{ $result->{table} }));

        foreach my $instance (keys %{$self->{snmp_collected}->{tables}->{ $result->{table} }}) {
            $self->{expand} = $self->set_constants();
            $self->set_builtin();
            $self->{expand}->{ $result->{table} . '.instance' } = $instance;
            foreach my $label (keys %{$self->{snmp_collected}->{tables}->{ $result->{table} }->{$instance}}) {
                $self->{expand}->{ $result->{table} . '.' . $label } =
                    $self->{snmp_collected}->{tables}->{ $result->{table} }->{$instance}->{$label};
            }
            my $config = {};
            $self->{expand}->{name} = $_->{name} if (defined($_->{name}));
            $self->set_functions(section => "selection_loop > $i > functions", functions => $_->{functions}, position => 'before_expand');
            $self->set_expand_table(section => "selection_loop > $i > expand_table", expand => $_->{expand_table});
            $self->set_expand(section => "selection_loop > $i > expand", expand => $_->{expand});
            $self->set_functions(section => "selection_loop > $i > functions", functions => $_->{functions}, position => 'after_expand', default => 1);
            next if ($self->check_filter(filter => $_->{filter}, values => $self->{expand}));
            next if ($self->check_filter_option());
            $config->{unknown} = $self->prepare_variables(section => "selection_loop > $i > unknown", value => $_->{unknown});
            $config->{warning} = $self->prepare_variables(section => "selection_loop > $i > warning", value => $_->{warning});
            $config->{critical} = $self->prepare_variables(section => "selection_loop > $i > critical", value => $_->{critical});
            $config->{perfdatas} = $self->prepare_perfdatas(section => "selection_loop > $i > perfdatas", perfdatas => $_->{perfdatas});
            $config->{formatting} = $self->prepare_formatting(section => "selection_loop > $i > formatting", formatting => $_->{formatting});
            $config->{formatting_unknown} = $self->prepare_formatting(section => "selection_loop > $i > formatting_unknown", formatting => $_->{formatting_unknown});
            $config->{formatting_warning} = $self->prepare_formatting(section => "selection_loop > $i > formatting_warning", formatting => $_->{formatting_warning});
            $config->{formatting_critical} = $self->prepare_formatting(section => "selection_loop > $i > formatting_critical", formatting => $_->{formatting_critical});
            $self->{selections}->{'s' . $i . '-' . $instance} = { expand => $self->{expand}, config => $config };
        }
    }
}

sub set_formatting {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{formatting}));
    if (defined($self->{config}->{formatting}->{custom_message_global})) {
        $self->{maps_counters_type}->[0]->{message_multiple} = $self->{config}->{formatting}->{custom_message_global};
    }
    if (defined($self->{config}->{formatting}->{separator})) {
        $self->{maps_counters_type}->[0]->{message_separator} = $self->{config}->{formatting}->{separator};
    }
}


sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->read_config();
    $self->collect_snmp(snmp => $options{snmp});

    $self->{selections} = {};
    $self->add_selection();
    $self->add_selection_loop();
    foreach (values %{$self->{selections}}) {
        my $entry = {};
        foreach my $label (keys %{$_->{expand}}) {
            next if ($label =~ /^(?:constants|builtin)\./);
            my $name = $label;
            $name =~ s/\./_/g;
            $entry->{$name} = defined($_->{expand}->{$label}) ? $_->{expand}->{$label} : '';
        }
        $self->{output}->add_disco_entry(%$entry);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    # TODO:
    #   add some functions types:
    #       decode snmp type: ipAddress
    #   can cache only some parts of snmp requests:
    #       use an array for "snmp" ?
    $self->read_config();
    $self->collect_snmp(snmp => $options{snmp});

    $self->{selections} = {};
    $self->add_selection();
    $self->add_selection_loop();
    $self->set_formatting();
}

1;

__END__

=head1 MODE

Collect and compute SNMP data.

=over 8

=item B<--config>

config used (required).
Can be a file or json content.

=item B<--filter-selection>

Filter selections.
Example: --filter-selection='name=test'

=item B<--constant>

Add a constant.
Example: --constant='warning=30' --constant='critical=45'

=back

=cut
