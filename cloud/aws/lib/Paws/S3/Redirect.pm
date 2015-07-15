package Paws::S3::Redirect {
  use Moose;
  has HostName => (is => 'ro', isa => 'Str');
  has HttpRedirectCode => (is => 'ro', isa => 'Str');
  has Protocol => (is => 'ro', isa => 'Str');
  has ReplaceKeyPrefixWith => (is => 'ro', isa => 'Str');
  has ReplaceKeyWith => (is => 'ro', isa => 'Str');
}
1;
