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

package centreon::plugins::alternative::Getopt;

use strict;
use warnings;

use Exporter;
use vars qw(@ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);

BEGIN {
    @EXPORT    = qw(&GetOptions);
    @EXPORT_OK = qw();
}

use vars @EXPORT, @EXPORT_OK;

our $warn_message = 0;

sub get_assigned_value {
    my (%options) = @_;
    
    if (!defined($options{val}) || $options{val} eq '') {
        # Add defined also. Hardened code: already see: $ARGV[6] = undef for example
        if ($options{pos} + 1 < $options{num_args} && defined($ARGV[$options{pos} + 1]) && $ARGV[$options{pos} + 1] !~ /^--/) {
            my $val = $ARGV[$options{pos} + 1];
            splice @ARGV, $options{pos} + 1, 1;
            return ($options{num_args} - 1, $val);
        } else {
            return ($options{num_args}, '');
        }
    }
    
    return ($options{num_args}, $options{val});
}

sub GetOptions {
    my (%opts) = @_;

    my $search_str = ',' . join(',', keys %opts) . ',';
    my $num_args = scalar(@ARGV);
    for (my $i = 0; $i < $num_args;) {
        if (defined($ARGV[$i]) && $ARGV[$i] =~ /^--(.*?)(?:=|$)((?s).*)/) {
            my ($option, $value) = ($1, $2);
            
            # find type of option
            if ($search_str !~ /,((?:[^,]*?\|){0,}$option(?:\|.*?){0,}(:.*?){0,1}),/) {
                warn "Unknown option: $option" if ($warn_message == 1);
                $i++;
                next;
            }
            
            my ($option_selected, $type_opt) = ($1, $2);
            if (!defined($type_opt)) {
                ${$opts{$option_selected}} = 1;
            } elsif ($type_opt =~ /:s$/) {
                ($num_args, my $assigned) = get_assigned_value(num_args => $num_args, pos => $i, val => $value);
                ${$opts{$option_selected}} = $assigned;
            } elsif ($type_opt =~ /:s\@$/) {
                ${$opts{$option . $type_opt}} = [] if (!defined(${$opts{$option . $type_opt}}));
                ($num_args, my $assigned) = get_assigned_value(num_args => $num_args, pos => $i, val => $value);
                push @{${$opts{$option_selected}}}, $assigned;
            } elsif ($type_opt =~ /:s\%$/) {
                ${$opts{$option . $type_opt}} = {} if (!defined(${$opts{$option . $type_opt}}));
                ($num_args, my $assigned) = get_assigned_value(num_args => $num_args, pos => $i, val => $value);
                if ($assigned =~ /^(.*?)=(.*)/) {
                    ${$opts{$option_selected}}->{$1} = $2;
                }
            } 
            
            splice @ARGV, $i, 1;
            $num_args--;
        } else {
            warn "argument $ARGV[$i] alone" if ($warn_message == 1 && $i != 0 && defined($ARGV[$i]));
            $i++;
        }
    }
}

1;

__END__
