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

package centreon::plugins::script;

use strict;
use warnings;
use centreon::plugins::output;
use centreon::plugins::misc;
use Pod::Usage;
use Pod::Find qw(pod_where);

my %handlers = (DIE => {}, ALRM => {});

my $global_version = '(dev)';
my $alternative_fatpacker = 0;

sub new {
    my ($class) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{options} = undef;
    $self->{plugin} = undef;
    $self->{help} = undef;

    # Avoid to destroy because it keeps a ref on the object. 
    # A problem if we execute it multiple times in the same perl execution
    # Use prepare_destroy
    $self->set_signal_handlers();
    return $self;
}

sub prepare_destroy {
    my ($self) = @_;

    %handlers = ();
}

sub set_signal_handlers {
    my ($self) = @_;

    $SIG{__DIE__} = \&class_handle_DIE;
    $handlers{DIE}->{$self} = sub { $self->handle_DIE($_[0]) };
}

sub class_handle_DIE {
    my ($msg) = @_;

    foreach (keys %{$handlers{DIE}}) {
        &{$handlers{DIE}->{$_}}($msg);
    }
}

sub class_handle_ALRM {
    foreach (keys %{$handlers{ALRM}}) {
        &{$handlers{ALRM}->{$_}}();
    }
}

sub handle_DIE {
    my ($self, $msg) = @_;

    return unless defined $^S and $^S == 0; # Ignore errors in eval
    $self->{output}->add_option_msg(short_msg => $msg);
    $self->{output}->die_exit();
}

sub handle_ALRM {
    my ($self) = @_;

    $self->{output}->add_option_msg(short_msg => 'script global timeout');
    $self->{output}->option_exit();
}

sub get_global_version {
    return $global_version;
}

sub get_plugin {
    my ($self) = @_;

    # Need to load global 'Output' and 'Options'
    if ($alternative_fatpacker == 0) {
        require centreon::plugins::options;
        $self->{options} = centreon::plugins::options->new();
    } else {
        require centreon::plugins::alternative::FatPackerOptions;
        $self->{options} = centreon::plugins::alternative::FatPackerOptions->new();
    }
    $self->{output} = centreon::plugins::output->new(options => $self->{options});
    $self->{options}->set_output(output => $self->{output});

    $self->{options}->add_options(arguments => {
        'plugin:s'          => { name => 'plugin' },
        'list-plugin'       => { name => 'list_plugin' }, 
        'help'              => { name => 'help' },
        'ignore-warn-msg'   => { name => 'ignore_warn_msg' },
        'version'           => { name => 'version' },
        'runas:s'           => { name => 'runas' },
        'global-timeout:s'  => { name => 'global_timeout' },
        'environment:s%'    => { name => 'environment' },
        'convert-args:s'    => { name => 'convert_args' },
    });

    $self->{options}->parse_options();

    $self->{plugin} = $self->{options}->get_option(argument => 'plugin');
    $self->{list_plugin} = $self->{options}->get_option(argument => 'list_plugin');
    $self->{help} = $self->{options}->get_option(argument => 'help');
    $self->{version} = $self->{options}->get_option(argument => 'version');
    $self->{runas} = $self->{options}->get_option(argument => 'runas');
    $self->{environment} = $self->{options}->get_option(argument => 'environment');
    $self->{ignore_warn_msg} = $self->{options}->get_option(argument => 'ignore_warn_msg');
    $self->{convert_args} = $self->{options}->get_option(argument => 'convert_args');

    my $global_timeout = $self->{options}->get_option(argument => 'global_timeout');
    if (defined($global_timeout) && $global_timeout =~ /(\d+)/) {
        $SIG{ALRM} = \&class_handle_ALRM;
        $handlers{ALRM}->{$self} = sub { $self->handle_ALRM() };
        alarm($1);
    }

    $self->{output}->plugin(name => $self->{plugin});
    $self->{output}->check_options(option_results => $self->{options}->get_options());

    $self->{options}->clean();
}

sub convert_args {
    my ($self) = @_;

    if ($self->{convert_args} =~ /^(.+?),(.*)/) {
        my ($search, $replace) = ($1, $2);
        for (my $i = 0; $i <= $#ARGV; $i++) {
            eval "\$ARGV[\$i] =~ s/$search/$replace/g";
        }
    }
}

