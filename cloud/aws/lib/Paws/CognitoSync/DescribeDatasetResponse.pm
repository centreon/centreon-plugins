
package Paws::CognitoSync::DescribeDatasetResponse {
  use Moose;
  has Dataset => (is => 'ro', isa => 'Paws::CognitoSync::Dataset');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::DescribeDatasetResponse

=head1 ATTRIBUTES

=head2 Dataset => Paws::CognitoSync::Dataset

  

Meta data for a collection of data for an identity. An identity can
have multiple datasets. A dataset can be general or associated with a
particular entity in an application (like a saved game). Datasets are
automatically created if they don't exist. Data is synced by dataset,
and a dataset can hold up to 1MB of key-value pairs.











=cut

