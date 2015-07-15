package Paws::CloudFront::CookiePreference {
  use Moose;
  has Forward => (is => 'ro', isa => 'Str', required => 1);
  has WhitelistedNames => (is => 'ro', isa => 'Paws::CloudFront::CookieNames');
}
1;
