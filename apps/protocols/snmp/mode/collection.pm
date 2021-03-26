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
use centreon::plugins::statefile;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'selections', type => 1, message_multiple => 'All selections are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{selections} = [
        { label => 'select', threshold => 0, set => {
                key_values => [ { name => 'percent_load' } ],
                output_template => 'load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'config:s' => { name => 'config' }
    });

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
        $self->{config} = JSON::XS->new->utf8->decode($content);
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
        foreach (@{$table->{entries}}) {
            $self->validate_name(name => $_->{name}, section => "[snmp > tables > $table->{name}]");
            if (!defined($_->{oid}) || $_->{oid} eq '') {
                $self->{output}->add_option_msg(short_msg => "oid attribute is missing [snmp > tables > $table->{name} >  $_->{name}]");
                $self->{output}->option_exit();
            }
            $mapping->{ $_->{name} } = { oid => $_->{oid} };
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
        statefile => 'cache_snmp_collection_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port()
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

sub collect_snmp {
    my ($self, %options) = @_;

    if (!defined($self->{config}->{snmp})) {
        $self->{output}->add_option_msg(short_msg => 'please set snmp config');
        $self->{output}->option_exit();
    }

    return if ($self->use_snmp_cache(snmp => $options{snmp}));

    $self->{snmp_collected} = { tables => {}, leefs => {}, epoch => time() };

    $self->collect_snmp_tables(snmp => $options{snmp});
    $self->collect_snmp_leefs(snmp => $options{snmp});

    $self->save_snmp_cache();
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

sub get_leef_variable {
    my ($self, %options) = @_;

    return $self->{snmp_collected}->{leefs}->{ $options{name} };
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
            my $data;
            if ($results->{$i}->{type} == 0) {
                $data = $self->get_local_variable(name => $results->{$i}->{label});
            } elsif ($results->{$i}->{type} == 1) {
                $data = $self->get_leef_variable(name => $results->{$i}->{label});
            } elsif ($results->{$i}->{type} == 4) {
                $data = $self->get_table_attribute_value(
                    table => $results->{$i}->{table},
                    instance => $results->{$i}->{instance},
                    attribute => $results->{$i}->{label}
                );
            }
            $end = $results->{$i}->{end};
            $str .= defined($data) ? $data : '';
        } else {
            $str .= $arr->[$i];
        }
    }

    return $str;
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

        foreach (keys %$table) {
            $self->{expand}->{ $result->{table} . '.' . $_ } = $table->{$_};
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

sub add_selection {
    my ($self, %options) = @_;

    return if (!defined($self->{config}->{selection}));

    my $i = -1;
    foreach (@{$self->{config}->{selection}}) {
        $i++;
        $self->{expand} = {};
        $self->{expand}->{name} = $_->{name} if (defined($_->{name}));
        $self->set_expand_table(section => "selection > $i > expand_table >", expand => $_->{expand_table});
        $self->set_expand(section => "selection > $i > expand >", expand => $_->{expand});
    }

    use Data::Dumper; print Data::Dumper::Dumper($self->{expand});
}

sub add_selection_loop {
    my ($self, %options) = @_;

    
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

sub manage_selection {
    my ($self, %options) = @_;

    $self->read_config();
    $self->collect_snmp(snmp => $options{snmp});

    $self->add_selection();
    $self->add_selection_loop();
    $self->set_formatting();

    exit(1);
}

1;

__END__

=head1 MODE

Collect and compute SNMP datas.

=over 8

=item B<--config>

config used (Required).
Can be a file or json content.

=back

=cut
