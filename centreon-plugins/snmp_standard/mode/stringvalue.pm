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

package snmp_standard::mode::stringvalue;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'oid:s'                   => { name => 'oid' },
        'oid-leef:s'              => { name => 'oid_leef' },
        'oid-table:s'             => { name => 'oid_table' },
        'oid-instance:s'          => { name => 'oid_instance' },
        'filter-table-value:s'    => { name => 'filter_table_value' },
        'filter-table-instance:s' => { name => 'filter_table_instance' },

        'warning-regexp:s'        => { name => 'warning_regexp' },
        'critical-regexp:s'       => { name => 'critical_regexp' },
        'unknown-regexp:s'        => { name => 'unknown_regexp' },
        'regexp-isensitive'       => { name => 'use_iregexp' },

        'warning-absent:s@'       => { name => 'warning_absent' },
        'critical-absent:s@'      => { name => 'critical_absent' },
        'unknown-absent:s@'       => { name => 'unknown_absent' },
        'warning-present:s@'      => { name => 'warning_present' },
        'critical-present:s@'     => { name => 'critical_present' },
        'unknown-present:s@'      => { name => 'unknown_present' },

        'format-ok:s'             => { name => 'format_ok', default => '%{filter_rows} value(s)' },
        'format-warning:s'        => { name => 'format_warning', default => 'value(s): %{details_warning}' },
        'format-critical:s'       => { name => 'format_critical', default => 'value(s): %{details_critical}' },
        'format-unknown:s'        => { name => 'format_unknown', default => 'value(s): %{details_unknown}' },

        'format-details-ok:s'         => { name => 'format_details_ok', default => '%{value}' },
        'format-details-warning:s'    => { name => 'format_details_warning', default => '%{value}' },
        'format-details-critical:s'   => { name => 'format_details_critical', default => '%{value}' },
        'format-details-unknown:s'    => { name => 'format_details_unknown', default => '%{value}' },

        'format-details-separator-ok:s'       => { name => 'format_details_separator_ok', default => ', ' },
        'format-details-separator-warning:s'  => { name => 'format_details_separator_warning', default => ', ' },
        'format-details-separator-critical:s' => { name => 'format_details_separator_critical', default => ', ' },
        'format-details-separator-unknown:s'  => { name => 'format_details_separator_unknown', default => ', ' },

        'map-values:s'            => { name => 'map_values' },
        'map-value-other:s'       => { name => 'map_value_other' },
        'map-values-separator:s'  => { name => 'map_values_separator', default => ',' },
        'convert-custom-values:s' => { name => 'convert_custom_values' },

        'use-perl-mod:s@'         => { name => 'use_perl_mod' },
    });

    $self->{macros} = { ok => {}, warning => {}, critical => {}, unknown => {} };
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach my $mod (@{$self->{option_results}->{use_perl_mod}}) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $mod,
                                               error_msg => "Cannot load module '" . $mod . "'.");
    }

    $self->{option_results}->{oid_leef} = $self->{option_results}->{oid} if (defined($self->{option_results}->{oid}) && $self->{option_results}->{oid} ne '');
    if ((!defined($self->{option_results}->{oid_leef}) || $self->{option_results}->{oid_leef} eq '') &&
        (!defined($self->{option_results}->{oid_table}) || $self->{option_results}->{oid_table} eq '')) {
       $self->{output}->add_option_msg(short_msg => 'Need to specify an OID with option --oid-leef or --oid-table.');
       $self->{output}->option_exit(); 
    }
    foreach (('oid_leef', 'oid_table', 'oid_instance')) {
        $self->{option_results}->{$_} = '.' . $self->{option_results}->{$_} if (defined($self->{option_results}->{$_}) && $self->{option_results}->{$_} ne '' && $self->{option_results}->{$_} !~ /^\./);
    }   
    
    $self->{map_values} = {};
    if (defined($self->{option_results}->{map_values})) {
        foreach (split /$self->{option_results}->{map_values_separator}/, $self->{option_results}->{map_values}) {
            my ($name, $map) = split /=>/;
            $self->{map_values}->{centreon::plugins::misc::trim($name)} = centreon::plugins::misc::trim($map);
        }
    }
}

sub get_instance_value {
    my ($self, %options) = @_;
    
    if (!defined($self->{option_results}->{oid_instance}) || $self->{option_results}->{oid_instance} eq ''
        || !defined($self->{results}->{$self->{option_results}->{oid_instance} . '.' . $options{instance}})) {
        return $options{instance};
    }
    
    return $self->{results}->{$self->{option_results}->{oid_instance} . '.' . $options{instance}};
}

sub get_change_value {
    my ($self, %options) = @_;
    
    my $value = $options{value};
    return '' if (!defined($options{value}));
    if (defined($self->{map_values}->{$options{value}})) {
        $value = $self->{map_values}->{$options{value}};
    } elsif (defined($self->{option_results}->{map_value_other}) && $self->{option_results}->{map_value_other} ne '') {
        $value = $self->{option_results}->{map_value_other};
    }

    if (defined($self->{option_results}->{convert_custom_values}) && $self->{option_results}->{convert_custom_values} ne '') {
        eval "\$value = $self->{option_results}->{convert_custom_values}";
    }

    return $value;
}

