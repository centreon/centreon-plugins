package Paws::ELB::AppCookieStickinessPolicy {
  use Moose;
  has CookieName => (is => 'ro', isa => 'Str');
  has PolicyName => (is => 'ro', isa => 'Str');
}
1;
