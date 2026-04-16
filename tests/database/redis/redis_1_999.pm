package Redis;

# Fake Redis class < 2.00: only single-parameter auth is supported

$INC{'Redis.pm'}="fake.pm";

$Redis::VERSION = '1.999';

sub new
{
    my ($class, %options) = @_;
    bless ({}, $class);
}

sub info { }
sub auth($) { }
sub quit() { }

1;
