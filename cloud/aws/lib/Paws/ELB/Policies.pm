package Paws::ELB::Policies {
  use Moose;
  has AppCookieStickinessPolicies => (is => 'ro', isa => 'ArrayRef[Paws::ELB::AppCookieStickinessPolicy]');
  has LBCookieStickinessPolicies => (is => 'ro', isa => 'ArrayRef[Paws::ELB::LBCookieStickinessPolicy]');
  has OtherPolicies => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
