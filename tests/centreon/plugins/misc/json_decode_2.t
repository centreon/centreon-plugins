use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings echo => 1;
use FindBin;
use lib "$FindBin::RealBin/../../../../src";
use centreon::plugins::misc;
use JSON::XS;

my $files = $FindBin::RealBin . "/json_decode";

# Test centreon::plugins::misc::json_decode function

my $error_msg;

# Copy of the original json_decode result to verify that the new one produces identical values
# The old function will fail to decode streams that the new one will successfully handle
sub legacy_json_decode
{
    my ($content, %options) = @_;
    $error_msg = '';

    $content =~ s/\r//mg;
    my $object;

    my $decoder = JSON::XS->new->utf8;
    # this option
    if ($options{booleans_as_strings}) {
        # boolean_values() is not available on old versions of JSON::XS (Alma 8 still provides v3.04)
        if (JSON::XS->can('boolean_values')) {
            $decoder = $decoder->boolean_values("false", "true");
        } else {
            # if boolean_values is not available, perform a dirty substitution of booleans
            $content =~ s/"(\w+)"\s*:\s*(true|false)(\s*,?)/"$1": "$2"$3/gm;
        }
    }

    eval {
        $object = $decoder->decode($content);
    };
    if ($@) {
        $error_msg = "Cannot decode JSON string: $@" . "\n";
        return undef;
    }
    return $object;
}

sub test_json_decode {

    # Test with a simple JSON data that both functions should be able to decode
    my @tests = ( { file => 'utf-8.json', title => 'JSON has a valid UTF-8 encoding' },
                );

    foreach my $test (@tests) {
        open(my $fic, "<$files/$test->{file}" ) or die "Cannot open file: $files/$test->{file}: $!";
        my $content = join '', <$fic>;
        close $fic;

        my $old = legacy_json_decode($content) ;
        ok(ref $old eq 'HASH' && exists $old->{'bla'}, "$test->{title} - JSON successful decode with original function");

        my $new = eval { centreon::plugins::misc::json_decode($content, silence => 1) };

        ok(ref $new eq 'HASH' && exists $new->{'bla'}, "$test->{title} - JSON successful decode with new json_decode function");

        foreach my $key (keys %$new) {
            is($new->{$key}, $old->{$key}, "$test->{title} - Key '$key' has the same value");
        }
    }

    # Test with JSON data that only the new function should be able to decode
    @tests = ( { file => 'iso-8859-15.json', title => 'JSON has a valid ISO-8859-15 encoding' },
               { file => 'invalid.json', title => 'JSON has an invalid UTF-8 encoding' },
                );

    foreach my $test (@tests) {
        open(my $fic, "<$files/$test->{file}" ) or die "Cannot open file: $files/$test->{file}: $!";
        my $content = join '', <$fic>;
        close $fic;

        my $old = legacy_json_decode($content) ;
        ok((not defined $old) && $@ =~ /malformed/, "$test->{title} - JSON fails to decode with original function");

        my $new = eval { centreon::plugins::misc::json_decode($content, silence => 1) };

        ok(ref $new eq 'HASH' && exists $new->{'bla'}, "$test->{title} - JSON successful decode with new json_decode function");

        ok(keys %{$new} > 1, "$test->{title} - New json_decode successfully decodes many keys");
    }
}

test_json_decode;
done_testing();
