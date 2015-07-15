package Paws::Support::RecentCaseCommunications {
  use Moose;
  has communications => (is => 'ro', isa => 'ArrayRef[Paws::Support::Communication]');
  has nextToken => (is => 'ro', isa => 'Str');
}
1;
