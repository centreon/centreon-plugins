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

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Output source status is '%s'", $self->{result_values}->{status});
}

sub prefix_oline_output {
    my ($self, %options) = @_;

    return "Output line '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'oline', type => 1, cb_prefix_output => 'prefix_oline_output', message_multiple => 'All output lines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'source-status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{oline} = [
        { label => 'load', nlabel => 'line.output.load.percentage', set => {
                key_values => [ { name => 'percent_load' } ],
                output_template => 'load: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'current', nlabel => 'line.output.current.ampere', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current: %.2f A',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'A', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'voltage', nlabel => 'line.output.voltage.volt', set => {
                key_values => [ { name => 'voltage' } ],
                output_template => 'voltage: %.2f V',
                perfdatas => [
                    { template => '%.2f', unit => 'V', label_extra_instance => 1 }
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

# on va faire une methode de selection globale pour trouver.
# apres le comportement change.

#"expand_table": {
#   "mytable": "%(snmp.tables.plcData[1])"
# },
# "expand": {
#    "serial": "%(snmp.leefs.serialNum)",
#    "test": "test display",
#    "test2": "other %(snmp.tables.plcOther.plop[1])"
#},
# on stocke dans:
#    'snmp.tables.plcData' { 'instance' => { 'plcWrite' => 'xxx' }'

=pod
"selection": [
    {
        "name": "TDO1 : Interrupteur Général IG",
        "expand_table": {
            "mytable": "%(snmp.tables.plcData[1])"
        },
        "expand": {
            "serial": "%(snmp.leefs.serialNum)",
            "test": "test display",
            "test2": "other %(snmp.tables.plcOther.plop[1])"
        },
        "map": {
            "%(mytable.plcWrite)": "disjoncteur"
        },
        "warning": "%(mytable.plcWrite) eq 'ouvert'",
        "critical": "%(mytable.plcWrite) eq 'ferme'",
        "perfdatas": [
            { "nlabel": "test.count", "instances": ["%(test)", "%(name)"], "value": "%(mytable.plcWrite)", "warning": "20", "critical": "30", "min": 0 }
        ],
        "custom_formatting": {
            "printf_msg":"name %s serial %s data is %.2f",
            "printf_var":[
                "%(name)",
                "%(serial)",
                "%(mytable.plcRead)"
            ]
        }
    }
],
=cut

sub manage_selection {
    my ($self, %options) = @_;

    $self->read_config();
    $self->collect_snmp(snmp => $options{snmp});
    use Data::Dumper; print Data::Dumper::Dumper($self->{snmp_collected});

    
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
