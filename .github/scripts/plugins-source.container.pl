#!/usr/bin/env perl

use App::FatPacker;
use File::Copy::Recursive;
use File::Path;
use File::Basename;
use JSON;
use Cwd qw(getcwd);

my $pwd = (getcwd . '/');
my $plugins_dir = ($pwd . 'src');
my $packaging_dir = ($pwd . 'packaging');
my $build_dir = ($pwd . 'build');

# Prepare destination directory.
File::Path::remove_tree($build_dir);
File::Path::make_path($build_dir);


# Set version within sources.
my $plugins = $ARGV[0];
my $global_version = $ARGV[1];
do {
    local $^I = '.bak';
    local @ARGV = ($plugins_dir . '/centreon/plugins/script.pm');
    while (<>) {
        s/^my \$global_version = .*$/my \$global_version = '$global_version';/ig;
        print;
    }
};
do {
    local $^I = '.bak';
    local @ARGV = ($plugins_dir . '/centreon/plugins/script.pm');
    while (<>) {
        s/^my \$alternative_fatpacker = 0;$/my \$alternative_fatpacker = 1;/ig;
        print;
    }
};

chdir($packaging_dir);

my @plugins = split / /, $plugins;
foreach my $plugin (@plugins) {
    chdir($packaging_dir);

    # Load plugin configuration file.
    my $package_path = $plugin;
    if (! -f $package_path . '/pkg.json') {
        if ($package_path =~ /(.+)=>(.+)/) {
            $package_path = $1;
            $plugin = $2;
        }
    }

    if (-f $package_path . '/pkg.json') {
        my $plugin_build_dir = $build_dir . '/' . $plugin;
        File::Path::make_path($plugin_build_dir);

        open($fh, '<', $package_path . '/pkg.json');
        my $json_content = do { local $/; <$fh> };
        close($fh);
        $config = JSON::decode_json($json_content);

        # Prepare plugin layout.
        chdir($plugins_dir);
        File::Path::remove_tree('lib');
        File::Path::make_path('lib');
        my @common_files = (
            'centreon/plugins/http.pm',
            'centreon/plugins/misc.pm',
            'centreon/plugins/mode.pm',
            'centreon/plugins/multi.pm',
            'centreon/plugins/options.pm',
            'centreon/plugins/output.pm',
            'centreon/plugins/perfdata.pm',
            'centreon/plugins/script.pm',
            'centreon/plugins/statefile.pm',
            'centreon/plugins/values.pm',
            'centreon/plugins/backend/http/curl.pm',
            'centreon/plugins/backend/http/curlconstants.pm',
            'centreon/plugins/backend/http/lwp.pm',
            'centreon/plugins/backend/http/useragent.pm',
            'centreon/plugins/alternative/Getopt.pm',
            'centreon/plugins/alternative/FatPackerOptions.pm',
            'centreon/plugins/passwordmgr/centreonvault.pm',
            'centreon/plugins/passwordmgr/environment.pm',
            'centreon/plugins/passwordmgr/file.pm',
            'centreon/plugins/passwordmgr/hashicorpvault.pm',
            'centreon/plugins/passwordmgr/keepass.pm',
            'centreon/plugins/passwordmgr/teampass.pm',
            'centreon/plugins/templates/catalog_functions.pm',
            'centreon/plugins/templates/counter.pm',
            'centreon/plugins/templates/hardware.pm'
        );
        foreach my $file ((@common_files, @{$config->{files}})) {
            if (-f $file) {
                File::Copy::Recursive::fcopy($file, 'lib/' . $file);
            } elsif (-d $file) {
                File::Copy::Recursive::dircopy($file, 'lib/' . $file);
            }
        }
        # Remove __END__ for Centreon Connector Perl compatibility.
        system 'find', 'lib', '-name', '*.pm', '-exec', 'sed', '-i', ' /__END__/d', '{}', ';';

        # Fatpack plugin.
        my $fatpacker = App::FatPacker->new();
        my $content = $fatpacker->fatpack_file("centreon_plugins.pl");
        open($fh, '>', "$plugin_build_dir/$config->{plugin_name}");
        print $fh $content;
        close($fh);
        chmod 0755, "$plugin_build_dir/$config->{plugin_name}"; # Add execution permission
    }
}
