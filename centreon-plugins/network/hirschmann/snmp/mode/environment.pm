################################################################################
# Copyright 2005-2015 CENTREON
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
# As a special exception, the copyright holders of this program give CENTREON
# permission to link this program with independent modules to produce an executable,
# regardless of the license terms of these independent modules, and to copy and
# distribute the resulting executable under terms of CENTREON choice, provided that
# CENTREON also meet, for each linked independent module, the terms  and conditions
# of the license of that module. An independent module is a module which is not
# derived from this program. If you modify this program, you may extend this
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
#
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package network::hirschmann::snmp::mode::environment;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %fan_states = (
    1 => ['ok', 'OK'],
    2 => ['failed', 'CRITICAL'],
);

my %psu_states = (
    1 => ['ok', 'OK'],
    2 => ['failed', 'CRITICAL'],
    3 => ['notInstalled', 'UNKNOWN'],
    4 => ['unknown', 'UNKNOWN'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "exclude:s"        => { name => 'exclude' },
                                });

    $self->{components} = {};
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

    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};

    $self->check_fans();
    $self->check_psus();

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %d components [%d fans, %d power supplies] are ok",
                                ($self->{components}->{psu}->{total} + $self->{components}->{fan}->{total}),
                                $self->{components}->{fan}->{total}, $self->{components}->{psu}->{total}));

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_fans {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    return if ($self->check_exclude(section => 'fan'));

    my $oid_hmFanTable = '.1.3.6.1.4.1.248.14.1.3';
    my $oid_hmFanState = '.1.3.6.1.4.1.248.14.1.3.1.3';

    my $result = $self->{snmp}->get_table(oid => $oid_hmFanTable);
    return if (scalar(keys %$result) <= 0);

    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_hmFanState/);
        $oid =~ /\.([1-2]\.([0-8]))$/;
        my $fan_id = $1;
        my $instance = $2;

        my $fan_state = $result->{ $oid_hmFanState. '.' . $fan_id};

        next if ($self->check_exclude(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Fan '%s' state is %s.",
                                    $instance, ${$fan_states{$fan_state}}[0]));
        if (${$fan_states{$fan_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$fan_states{$fan_state}}[1],
                                        short_msg => sprintf("Fan '%s' state is %s.", $instance, ${$fan_states{$fan_state}}[0]));
        }
    }
}

sub check_psus {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    return if ($self->check_exclude(section => 'psu'));

    my $oid_hmPSTable = '.1.3.6.1.4.1.248.14.1.2';
    my $oid_hmPSState = '.1.3.6.1.4.1.248.14.1.2.1.3';

    my $result = $self->{snmp}->get_table(oid => $oid_hmPSTable);
    return if (scalar(keys %$result) <= 0);

    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_hmPSState/);
        $oid =~ /\.([1-2]\.([0-8]))$/;
        my $psu_id = $1;
        my $instance = $2;

        my $psu_state = $result->{ $oid_hmPSState. '.' . $psu_id};

        next if ($self->check_exclude(section => 'psu', instance => $instance));

        $self->{components}->{psu}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Power Supply '%s' state is %s.",
                                    $instance, ${$psu_states{$psu_state}}[0]));
        if (${$psu_states{$psu_state}}[1] ne 'OK') {
            $self->{output}->output_add(severity =>  ${$psu_states{$psu_state}}[1],
                                        short_msg => sprintf("Power Supply '%s' state is %s.", $instance, ${$fan_states{$psu_state}}[0]));
        }
    }
}

#sub check_exclude {
#    my ($self, $section) = @_;
#
#    if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$section(\s|,|$)/) {
#        $self->{output}->output_add(long_msg => sprintf("Skipping $section section."));
#        return 1;
#    }
#    return 0;
#}

sub check_exclude {
    my ($self, %options) = @_;

    if (defined($options{instance})) {
        if (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
            $self->{components}->{$options{section}}->{skip}++;
            $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance."));
            return 1;
        }
    } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
        $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section."));
        return 1;
    }
    return 0;
}



1;

__END__

=head1 MODE

Check Environment monitor (Fans, Power Supplies).

=over 8

=item B<--exclude>

Exclude some parts (comma seperated list) (Example: --exclude=psu)
Can also exclude specific instance: --exclude='psu#3.3#'

=back

=cut

