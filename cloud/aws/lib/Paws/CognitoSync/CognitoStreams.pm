package Paws::CognitoSync::CognitoStreams {
  use Moose;
  has RoleArn => (is => 'ro', isa => 'Str');
  has StreamName => (is => 'ro', isa => 'Str');
  has StreamingStatus => (is => 'ro', isa => 'Str');
}
1;
