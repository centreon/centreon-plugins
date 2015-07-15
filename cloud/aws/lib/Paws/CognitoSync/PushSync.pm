package Paws::CognitoSync::PushSync {
  use Moose;
  has ApplicationArns => (is => 'ro', isa => 'ArrayRef[Str]');
  has RoleArn => (is => 'ro', isa => 'Str');
}
1;