sub display_local_help {
    my ($self) = @_;

    my $stdout;
    if ($self->{help}) {
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        
        if ($alternative_fatpacker == 0) {
            pod2usage(-exitval => 'NOEXIT', -input => pod_where({-inc => 1}, __PACKAGE__));
        } else {
            my $pp = __PACKAGE__ . '.pm';
            $pp =~ s{::}{/}g;
            my $content_class = $INC{$pp}->{$pp};
            open my $str_fh, '<', \$content_class;
            pod2usage(-exitval => 'NOEXIT', -input => $str_fh);
            close $str_fh;
        }
    }

    $self->{output}->add_option_msg(long_msg => $stdout) if (defined($stdout));
}

sub check_directory {
    my ($self, $directory) = @_;

    opendir(my $dh, $directory) || return ;
    while (my $filename = readdir $dh) {
        $self->check_directory($directory . '/' . $filename) if ($filename !~ /^\./ && -d $directory . '/' . $filename);
        if ($filename eq 'plugin.pm') {
            my $stdout = '';

            {
                local *STDOUT;
                open STDOUT, '>', \$stdout;
                pod2usage(
                    -exitval => 'NOEXIT',
                    -input => $directory . "/" . $filename,
                    -verbose => 99, 
                    -sections => 'PLUGIN DESCRIPTION'
                );
            }
            $self->{plugins_result}->{$directory . '/' . $filename} = $stdout;
        }
    }
    closedir $dh;
}

sub fatpacker_find_plugin {
    my ($self) = @_;
    
    my $plugins = [];
    foreach (@INC) {
        next if (ref($_) !~ /FatPacked/);
        foreach my $name (keys %$_) {
            if ($name =~ /plugin.pm$/) {
                push @$plugins, $name;
            }
        }
    }

    return $plugins;
}

sub check_plugin_option {
    my ($self) = @_;

    if (defined($self->{version})) {
        $self->{output}->add_option_msg(short_msg => 'Global Version: ' . $global_version);
        $self->{output}->option_exit(nolabel => 1);
    }

    my $no_plugin = 1;
    if ($alternative_fatpacker == 1) {
        my $integrated_plugins = $self->fatpacker_find_plugin();
        if (scalar(@$integrated_plugins) == 1) {
            $self->{plugin} = $integrated_plugins->[0];
            $no_plugin = 0;
        }
    }

    if ($no_plugin == 1) {
        $self->{output}->add_option_msg(short_msg => "Need to specify '--plugin' option.");
        $self->{output}->option_exit();
    }
}

sub display_list_plugin {
    my ($self) = @_;
    $self->{plugins_result} = {};

    if ($alternative_fatpacker == 1) {
        my $integrated_plugins = $self->fatpacker_find_plugin();

        foreach my $key (sort @$integrated_plugins) {
            # Need to load it to get the description
            centreon::plugins::misc::mymodule_load(
                output => $self->{output}, module => $key, 
                error_msg => 'Cannot load module --plugin.'
            );

            my $name = $key;
            $name =~ s/\.pm//g;
            $name =~ s/\//::/g;
            $self->{output}->add_option_msg(long_msg => '-----------------');
            $self->{output}->add_option_msg(long_msg => 'PLUGIN: ' . $name);
            {
                my $stdout = '';
                local *STDOUT;
                open STDOUT, '>', \$stdout;
                my $content_class = $INC{$key}->{$key};
                open my $str_fh, '<', \$content_class;
                pod2usage(-exitval => 'NOEXIT', -input => $str_fh, -verbose => 99, -sections => 'PLUGIN DESCRIPTION');
                close $str_fh;
                $self->{output}->add_option_msg(long_msg => $stdout);
            }
        }
        return ;
    }

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'FindBin', 
        error_msg => "Cannot load module 'FindBin'."
    );
    my $directory = $FindBin::Bin;
    if (defined($ENV{PAR_TEMP})) {
        $directory = $ENV{PAR_TEMP} . '/inc/lib';
    }
    # Search file 'plugin.pm'
    $self->check_directory($directory);
    foreach my $key (sort keys %{$self->{plugins_result}}) {
        my $name = $key;
        $name =~ s/^\Q$directory\E\/(.*)\.pm/$1/;
        $name =~ s/\//::/g;
        $self->{plugins_result}->{$key} =~ s/^Plugin Description/DESCRIPTION/i;

        $self->{output}->add_option_msg(long_msg => '-----------------');
        $self->{output}->add_option_msg(long_msg => 'PLUGIN: ' . $name);
        $self->{output}->add_option_msg(long_msg => $self->{plugins_result}->{$key});
    }
}

