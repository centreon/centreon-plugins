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

package hardware::server::sun::mseries::mode::domains;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %error_status = (
    1 => ["The domain '%s' status is normal", 'OK'],
    2 => ["The domain '%s' status is degraded", 'WARNING'], 
    3 => ["The domain '%s' status is faulted", 'CRITICAL'],
    254 => ["The domain '%s' status has changed", 'WARNING'],
    255 => ["The domain '%s' status is unknown", 'UNKNOWN'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "skip"  => { name => 'skip' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    my $oid_scfDomainErrorStatus = '.1.3.6.1.4.1.211.1.15.3.1.1.5.2.1.15';
    my $oids_domain_status = $self->{snmp}->get_table(oid => $oid_scfDomainErrorStatus, nothing_quit => 1);
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All domains are ok.");
    foreach ($self->{snmp}->oid_lex_sort(keys %$oids_domain_status)) {
        /^${oid_scfDomainErrorStatus}\.(.*)/;
        my $domain_id = $1;
        $self->{output}->output_add(long_msg => sprintf(${$error_status{$oids_domain_status->{$_}}}[0], $domain_id));
        if ($oids_domain_status->{$_} == 255 && defined($self->{option_results}->{skip})) {
            next;
        }
        if ($oids_domain_status->{$_} != 1) {
            $self->{output}->output_add(severity => ${$error_status{$oids_domain_status->{$_}}}[1],
                                        short_msg => sprintf(${$error_status{$oids_domain_status->{$_}}}[0], $domain_id));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Mseries domains status.

=over 8

=item B<--skip>

Skip 'unknown' domains.

=back

=cut
    