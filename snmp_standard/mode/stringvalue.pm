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

package snmp_standard::mode::stringvalue;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "oid:s"                   => { name => 'oid' },
                                  "warning-regexp:s"        => { name => 'warning_regexp' },
                                  "critical-regexp:s"       => { name => 'critical_regexp' },
                                  "unknown-regexp:s"        => { name => 'unknown_regexp' },
                                  "format:s"                => { name => 'format', default => 'current value is %s' },
                                  "map-values:s"            => { name => 'map_values' },
                                  "map-values-separator:s"  => { name => 'map_values_separator', default => ',' },
                                  "regexp-map-values"       => { name => 'use_regexp_map_values' },
                                  "regexp-isensitive"       => { name => 'use_iregexp' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{oid}) || $self->{option_results}->{oid} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify an OID.");
       $self->{output}->option_exit(); 
    }
    $self->{option_results}->{oid} = '.' . $self->{option_results}->{oid} if ($self->{option_results}->{oid} !~ /^\./);

    $self->{map_values} = {};
    if (defined($self->{option_results}->{map_values})) {
        foreach (split /$self->{option_results}->{map_values_separator}/, $self->{option_results}->{map_values}) {
            my ($name, $map) = split /=>/;
            $self->{map_values}->{centreon::plugins::misc::trim($name)} = centreon::plugins::misc::trim($map);
        }
    }
}

sub check_regexp {
    my ($self, %options) = @_;
    
    return 0 if (!defined($self->{option_results}->{$options{severity} . '_regexp'}));
    my $regexp = $self->{option_results}->{$options{severity} . '_regexp'};
    
    if (defined($self->{option_results}->{use_iregexp}) && $options{value} =~ /$regexp/i) {
        $self->{exit_code} = $options{severity};
        return 1;
    } elsif (!defined($self->{option_results}->{use_iregexp}) && $options{value} =~ /$regexp/) {
        $self->{exit_code} = $options{severity};
        return 1;
    }
    
    return 0;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};    

    my $result = $self->{snmp}->get_leef(oids => [$self->{option_results}->{oid}], nothing_quit => 1);
    my $value_check = $result->{$self->{option_results}->{oid}};
    my $value_display = $value_check;
    
    if (defined($self->{option_results}->{map_values})) {
        # If we don't find it. We keep the original value
        $value_display = defined($self->{map_values}->{$value_check}) ? $self->{map_values}->{$value_check} : $value_check;
        if (defined($self->{option_results}->{use_regexp_map_values})) {
            $value_check = $value_display;
        }
    }
    
    $self->{exit_code} = 'ok';
    $self->check_regexp(severity => 'critical', value => $value_check) || 
        $self->check_regexp(severity => 'warning', value => $value_check) || 
        $self->check_regexp(severity => 'unknown', value => $value_check);

    $self->{output}->output_add(severity => $self->{exit_code},
                                short_msg => sprintf($self->{option_results}->{format}, $value_display));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check an SNMP string value (can be a String or an Integer).

=over 8

=item B<--oid>

OID value to check (numeric format only).

=item B<--warning-regexp>

Return Warning if the oid value match the regexp.

=item B<--critical-regexp>

Return Critical if the oid value match the regexp.

=item B<--unknown-regexp>

Return Unknown if the oid value match the regexp.

=item B<--format>

Output format (Default: 'current value is %s').

=item B<--map-values>

Use to transform an integer value in most common case.
Example: --map-values='1=>ok,10=>fan failed,11=>psu recovery'

=item B<--map-values-separator>

Separator uses between values (default: coma).

=item B<--regexp-map-values>

Use the 'map values' to match in regexp (need --map-values option).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive.

=back

=cut
