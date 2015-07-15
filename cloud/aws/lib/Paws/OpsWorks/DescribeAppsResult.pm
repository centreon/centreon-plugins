
package Paws::OpsWorks::DescribeAppsResult {
  use Moose;
  has Apps => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::App]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeAppsResult

=head1 ATTRIBUTES

=head2 Apps => ArrayRef[Paws::OpsWorks::App]

  

An array of C<App> objects that describe the specified apps.











=cut

1;