sub get_snmp_values {
    my ($self, %options) = @_;
    
    $self->{instances} = {};
    if (defined($self->{option_results}->{oid_leef}) && $self->{option_results}->{oid_leef} ne '') {
        $self->{results} = $self->{snmp}->get_leef(oids => [$self->{option_results}->{oid_leef}], nothing_quit => 1);
        $self->{macros}->{rows} = 1;
        $self->{macros}->{filter_rows} = 1;
        $self->{instances}->{0} = $self->get_change_value(value => $self->{results}->{$self->{option_results}->{oid_leef}});
        return 0;
    }
    
    my $tables = [ { oid => $self->{option_results}->{oid_table}} ];
    push @$tables, { oid => $self->{option_results}->{oid_instance} } if (defined($self->{option_results}->{oid_instance}) && $self->{option_results}->{oid_instance} ne '');
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $tables, nothing_quit => 1, return_type => 1);
    my ($row, $filter_row) = (0, 0);
    foreach (keys %{$self->{results}}) {
        next if ($_ !~ /^$self->{option_results}->{oid_table}\.(.*)$/);
        
        $row++;
        my $instance = $self->get_instance_value(instance => $1);
        my $value = $self->get_change_value(value => $self->{results}->{$_});
        $self->{output}->output_add(long_msg => sprintf('[instance: %s][value: %s]', $_, $value), debug => 1);
        if (defined($self->{option_results}->{filter_table_value}) && $self->{option_results}->{filter_table_value} ne '' && 
            $value !~ /$self->{option_results}->{filter_table_value}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping oid '%s' value '%s': not matching the filter", $_, $value), debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_table_instance}) && $self->{option_results}->{filter_table_instance} ne '' && 
            $instance !~ /$self->{option_results}->{filter_table_instance}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping oid '%s' instance '%s': not matching the filter", $_, $instance), debug => 1);
            next;
        }
        
        $self->{instances}->{$instance} = $value;
        $filter_row++;
    }
    $self->{macros}->{rows} = $row;
    $self->{macros}->{filter_rows} = $filter_row;
    
    return 0;
}

sub checking_regexp {
    my ($self, %options) = @_;
    
    return 0 if (!defined($self->{option_results}->{$options{severity} . '_regexp'}));
    my $regexp = $self->{option_results}->{$options{severity} . '_regexp'};
    
    if (defined($self->{option_results}->{use_iregexp}) && $options{value} =~ /$regexp/i) {
        $self->{instances}->{$options{severity}}->{$options{instance}} = $options{value};
        return 1;
    } elsif (!defined($self->{option_results}->{use_iregexp}) && $options{value} =~ /$regexp/) {
        $self->{instances}->{$options{severity}}->{$options{instance}} = $options{value};
        return 1;
    }    
    
    return 0;
}

sub store_ok {
    my ($self, %options) = @_;
    
    foreach my $severity (('critical', 'warning', 'unknown')) {
        foreach my $type (('absent', 'present')) {
            if (defined($self->{option_results}->{$severity . '_' . $type}) && scalar(@{$self->{option_results}->{$severity . '_' . $type}}) > 0) {
                return 0;
            }   
        }
    }

    $self->{instances}->{ok}->{$options{instance}} = $options{value};
}

sub checking_exist {
    my ($self, %options) = @_;
    
    foreach my $severity (('critical', 'warning', 'unknown')) {
        foreach my $absent (@{$self->{option_results}->{$severity . '_absent'}}) {
            my $match = 0;
            foreach (keys %{$self->{instances}}) {
                if ($self->{instances}->{$_} eq $absent) {
                    $match = 1;
                    last;
                }
            }
            
            if ($match == 0) {
                $self->{instances}->{$severity}->{$absent} = $absent;
            }
        }
        
        foreach my $present (@{$self->{option_results}->{$severity . '_present'}}) {
            my $match = 0;
            foreach (keys %{$self->{instances}}) {
                if ($self->{instances}->{$_} eq $present) {
                    $self->{instances}->{$severity}->{$_} = $self->{instances}->{$_};
                }
            }
        }
    }
}

sub change_macros {
    my ($self, %options) = @_;

    my $value = $self->{option_results}->{'format_' . $options{severity}};
    while ($value =~ /%\{(.*?)\}/g) {
        $value =~ s/%\{($1)\}/\$self->{macros}->{$1}/g;
    }
    
    return $value;
}

