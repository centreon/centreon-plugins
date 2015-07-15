
package Paws::IAM::GetAccessKeyLastUsedResponse {
  use Moose;
  has AccessKeyLastUsed => (is => 'ro', isa => 'Paws::IAM::AccessKeyLastUsed');
  has UserName => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetAccessKeyLastUsedResponse

=head1 ATTRIBUTES

=head2 AccessKeyLastUsed => Paws::IAM::AccessKeyLastUsed

  

Contains information about the last time the access key was used.









=head2 UserName => Str

  

The name of the AWS IAM user that owns this access key.











=cut

