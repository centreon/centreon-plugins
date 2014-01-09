################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package network::securactive::mode::bcn;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_spvBCNName = '.1.3.6.1.4.1.36773.3.2.2.1.1.1';
my $oid_spvBCNGlobalStatus = '.1.3.6.1.4.1.36773.3.2.2.1.1.4';

my %bcn_status = (
    1 => ['ok', 'OK'], 
    2 => ['warning', 'WARNING'], 
    3 => ['alert', 'WARNING'], 
    4 => ['not available', 'UNKNOWN'],
    5 => ['not data at all', 'UNKNOWN'],
    6 => ['not enough samples for computation', 'UNKNOWN'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "bcn:s"                   => { name => 'bcn' },
                                  "name"                    => { name => 'use_name' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "display-transform-src:s" => { name => 'display_transform_src' },
                                  "display-transform-dst:s" => { name => 'display_transform_dst' },
                                });
    $self->{bcn_id_selected} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{result_names} = $self->{snmp}->get_table(oid => $oid_spvBCNName, nothing_quit => 1);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{result_names}})) {
        next if ($oid !~ /\.([0-9]+)$/);
        my $instance = $1;
        
        # Get all without a name
        if (!defined($self->{option_results}->{bcn})) {
            push @{$self->{bcn_id_selected}}, $instance; 
            next;
        }
        
        # By ID
        if (!defined($self->{option_results}->{use_name}) && defined($self->{option_results}->{bcn})) {
            if ($instance == $self->{option_results}->{bcn}) {
                push @{$self->{bcn_id_selected}}, $instance; 
            }
            next;
        }
        
        $self->{result_names}->{$oid} = $self->{output}->to_utf8($self->{result_names}->{$oid});
        if (!defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} eq $self->{option_results}->{bcn}) {
            push @{$self->{bcn_id_selected}}, $instance; 
        }
        if (defined($self->{option_results}->{use_regexp}) && $self->{result_names}->{$oid} =~ /$self->{option_results}->{bcn}/) {
            push @{$self->{bcn_id_selected}}, $instance;
        }
    }

    if (scalar(@{$self->{bcn_id_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No bcn found for name '" . $self->{option_results}->{bcn} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    $self->{snmp}->load(oids => [$oid_spvBCNGlobalStatus], 
                        instances => $self->{bcn_id_selected});
    my $result = $self->{snmp}->get_leef();
    
    if (!defined($self->{option_results}->{bcn}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All BCN are ok.');
    }
    
    foreach my $instance (sort @{$self->{bcn_id_selected}}) {
        my $name = $self->{result_names}->{$oid_spvBCNName . '.' . $instance};
        $name = $self->get_display_value(value => $name);
        my $status = $result->{$oid_spvBCNGlobalStatus . '.' . $instance};
        my $exit_from_snmp = ${$bcn_status{$status}}[1];
        
        $self->{output}->output_add(long_msg => sprintf("BCN '%s' global status is '%s'", 
                                                        $name, ${$bcn_status{$status}}[0]));
        if (!$self->{output}->is_status(value => $exit_from_snmp, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{bcn}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit_from_snmp,
                                        short_msg => sprintf("BCN '%s' global status is '%s'", $name, ${$bcn_status{$status}}[0]));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{bcn}) || defined($self->{option_results}->{use_regexp}));
        #$self->{output}->perfdata_add(label => 'eurt' . $extra_label,
        #                              value => $eurt,
        #                              warning => $warnth,
        #                              critical => $critth,
        #                              min => 0);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub get_display_value {
    my ($self, %options) = @_;
    my $value = $options{value};

    if (defined($self->{option_results}->{display_transform_src})) {
        $self->{option_results}->{display_transform_dst} = '' if (!defined($self->{option_results}->{display_transform_dst}));
        eval "\$value =~ s{$self->{option_results}->{display_transform_src}}{$self->{option_results}->{display_transform_dst}}";
    }
    return $value;
}

1;

__END__

=head1 MODE

Check BCN status.

=over 8

=item B<--bcn>

Set the bcn (number expected) ex: 1, 2,... (empty means 'check all bcn').

=item B<--name>

Allows to use bcn name with option --bcn instead of bcn oid index.

=item B<--regexp>

Allows to use regexp to filter bcn (with option --name).

=item B<--display-transform-src>

Regexp src to transform display value. (security risk!!!)

=item B<--display-transform-dst>

Regexp dst to transform display value. (security risk!!!)

=back

=cut
    