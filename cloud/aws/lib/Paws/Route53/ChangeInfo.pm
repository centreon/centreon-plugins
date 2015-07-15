package Paws::Route53::ChangeInfo {
  use Moose;
  has Comment => (is => 'ro', isa => 'Str');
  has Id => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
  has SubmittedAt => (is => 'ro', isa => 'Str', required => 1);
}
1;
