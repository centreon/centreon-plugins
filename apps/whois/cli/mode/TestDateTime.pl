
use strict;
use warnings;
use DateTime;
my $SECONDS_PER_DAY = 86400;
my $endTime = DateTime->new(
    year      => 2028,
    month     => 9,
    day       => 14,
    hour      => 4,
    minute    => 0,
    second    => 0,
    time_zone => 'UTC',
)->epoch;
#print($endTime->datetime);
#print('/n');
my $nowTime = DateTime->now(time_zone => 'UTC')->epoch;
#print($nowTime->datetime);
#print('/n');
my $delta_seconds = $endTime - $nowTime;


print("Epoch Seconds: \n");
print($endTime);
print("\n");

print("Now Seconds: \n");
print($nowTime);
print("\n");

print("Delta Seconds: \n");
print($delta_seconds);
print("\n");

print("Remaining Days: \n");
print(int($delta_seconds / $SECONDS_PER_DAY));
print("\n");

