
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

#https://www.tutorialspoint.com/grouping-matching-in-perl
#my ($hours, $minutes, $seconds) = ($time =~ m/(\d+):(\d+):(\d+)/);

# https://perldoc.perl.org/perlretut#Position-information
# position information 
# $-[n] is the position of the start of the $n match
# $+[n] is the position of the end

## Timezone support is poor at best.

### Match Date time fields
# Default Date
my %map_fields = (
    'Y' => 1,
    'M' => 2,
    'D' => 3,
    'h' => 99,
    'm' => 99,
    's' => 99,
    'Z' => 99,
);
my $hour=0;
my $minute=0;
my $second=0;
my $time_zone='UTC';
my $TZ = DateTime::TimeZone->new( name => 'UTC' );

# Update date fields maps
for (keys %map_fields) {
    my $key = $_;
    if ($map =~ /($key)/) {
        $map_fields{$key} = $-[0];
    }
}
# Create Variables for datetime object  
if ($timestamp =~ /$custom_regex/) {
    my @regex_groups = ($timestamp =~ /$custom_regex/);
    my $year = $regex_groups[$map_fields{'Y'}];
    my $month = $regex_groups[$map_fields{'M'}];
    my $day = $regex_groups[$map_fields{'D'}];
    if ($map_fields{'h'} <= scalar @regex_groups) {
        $hour = $regex_groups[$map_fields{'h'}];
    }
    if ($map_fields{'m'} <= scalar @regex_groups) {
        $minute = $regex_groups[$map_fields{'m'}];
    }
    if ($map_fields{'s'} <= scalar @regex_groups) {
        $second = $regex_groups[$map_fields{'s'}];
    }
    if ($map_fields{'Z'} <= scalar @regex_groups) {
        $time_zone = $regex_groups[$map_fields{'Z'}];
        print("time zone string: " . $time_zone . ".\n");
        $TZ = DateTime::TimeZone->new( name => $time_zone );
        print("time zone Object: " . $TZ . ".\n");
    }
    my $dateObject = DateTime->new(
        year      => $year,
        month     => $month,
        day       => $day,
        hour      => $hour,
        minute    => $minute,
        second    => $second,
        time_zone => $TZ
    );
    print ("Datetime: ");
    print ($dateObject->datetime);
    print ("\n");
    print ($TZ->offset_for_datetime($dateObject));
    print ("\n");
    print ($dateObject + $TZ)->datetime;
    print ("\n");
}
