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

package centreon::plugins::script;

use strict;
use warnings;
use centreon::plugins::options;
use centreon::plugins::output;
use centreon::plugins::misc;
use FindBin;
use Pod::Usage;
use Pod::Find qw(pod_where);

my %handlers = (DIE => {});

my $global_version = 20160122;

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;

    $self->{options} = undef;
    $self->{plugin} = undef;
    $self->{help} = undef;

    # Avoid to destroy because it keeps a ref on the object. 
    # A problem if we execute it multiple times in the same perl execution
    # Use prepare_destroy
    $self->set_signal_handlers;
    return $self;
}

sub prepare_destroy {
    my $self = shift;

    delete $handlers{DIE}->{$self};
}

sub set_signal_handlers {
    my $self = shift;

    $SIG{__DIE__} = \&class_handle_DIE;
    $handlers{DIE}->{$self} = sub { $self->handle_DIE($_[0]) };
}

sub class_handle_DIE {
    my ($msg) = @_;

    foreach (keys %{$handlers{DIE}}) {
        &{$handlers{DIE}->{$_}}($msg);
    }
}

sub handle_DIE {
    my ($self, $msg) = @_;

    return unless defined $^S and $^S == 0; # Ignore errors in eval
    $self->{output}->add_option_msg(short_msg => $msg);
    $self->{output}->die_exit();
}

sub get_plugin {
    my $self = shift;
    
    ######
    # Need to load global 'Output' and 'Options'
    ######
    $self->{options} = centreon::plugins::options->new();
    $self->{output} = centreon::plugins::output->new(options => $self->{options});
    $self->{options}->set_output(output => $self->{output});

    $self->{options}->add_options(arguments => {
                                                'plugin:s'          => { name => 'plugin' },
                                                'list-plugin'       => { name => 'list_plugin' }, 
                                                'help'              => { name => 'help' },
                                                'ignore-warn-msg'   => { name => 'ignore_warn_msg' },
                                                'version'           => { name => 'version' },
                                                'runas:s'           => { name => 'runas' },
                                                'environment:s%'    => { name => 'environment' },
                                                } );

    $self->{options}->parse_options();

    $self->{plugin} = $self->{options}->get_option(argument => 'plugin' );
    $self->{list_plugin} = $self->{options}->get_option(argument => 'list_plugin' );
    $self->{help} = $self->{options}->get_option(argument => 'help' );
    $self->{version} = $self->{options}->get_option(argument => 'version' );
    $self->{runas} = $self->{options}->get_option(argument => 'runas' );
    $self->{environment} = $self->{options}->get_option(argument => 'environment' );
    $self->{ignore_warn_msg} = $self->{options}->get_option(argument => 'ignore_warn_msg' );

    $self->{output}->mode(name => $self->{mode});
    $self->{output}->plugin(name => $self->{plugin});
    $self->{output}->check_options(option_results => $self->{options}->get_options());

    $self->{options}->clean();
}

sub display_local_help {
    my $self = shift;

    my $stdout;
    if ($self->{help}) {
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        pod2usage(-exitval => "NOEXIT", -input => pod_where({-inc => 1}, __PACKAGE__));
    }
    
    $self->{output}->add_option_msg(long_msg => $stdout) if (defined($stdout));
}

sub check_directory {
    my ($self, $directory) = @_;
    
    opendir(my $dh, $directory) || return ;
    while (my $filename = readdir $dh) {
        $self->check_directory($directory . "/" . $filename) if ($filename !~ /^\./ && -d $directory . "/" . $filename);
        if ($filename eq 'plugin.pm') {
            my $stdout = '';
            
            {
                local *STDOUT;
                open STDOUT, '>', \$stdout;
                pod2usage(-exitval => 'NOEXIT', -input => $directory . "/" . $filename,
                          -verbose => 99, 
                          -sections => "PLUGIN DESCRIPTION");
            }
            $self->{plugins_result}->{$directory . "/" . $filename} = $stdout;
        }
    }
    closedir $dh;
}

sub display_list_plugin {
    my $self = shift;
    $self->{plugins_result} = {};
    
    # Search file 'plugin.pm'
    $self->check_directory($FindBin::Bin);
    foreach my $key (keys %{$self->{plugins_result}}) {
        my $name = $key;
        $name =~ s/^$FindBin::Bin\/(.*)\.pm/$1/;
        $name =~ s/\//::/g;
        $self->{plugins_result}->{$key} =~ s/^Plugin Description/DESCRIPTION/i;
        
        $self->{output}->add_option_msg(long_msg => '-----------------');
        $self->{output}->add_option_msg(long_msg => 'PLUGIN: ' . $name);
        $self->{output}->add_option_msg(long_msg => $self->{plugins_result}->{$key});
    }
}

