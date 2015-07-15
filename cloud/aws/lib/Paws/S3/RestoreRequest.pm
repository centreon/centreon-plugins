package Paws::S3::RestoreRequest {
  use Moose;
  has Days => (is => 'ro', isa => 'Int', required => 1);
}
1;
