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

package storage::panzura::snmp::mode::ratios;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    dedup   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'dedup' }, ],
                        output_template => 'Deduplication ratio : %.2f',
                        perfdatas => [
                            { value => 'dedup_absolute', template => '%.2f', min => 0 },
                        ],
                    }
               },
    comp   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'comp' }, ],
                        output_template => 'Compression ratio : %.2f',
                        perfdatas => [
                            { value => 'comp_absolute', template => '%.2f', min => 0 },
                        ],
                    }
               },
    save   => { class => 'centreon::plugins::values', obj => undef,
                set => {
                        key_values => [ { name => 'save' }, ],
                        output_template => 'Save ratio : %.2f',
                        perfdatas => [
                            { value => 'save_absolute', template => '%.2f', min => 0 },
                        ],
                    }
               },
};

my $oid_dedupRatio = '.1.3.6.1.4.1.32853.1.3.1.5.1.0';
my $oid_compRatio = '.1.3.6.1.4.1.32853.1.3.1.6.1.0';
my $oid_saveRatio = '.1.3.6.1.4.1.32853.1.3.1.7.1.0';

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);  
    foreach (keys %{$maps_counters}) {
        $options{options}->add_options(arguments => {
                                                     'warning-' . $_ . ':s'    => { name => 'warning-' . $_ },
                                                     'critical-' . $_ . ':s'    => { name => 'critical-' . $_ },
                                      });
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(statefile => $self->{statefile_value},
                                                  output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $_);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }    
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
  
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'All ratios are ok');
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $maps_counters->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $self->{output}->output_add(long_msg => $output);
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "$short_msg"
                                    );
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $request = [$oid_dedupRatio, $oid_compRatio, $saveRatio];
    
    $self->{results} = $self->{snmp}->get_leef(oids => $request, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{dedup} = defined($self->{results}->{$oid_dedupRatio}) ? $self->{results}->{$oid_dedupRatio} / 100 : 0;
    $self->{global}->{comp} = defined($self->{results}->{$oid_compRatio}) ? $self->{results}->{$oid_compRatio} / 100 : 0;
    $self->{global}->{save} = defined($self->{results}->{$saveRatio}) ? $self->{results}->{$saveRatio} / 100 : 0;
}

1;

__END__

=head1 MODE

Check deduplication, compression and save ratios (panzura-systemext).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'dedup', 'comp', 'save'.

=item B<--critical-*>

Threshold critical.
Can be: 'dedup', 'comp', 'save'.

=back

=cut
    