sub check_relaunch_get_args {
    my ($self) = @_;

    my $args = ['--plugin=' . $self->{plugin}, @ARGV];
    push @$args, '--ignore-warn-msg' if (defined($self->{ignore_warn_msg}));
    push @$args, '--help' if (defined($self->{help}));
    push @$args, '--global-timeout', $self->{global_timeout} if (defined($self->{global_timeout}));
    foreach ((
        ['output_xml', 0], ['output_json', 0], ['output_openmetrics', 0], 
        ['disco_format', 0], ['disco_show', 0], ['use_new_perfdata', 0], ['debug', 0], ['verbose', 0],
        ['range_perfdata', 1], ['filter_uom', 1], ['opt_exit', 1], ['filter_perfdata', 1],
        ['output_file', 1], ['float_precision', 1]
    )) {
        my $option = $self->{output}->get_option(option => $_->[0]);
        if (defined($option)) {
            my $option_label = $_->[0];
            $option_label =~ s/_/-/g;
            push @$args, "--$option_label" if ($_->[1] == 0);
            push @$args, "--$option_label", $option if ($_->[1] == 1);
        }
    }

    return $args;
}

sub check_relaunch {
    my $self = shift;

    centreon::plugins::misc::mymodule_load(
        output => $self->{output}, module => 'FindBin', 
        error_msg => "Cannot load module 'FindBin'."
    );

    my $need_restart = 0;
    my $cmd = $FindBin::Bin . '/' . $FindBin::Script;
    my $args = [];

    if (defined($self->{environment})) {
        foreach (keys %{$self->{environment}}) {
            if ($_ ne '' && (!defined($ENV{$_}) || $ENV{$_} ne $self->{environment}->{$_})) {
                $ENV{$_} = $self->{environment}->{$_};
                $need_restart = 1;
            }
        }
    }

    my $rebuild_args = $self->check_relaunch_get_args();

    if (defined($self->{runas}) && $self->{runas} ne '') {
        # Check if it's already me and user exist ;)
        my ($name, $passwd, $uid) = getpwnam($self->{runas});
        if (!defined($uid)) {
            $self->{output}->add_option_msg(short_msg => "Runas user '" . $self->{runas} . "' not exist.");
            $self->{output}->option_exit();
        }
        if ($uid != $>) {
            if ($> == 0) {
                unshift @$args, '-s', '/bin/bash', '-l', $self->{runas}, '-c', join(' ', $cmd, $rebuild_args);
                $cmd = 'su';
            } else {
                unshift @$args, '-S', '-u', $self->{runas}, $cmd, @$rebuild_args;
                $cmd = 'sudo';
            }
            $need_restart = 1;
        }
    }

    if ($need_restart == 1) {
        if (scalar(@$args) <= 0) {
            unshift @$args, @$rebuild_args;
        }

        my ($lerror, $stdout, $exit_code) = centreon::plugins::misc::backtick(
            command => $cmd,
            arguments => $args,
            timeout => 30,
            wait_exit => 1
        );

        if ($exit_code <= -1000) {
            if ($exit_code == -1000) {
                $self->{output}->output_add(
                    severity => 'UNKNOWN', 
                    short_msg => $stdout
                );
            }
            $self->{output}->display();
            $self->{output}->exit();
        }
        chomp $stdout;
        print $stdout . "\n";
        # We put unknown
        if (!($exit_code >= 0 && $exit_code <= 4)) {
            exit 3;
        }
        exit $exit_code;
    }
}

sub run {
    my ($self) = @_;

    $self->get_plugin();

    if (defined($self->{help}) && !defined($self->{plugin})) {
        $self->display_local_help();
        $self->{output}->option_exit();
    }
    if (defined($self->{list_plugin})) {
        $self->display_list_plugin();
        $self->{output}->option_exit();
    }
    $self->check_plugin_option() if (!defined($self->{plugin}) || $self->{plugin} eq '');
    if (defined($self->{ignore_warn_msg})) {
        $SIG{__WARN__} = sub {};
    }
    $self->convert_args() if (defined($self->{convert_args}));

    $self->check_relaunch();

    (undef, $self->{plugin}) = 
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => $self->{plugin}, 
                                               error_msg => 'Cannot load module --plugin.');
    my $plugin = $self->{plugin}->new(options => $self->{options}, output => $self->{output});
    $plugin->init(
        help => $self->{help},
        version => $self->{version}
    );
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

=item B<--global-timeout>

Set script timeout.

=item B<--environment>

Set environment variables for the script (prefer to set it before running it for better performance).

=item B<--convert-args>

Change strings of arguments. Useful to use '!' in nrpe protocol.
Example: --convert-args='##,\x21'

=back

=head1 DESCRIPTION

B<centreon_plugins.pl> .

=cut
