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
# Authors : Simon BOMM <sbomm@centreon.com>
#
####################################################################################

package apps::centreon::local::mode::retentionbroker;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use XML::LibXML;
use File::Basename;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                 "broker-config:s@"     => { name => 'broker_config' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
 
    if (!defined($self->{option_results}->{broker_config}) || scalar(@{$self->{option_results}->{broker_config}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Please set broker-config option.");
        $self->{output}->option_exit();
    }
}

sub check_directory {
    my ($self, %options) = @_;
    
    my ($current_total, $current_size) = (0, 0);
    my $dirname = dirname($options{path});
    my $basename = basename($options{path});
    my $dh;
    if (!opendir($dh, $dirname)) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "'$options{config}': cannot open directory '$dirname'");
        return 0;
    }
    while (my $file = readdir($dh)) {
        if ($file =~ /^$basename\d*$/) {
            $current_total++;
            $current_size += -s $dirname . '/' . $file;
        }
    }
    closedir $dh;
    return (1, $current_total, $current_size);
}

sub run {
    my ($self, %options) = @_;
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'centreon-broker failover files and tempory are ok');
    
    my $total_size = 0;
    foreach my $config (@{$self->{option_results}->{broker_config}}) {
        $self->{output}->output_add(long_msg => "Checking config '$config'");
        
        if (! -f $config or ! -r $config) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "'$config': not a file or cannot be read");
            next;
        }
        
        my $parser = XML::LibXML->new();
        my $xml;
        eval {
            $xml = $parser->parse_file($config);
        };
        if ($@) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "'$config': cannot parse xml");
            next;
        }
        my %failover_finded = ();
        my %file_finded = ();
        my $temporary;
        foreach my $node ($xml->findnodes('/centreonBroker/output')) {
            my %load = ();
            foreach my $element ($node->getChildrenByTagName('*')) {
                if ($element->nodeName eq 'failover') {
                    $failover_finded{$element->textContent} = 1;
                } elsif ($element->nodeName =~ /^(name|type|path)$/) {
                    $load{$element->nodeName} = $element->textContent;
                }
            }
            if (defined($load{type}) && $load{type} eq 'file') {
                $file_finded{$load{name}} = {%load};
            }
        }
        
        foreach my $node ($xml->findnodes('/centreonBroker/temporary')) {
            foreach my $element ($node->getChildrenByTagName('path')) {
                $temporary = $element->textContent;
            }
        }
        
        # Check failovers
        my $current_total = 0;
        foreach my $failover (sort keys %failover_finded) {
            next if (!defined($file_finded{$failover}));
            
            my ($status, $total, $size) = $self->check_directory(config => $config, path => $file_finded{$failover}->{path});
            next if (!$status);
            
            $current_total += $total;
            $total_size += $size;            
            my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
            $self->{output}->output_add(long_msg => sprintf("failover '%s': %d file(s) finded (%s)", 
                                                            $failover, $total, $size_value . ' ' . $size_unit));
        }
        
        if ($current_total > 0) {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Some failover(s) are active"));
        }
        
        # Check temporary
        if (!defined($temporary)) {
            $self->{output}->output_add(long_msg => "skipping temporary: no configuration set");
            next;
        }
        my ($status, $total, $size) = $self->check_directory(config => $config, path => $temporary);
        if ($status) {
            my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
            $self->{output}->output_add(long_msg => sprintf("temporary: %d file(s) finded (%s)", 
                                                            $total, $size_value . ' ' . $size_unit));
            if ($total > 0) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => sprintf("Temporary is active"));
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check failover file retention or temporary is active.

=over 8

=item B<--broker-config>

Specify the centreon-broker config (Required). Can be multiple.

=back

=cut
