package Paws::CloudSearch::DomainStatus {
  use Moose;
  has ARN => (is => 'ro', isa => 'Str');
  has Created => (is => 'ro', isa => 'Bool');
  has Deleted => (is => 'ro', isa => 'Bool');
  has DocService => (is => 'ro', isa => 'Paws::CloudSearch::ServiceEndpoint');
  has DomainId => (is => 'ro', isa => 'Str', required => 1);
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Limits => (is => 'ro', isa => 'Paws::CloudSearch::Limits');
  has Processing => (is => 'ro', isa => 'Bool');
  has RequiresIndexDocuments => (is => 'ro', isa => 'Bool', required => 1);
  has SearchInstanceCount => (is => 'ro', isa => 'Int');
  has SearchInstanceType => (is => 'ro', isa => 'Str');
  has SearchPartitionCount => (is => 'ro', isa => 'Int');
  has SearchService => (is => 'ro', isa => 'Paws::CloudSearch::ServiceEndpoint');
}
1;
