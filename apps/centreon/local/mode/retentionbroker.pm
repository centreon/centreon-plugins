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
    
    $options{options}->add_options(arguments => {
        'broker-config:s@' => { name => 'broker_config' },
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
                                short_msg => 'centreon-broker failover/temporary files are ok');
    
    my $total_size = 0;
    foreach my $config (@{$self->{option_results}->{broker_config}}) {
        $self->{output}->output_add(long_msg => "Checking config '$config'");
        
        if (! -f $config or ! -r $config) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "'$config': not a file or cannot be read"
            );
            next;
        }
        
        my $parser = XML::LibXML->new();
        my $xml;
        eval {
            $xml = $parser->parse_file($config);
        };
        if ($@) {
            $self->{output}->output_add(
                severity => 'UNKNOWN',
                short_msg => "'$config': cannot parse xml"
            );
            next;
        }
        my %failover_found = ();
        my %file_found = ();
        my $temporary;
        foreach my $node ($xml->findnodes('/centreonBroker/output')) {
            my %load = ();
            foreach my $element ($node->getChildrenByTagName('*')) {
                if ($element->nodeName eq 'failover') {
                    $failover_found{$element->textContent} = 1;
                } elsif ($element->nodeName =~ /^(name|type|path)$/) {
                    $load{$element->nodeName} = $element->textContent;
                }
            }
            if (defined($load{type}) && $load{type} eq 'file') {
                $file_found{$load{name}} = {%load};
            }
        }
        
        foreach my $node ($xml->findnodes('/centreonBroker/temporary')) {
            foreach my $element ($node->getChildrenByTagName('path')) {
                $temporary = $element->textContent;
            }
        }
        
        # Check failovers
        my $current_total = 0;
        foreach my $failover (sort keys %failover_found) {
            next if (!defined($file_found{$failover}));
            
            my ($status, $total, $size) = $self->check_directory(config => $config, path => $file_found{$failover}->{path});
            next if (!$status);
            
            $current_total += $total;
            $total_size += $size;            
            my ($size_value, $size_unit) = $self->{perfdata}->change_bytes(value => $size);
            $self->{output}->output_add(long_msg => sprintf("failover '%s': %d file(s) found (%s)", 
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
            $self->{output}->output_add(long_msg => sprintf("temporary: %d file(s) found (%s)", 
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