sub build_format_details {
    my ($self, %options) = @_;
    
    foreach my $severity (('ok', 'critical', 'warning', 'unknown')) {
        $self->{macros}->{'details_' . $severity} = '';
        my $append = '';
        foreach my $instance (sort keys %{$self->{instances}->{$severity}}) {
            my $details = $self->{option_results}->{'format_details_' . $severity};
            $details =~ s/%\{rows\}/$self->{macros}->{rows}/g;
            $details =~ s/%\{filter_rows\}/$self->{macros}->{filter_rows}/g;
            $details =~ s/%\{instance\}/$instance/g;
            $details =~ s/%\{value\}/$self->{instances}->{$severity}->{$instance}/g;
        
            $self->{macros}->{'details_' . $severity} .= $append . $details;
            $append = $self->{option_results}->{'format_details_separator_' . $severity};
        }
    }
}

sub display_severity {
    my ($self, %options) = @_;
    
    if (!(defined($options{force}) && $options{force} == 1) && scalar(keys %{$self->{instances}->{$options{severity}}}) == 0) {
        return 0;
    }
    
    my $display = $self->change_macros(severity => $options{severity});
    eval "\$display = \"$display\"";
    $self->{output}->output_add(severity => $options{severity},
                                short_msg => $display);
}

sub display_result {
    my ($self, %options) = @_;

    $self->build_format_details();
    $self->display_severity(severity => 'ok', force => 1);
    foreach my $severity (('critical', 'warning', 'unknown')) {
        $self->display_severity(severity => $severity);
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};    

    $self->get_snmp_values();
    
    foreach (keys %{$self->{instances}}) {
        $self->checking_regexp(severity => 'critical', instance => $_, value => $self->{instances}->{$_}) || 
            $self->checking_regexp(severity => 'warning', instance => $_, value => $self->{instances}->{$_}) || 
            $self->checking_regexp(severity => 'unknown', instance => $_, value => $self->{instances}->{$_}) || 
            $self->store_ok(instance => $_, value => $self->{instances}->{$_});
    }
    $self->checking_exist();
    $self->display_result();

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check SNMP string values (can be a String or an Integer).

Check values absent:
centreon_plugins.pl --plugin=snmp_standard::plugin --mode=string-value --hostname=127.0.0.1 --snmp-version=2c --snmp-community=public 
    --oid-table='.1.3.6.1.2.1.25.4.2.1.2' --format-ok='%{filter_rows} processes' --format-critical='processes are absent: %{details_critical}' --critical-absent='centengine' --critical-absent='crond' --filter-table-value='centengine|crond'

Check table status:
centreon_plugins.pl --plugin=snmp_standard::plugin --mode=string-value --hostname=127.0.0.1 --snmp-version=2c --snmp-community=akcp 
    --oid-table='.1.3.6.1.4.1.3854.1.2.2.1.16.1.4' --oid-instance='.1.3.6.1.4.1.3854.1.2.2.1.16.1.1' --map-values='1=>noStatus,2=>normal,3=>highWarning,4=>highCritical,5=>lowWarning,6=>lowCritical,7=>sensorError' --map-value-other='unknown' --format-ok='All %{rows} entries [%{filter_rows}/%{rows} Temperatures] are ok.' --format-critical='%{details_critical}' --format-details-critical='%{instance} status is %{value}' --critical-regexp='highCritical|lowCritical|sensorError'

Check like the old plugin:
centreon_plugins.pl --plugin=snmp_standard::plugin --mode=string-value --hostname=127.0.0.1 --snmp-version=2c --snmp-community=public 
    --oid='.1.3.6.1.2.1.1.1.0' --format-ok='current value is: %{details_ok}' --format-details-warning='current value is: %{details_warning}'  --format-details-critical='current value is: %{details_critical}'    
 
=over 8

=item B<--oid> or <--oid-leef>

OID value to check (numeric format only).

=item B<--oid-table>

OID table value to check (numeric format only).

=item B<--oid-instance>

OID table value for the instance (numeric format only).
Can be used to have human readable instance name.

=item B<--filter-table-value>

Filter value from --oid-table option (can be a regexp).

=item B<--filter-table-instance>

Filter instance from --oid-table option (can be a regexp).

=item B<--warning-regexp>

Return Warning if an oid value match the regexp.

=item B<--critical-regexp>

Return Critical if an oid value match the regexp.

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive.

=item B<--format-*>

Output format according the threshold.
Can be: 
'ok' (default: '%{filter_rows} value(s)'), 
'warning' (default: 'value(s): %{details_warning}'), 
'critical' (default: 'value(s): %{details_critical}'), 
'unknown' (default: 'value(s): %{details_unknown}').
Can used: %{rows}, %{filter_rows}, %{details_warning}, %{details_ok}, %{details_critical}, %{details_unknown}

=item B<--map-values>

Use to transform an integer value in most common case.
Example: --map-values='1=>ok,10=>fan failed,11=>psu recovery'

=item B<--map-value-other>

Use to transform an integer value not defined in --map-values option.

=item B<--map-values-separator>

Separator uses between values (default: coma).

=item B<--convert-custom-values>

Custom code to convert values.
Example to convert octetstring to macaddress: --convert-custom-values='join(":", unpack("(H2)*", $value))'

=item B<--use-perl-mod>

Load additional Perl module (Can be multiple)
Example : --use-perl-mod='Date::Parse'

=back

=cut
