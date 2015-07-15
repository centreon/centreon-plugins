package Paws::Route53::ChangeBatch {
  use Moose;
  has Changes => (is => 'ro', isa => 'ArrayRef[Paws::Route53::Change]', required => 1);
  has Comment => (is => 'ro', isa => 'Str');
}
1;