sub check_relaunch {
    my $self = shift;
    my $need_restart = 0;
    my $cmd = $FindBin::Bin . "/" . $FindBin::Script;
    my @args = ();
    
    if (defined($self->{environment})) {
        foreach (keys %{$self->{environment}}) {
            if ($_ ne '' && (!defined($ENV{$_}) || $ENV{$_} ne $self->{environment}->{$_})) {
                $ENV{$_} = $self->{environment}->{$_};
                $need_restart = 1;
            }
        }
    }
    
    if (defined($self->{runas}) && $self->{runas} ne '') {
        # Check if it's already me and user exist ;)
        my ($name, $passwd, $uid) = getpwnam($self->{runas});
        if (!defined($uid)) {
            $self->{output}->add_option_msg(short_msg => "Runas user '" . $self->{runas} . "' not exist.");
            $self->{output}->option_exit();
        }
        if ($uid != $>) {
            if ($> == 0) {
                unshift @args, "-s", "/bin/bash", "-l", $self->{runas}, "-c", join(" ", $cmd, "--plugin=" . $self->{plugin}, @ARGV);
                $cmd = "su";
            } else {
                unshift @args, "-S", "-u", $self->{runas}, $cmd, "--plugin=" . $self->{plugin}, @ARGV;
                $cmd = "sudo";
            }
            $need_restart = 1;
        }
    }

    if ($need_restart == 1) {
        if (scalar(@args) <= 0) {
            unshift @args, @ARGV, "--plugin=" . $self->{plugin}
        }

        my ($lerror, $stdout, $exit_code) = centreon::plugins::misc::backtick(
                                                 command => $cmd,
                                                 arguments => [@args],
                                                 timeout => 30,
                                                 wait_exit => 1
                                                 );
        if ($exit_code <= -1000) {
            if ($exit_code == -1000) {
                $self->{output}->output_add(severity => 'UNKNOWN', 
                                            short_msg => $stdout);
            }
            $self->{output}->display();
            $self->{output}->exit();
        }
        print $stdout;
        # We put unknown
        if (!($exit_code >= 0 && $exit_code <= 4)) {
            exit 3;
        }
        exit $exit_code;
    }
}

sub run {
    my $self = shift;

    $self->get_plugin();

    if (defined($self->{help}) && !defined($self->{plugin})) {
        $self->display_local_help();
        $self->{output}->option_exit();
    }
    if (defined($self->{list_plugin})) {
        $self->display_list_plugin();
        $self->{output}->option_exit();
    }
    if (!defined($self->{plugin}) || $self->{plugin} eq '') {
        if (defined($self->{version})) {
            $self->{output}->add_option_msg(short_msg => "Global Version: " . $global_version);
            $self->{output}->option_exit(nolabel => 1);
        }
        $self->{output}->add_option_msg(short_msg => "Need to specify '--plugin' option.");
        $self->{output}->option_exit();
    }
    if (defined($self->{ignore_warn_msg})) {
        $SIG{__WARN__} = sub {};
    }

    $self->check_relaunch();
    
    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $self->{plugin}, 
                                           error_msg => "Cannot load module --plugin.");
    my $plugin = $self->{plugin}->new(options => $self->{options}, output => $self->{output});
    $plugin->init(help => $self->{help},
                  version => $self->{version});
    $plugin->run();
}

1;

__END__

=head1 NAME

centreon_plugins.pl - main program to call Centreon plugins.

=head1 SYNOPSIS

centreon_plugins.pl [options]

=head1 OPTIONS

=over 8

=item B<--plugin>

Specify the path to the plugin.

=item B<--list-plugin>

Print available plugins.

=item B<--version>

Print global version.

=item B<--help>

Print a brief help message and exits.

=item B<--ignore-warn-msg>

Perl warn messages are ignored (not displayed).

=item B<--runas>

Run the script as a different user (prefer to use directly the good user).

=item B<--environment>

Set environment variables for the script (prefer to set it before running it for better performance).

=back

=head1 DESCRIPTION

B<centreon_plugins.pl> .

=cut
