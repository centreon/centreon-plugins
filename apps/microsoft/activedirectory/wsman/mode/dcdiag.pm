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

package apps::microsoft::activedirectory::wsman::mode::dcdiag;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use File::Basename;
use XML::LibXML;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "config:s"   => { name => 'config' },
        "language:s" => { name => 'language', default => 'en' },
        "dfsr"       => { name => 'dfsr' },
        "noeventlog" => { name => 'noeventlog' }
    });

    $self->{os_is2003} = 0;
    $self->{os_is2008} = 0;
    $self->{os_is2012} = 0;
    
    $self->{msg} = {ok => undef, warning => undef, critical => undef};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    if (defined($self->{option_results}->{config})) {
        $self->{config_file} = $self->{option_results}->{config};
    } else {
        $self->{config_file} = dirname(__FILE__) . '/../conf/dcdiag.xml';
    }
}

sub check_version {
    my ($self, %options) = @_;

    $self->{result} = $self->{wsman}->execute_winshell_commands(commands => [{label => 'os_version', value => 'ver' }],
                                                                keep_open => 1);
    if ($self->{result}->{os_version}->{exit_code} != 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Problem execution to get OS version (use verbose for more details)');
        $self->{output}->output_add(long_msg => 'stderr: ' . $self->{result}->{os_version}->{stderr}) if (defined($self->{result}->{os_version}->{stderr}));
        $self->{output}->output_add(long_msg => 'stdout: ' . $self->{result}->{os_version}->{stdout}) if (defined($self->{result}->{os_version}->{stdout}));        
        return 1;
    }
    
    if ($self->{result}->{os_version}->{stdout} !~ /(\d+\.\d+\.\d+)/) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find OS version in output');
        return 1;
    }
    
    # 5.1, 5.2 => XP/2003
    # 6.0, 6.1 => Vista/7/2008
    # 6.2, 6.3 => 2012
    my $os_version = $1;
    if ($os_version =~ /^(5\.1\.|5\.2\.)/) {
        $self->{os_is2003} = 1;
    } elsif ($os_version =~ /^(6\.0\.|6\.1\.)/) {
        $self->{os_is2008} = 1;
    } elsif ($os_version =~ /^(6\.2\.|6\.3\.)/) {
        $self->{os_is2012} = 1;
    } else {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'OS version ' . $os_version . ' not managed.');
        return 1;
    }
    return 0;
}

sub load_xml {
    my ($self, %options) = @_;

    # Load XML File
    my $parser = XML::LibXML->new();
    my $doc = $parser->parse_file($self->{config_file});
    my $nodes = $doc->getElementsByTagName('dcdiag');
    if ($nodes->size() == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find a <dcdiag> node in XML Config file');
        return 1;
    }
    
    my $language_found = 0;
    foreach my $node ($nodes->get_nodelist()) {
        if ($node->getAttribute('language') eq $self->{option_results}->{language}) {
            $language_found = 1;
            my $messages_node = $node->getElementsByTagName('messages');
            foreach my $node2 ($messages_node->get_nodelist()) {
                foreach my $element_msg ($node2->getChildrenByTagName('*')) {
                    $self->{msg}->{$element_msg->nodeName} = $element_msg->textContent if (exists($self->{msg}->{$element_msg->nodeName}));
                }
            }
            last;
        }
    }
    
    if ($language_found == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Cannot found language '" . $self->{option_results}->{language} . "' in XML Config file");
        return 1;
    }
    
    foreach my $label (keys %{$self->{msg}}) {
        if (!defined($self->{msg}->{$label})) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "Message '" . $label . "' for language '" . $self->{option_results}->{language} . "' not defined in XML Config file");
            return 1;
        }
    }
        
    return 0;
}

sub dcdiag {
    my ($self, %options) = @_;

    my $dcdiag_cmd = 'dcdiag /test:services /test:replications /test:advertising /test:fsmocheck /test:ridmanager /test:machineaccount';
    $dcdiag_cmd .= ' /test:frssysvol' if ($self->{os_is2003} == 1);
    $dcdiag_cmd .= ' /test:sysvolcheck' if ($self->{os_is2008} == 1 || $self->{os_is2012} == 1);
    
    if (!defined($self->{option_results}->{noeventlog})) {
        $dcdiag_cmd .= ' /test:frsevent /test:kccevent' if ($self->{os_is2003} == 1);
        $dcdiag_cmd .= ' /test:frsevent /test:kccevent' if (($self->{os_is2008} == 1 || $self->{os_is2012} == 1) && !defined($self->{option_results}->{dfsr}));
        $dcdiag_cmd .= ' /test:dfsrevent /test:kccevent' if (($self->{os_is2008} == 1 || $self->{os_is2012} == 1) && defined($self->{option_results}->{dfsr}));
    }
    
    $self->{result} = $self->{wsman}->execute_winshell_commands(commands => [{label => 'dcdiag', value => $dcdiag_cmd }]);
    if ($self->{result}->{dcdiag}->{exit_code} != 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Problem execution of dcdiag (use verbose for more details)');
        $self->{output}->output_add(long_msg => 'stderr: ' . $self->{result}->{dcdiag}->{stderr}) if (defined($self->{result}->{dcdiag}->{stderr}));
        $self->{output}->output_add(long_msg => 'stdout: ' . $self->{result}->{dcdiag}->{stdout}) if (defined($self->{result}->{dcdiag}->{stdout}));        
        return 1;
    }
    
    my $match = 0;
    foreach my $line (split /\n/, $self->{result}->{os_version}->{stdout}) {
        if ($line =~ /$self->{msg}->{ok}/) {
            $match = 1;
            $self->{output}->output_add(severity => 'OK',
                                        short_msg => $1);
        } elsif ($line =~ /$self->{msg}->{critical}/) {
            $match = 1;
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => 'test ' . $1);
        } elsif ($line =~ /$self->{msg}->{warning}/) {
            $match = 1;
            $self->{output}->output_add(severity => 'WARNING',
                                        short_msg => 'test ' . $1);
        }
    }
    
    if ($match == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot match output test (maybe you need to set the good language)');
        return 1;
    }
    
    return 0;
}

sub run {
    my ($self, %options) = @_;
    # $options{wsman} = wsman object
    $self->{wsman} = $options{wsman};

    if ($self->load_xml() == 0 && $self->check_version() == 0) {
        $self->dcdiag();
    }
   
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Windows Active Directory Health (use 'dcdiag' command).

=over 8

=item B<--config>

command can be localized by using a configuration file.
This parameter can be used to specify an alternative location for the configuration file

=item B<--language>

Set the language used in config file (default: 'en').

=item B<--dfsr>

Specifies that SysVol replication uses DFS instead of FRS (Windows 2008 or later)

=item B<--noeventlog>

Don't run the dc tests kccevent, frsevent and dfsrevent

=back

=cut
