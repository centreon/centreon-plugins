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

package apps::protocols::snmp::mode::collection;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use Safe;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub custom_select_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

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
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    $self->{result_values}->{last_status} = $status;
    return $status;
}

sub custom_select_perfdata {
    my ($self, %options) = @_;

    return if (!defined($self->{result_values}->{config}->{perfdatas}));
    foreach (@{$self->{result_values}->{config}->{perfdatas}}) {
        next if (!defined($_->{value}) || $_->{value} !~ /^\d+(?:\.\d+)?$/);
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
        next if (/^constants\./);
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
    });

    $self->{safe} = Safe->new();
    $self->{safe}->share('$expand');
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
    if (-f $self->{option_results}->{config}) {
        $content = do {
            local $/ = undef;
            if (!open my $fh, "<", $self->{option_results}->{config}) {
                $self->{output}->add_option_msg(short_msg => "Could not open file $self->{option_results}->{config} : $!");
                $self->{output}->option_exit();
            }
            <$fh>;
        };
    } else {
        $content = $self->{option_results}->{config};
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
            /$used_instance/;
            next if (defined($self->{snmp_collected}->{tables}->{ $table->{name} }->{$1}));
            $self->{snmp_collected}->{tables}->{ $table->{name} }->{$1} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
            foreach my $sample_name (keys %$sampling) {
                $self->{snmp_collected_sampling}->{tables}->{ $table->{name} } = {}
                    if (!defined($self->{snmp_collected_sampling}->{tables}->{ $table->{name} }));
                $self->{snmp_collected_sampling}->{tables}->{ $table->{name} }->{$1}->{$sample_name} = 
                    $self->{snmp_collected}->{tables}->{ $table->{name} }->{$1}->{$sample_name};
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

sub collect_snmp {
    my ($self, %options) = @_;

    if (!defined($self->{config}->{snmp})) {
        $self->{output}->add_option_msg(short_msg => 'please set snmp config');
        $self->{output}->option_exit();
    }

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

sub set_constants {
    my ($self, %options) = @_;

    my $constants = {};
    return $constants if (!defined($self->{config}->{constants}));

    foreach (keys %{$self->{config}->{constants}}) {
        $constants->{'constants.' . $_} = $self->{config}->{constants}->{$_};
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
        }
    }
}

sub prepare_variables {
    my ($self, %options) = @_;

    return undef if (!defined($options{value}));
    $options{value} =~ s/%\(([a-z-A-Z0-9\.]+?)\)/\$expand->{'$1'}/g;
    return $options{value};
}

sub check_filter {
    my ($self, %options) = @_;

    return 0 if (!defined($options{filter}) || $options{filter} eq '');
    our $expand = $self->{expand};
    $options{filter} =~ s/%\(([a-z-A-Z0-9\.]+?)\)/\$expand->{'$1'}/g;
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
        $self->{expand}->{name} = $_->{name} if (defined($_->{name}));
        $self->set_functions(section => "selection > $i > functions", functions => $_->{functions}, position => 'before_expand');
        $self->set_expand_table(section => "selection > $i > expand_table", expand => $_->{expand_table});
        $self->set_expand(section => "selection > $i > expand", expand => $_->{expand});
        $self->set_functions(section => "selection > $i > functions", functions => $_->{functions}, position => 'after_expand', default => 1);
        next if ($self->check_filter(filter => $_->{filter}));
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
            next if ($self->check_filter(filter => $_->{filter}));
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
            next if ($label =~ /^constants\./);
            my $name = $label;
            $name =~ s/\./_/g;
            $entry->{$name} = $_->{expand}->{$label};
        }
        $self->{output}->add_disco_entry(%$entry);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    # TODO:
    #   add some functions types:
    #       eval_equal (concatenate, math operation)
    #       regexp (regexp substitution, extract a pattern)
    #       decode snmp type: ipAddress, DateTime (seconds, strftime)
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

Collect and compute SNMP datas.

=over 8

=item B<--config>

config used (Required).
Can be a file or json content.

=item B<--filter-selection>

Filter selections.
Eg: --filter-selection='name=test'

=back

=cut
