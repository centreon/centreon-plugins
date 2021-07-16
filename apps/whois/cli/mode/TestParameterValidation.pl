
use strict;
use warnings;
use DateTime;
use DateTime::TimeZone;
use Getopt::Long;

#Default Values
my $map = "YMD000";
my $custom_regex = 'Update\s+(\d{4})-(\d{2})-(\d{2})';
my $timestamp = "";

GetOptions (
    "timestamp=s" => \$timestamp,
    "regex=s"     => \$custom_regex,
    "map=s"       => \$map)
or die("Error in command line arguments\n");

my $opening_groups = ($custom_regex =~ tr/\(//);
my $closing_groups = ($custom_regex =~ tr/\)//);

my $MinGroupCount = 3;

# Test groups and count of groups in regex
if ($opening_groups < $MinGroupCount) {
    print("Error. At least 3 groups needed on regex. found: " . $opening_groups);
    print("\n");
}
if ($opening_groups != $closing_groups) {
    print("Error. count of opening and closing parenthesis differ in regex: " . $opening_groups .'<>'. $closing_groups);
    print("\n");
}
print($custom_regex);
print("\n");

# Test YMD pressence in map
print ($map =~ /Y/);
print("\n");
print ($map =~ /M/);
print("\n");
print ($map =~ /D/);
print("\n");
unless ($map =~ /Y/ && $map =~ /D/ && $map =~ /M/) {
    print ("Error. Y, M and D must be on regex map for the timestamp");
    print("\n");
}

print ($map =~ tr/YMD//)
