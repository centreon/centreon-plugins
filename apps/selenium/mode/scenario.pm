###############################################################################
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
# permission to link this program with independent modules to produce an timeelapsedutable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting timeelapsedutable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Author : Simon BOMM <sbomm@merethis.com>
#
# Based on De Bodt Lieven plugin
####################################################################################

package apps::selenium::mode::scenario;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::httplib;
use XML::XPath;
use XML::XPath::XMLParser;
use WWW::Selenium;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
         {
         "selenium-hostname:s"  => { name => 'selenium_hostname', default => 'localhost' },
         "selenium-port:s"      => { name => 'selenium_port', default => '4444'},
         "browser:s"            => { name => 'browser', default => '*firefox'},
         "directory:s"          => { name => 'directory', default => '/var/lib/centreon_waa' },
         "scenario:s"           => { name => 'scenario' },
         "warning:s"            => { name => 'warning' },
         "critical:s"           => { name => 'critical' },
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $p = XML::Parser->new(NoLWP => 1);
    my $filename = $self->{option_results}->{directory} . '/' . $self->{option_results}->{scenario} . '.html';
    my $xp = XML::XPath->new(parser => $p, filename => $filename);

    my $baseurlNode = $xp->find('/html/head/link[@rel="selenium.base"]');
    my $baseurl = $baseurlNode->shift->getAttribute('href');

    my $listActionNode = $xp->find('/html/body/table/tbody/tr');

    my $sel = WWW::Selenium->new(
        host => $self->{option_results}->{selenium_hostname},
        port => $self->{option_results}->{selenium_port},
        browser => $self->{option_results}->{browser},
        browser_url => $baseurl
    );


    $sel->start;

    my $timing0 = [gettimeofday];
    my ($action, $filter, $value);
    my $step = $listActionNode->get_nodelist;
    my $stepOk = 0;
    my $exit1 = 'UNKNOWN';

    foreach my $actionNode ($listActionNode->get_nodelist) {
        ($action, $filter, $value) = $xp->find('./td', $actionNode)->get_nodelist;
        my $trim_action = centreon::plugins::misc::trim($action->string_value);
        my $trim_filter = centreon::plugins::misc::trim($filter->string_value);
        my $trim_value = centreon::plugins::misc::trim($value->string_value);
        if ($trim_action eq 'pause') {
            my $sleepTime = 1000;
            if ($trim_value =~ /^\d+$/) {
                $sleepTime = $trim_value;
            }
            if ($trim_filter =~ /^\d+$/) {
                $sleepTime = $trim_filter;
            }
            sleep($sleepTime / 1000);
            $stepOk++;
        } else {
            my $exit_command = $sel->do_command($trim_action, $trim_filter, $trim_value);
            $self->{output}->output_add(long_msg => "Step " . $step
                                                    . " - Command : '" . $trim_action . "'"
                                                    . " , Filter : '" . $trim_filter . "'"
                                                    . " , Value : '" . $trim_value . "'");
            if ($exit_command eq 'OK') {
                $exit1 = 'OK';
                $stepOk++;
            } else {
                $exit1 = 'CRITICAL';
                last;
            }
        }
    }
    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);

    my $availability = sprintf("%d", $stepOk * 100 / $step);


    my $exit2 = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                  threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%d/%d steps (%.3fs)", $stepOk, $step, $timeelapsed));
    $self->{output}->perfdata_add(label => "time",
                                  value => sprintf('%.3f', $timeelapsed),
                                  unit => 's',
                                  min => 0,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));

    $self->{output}->perfdata_add(label => "steps",
                                  value => sprintf('%d', $stepOk),
                                  min => 0,
                                  max => $step);

    $self->{output}->perfdata_add(label => "availability",
                                  unit => '%',
                                  value => sprintf('%d', $availability),
                                  min => 0,
                                  max => 100);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check scenario execution

=over 8

=item B<--selenium-hostname>

IP Addr/FQDN of the Selenium server

=item B<--selenium-port>

Port used by Selenium server

=item B<--browser>

Browser used by Selenium server (Default : '*firefox')

=item B<--directory>

Directory where scenarii are stored

=item B<--scenario>

Scenario used by Selenium server (without extension)

=item B<--warning>

Threshold warning in seconds (Scenario execution time)

=item B<--critical>

Threshold critical in seconds (Scenario execution response time)

=back

=cut
