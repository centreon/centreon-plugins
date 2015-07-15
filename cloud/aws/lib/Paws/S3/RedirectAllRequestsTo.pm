package Paws::S3::RedirectAllRequestsTo {
  use Moose;
  has HostName => (is => 'ro', isa => 'Str', required => 1);
  has Protocol => (is => 'ro', isa => 'Str');
}
1;
