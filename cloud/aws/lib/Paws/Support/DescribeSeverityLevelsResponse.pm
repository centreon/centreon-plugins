
package Paws::Support::DescribeSeverityLevelsResponse {
  use Moose;
  has severityLevels => (is => 'ro', isa => 'ArrayRef[Paws::Support::SeverityLevel]');

}

### main pod documentation begin ###

=head1 NAME

Paws::Support::DescribeSeverityLevelsResponse

=head1 ATTRIBUTES

=head2 severityLevels => ArrayRef[Paws::Support::SeverityLevel]

  

The available severity levels for the support case. Available severity
levels are defined by your service level agreement with AWS.











=cut

1;