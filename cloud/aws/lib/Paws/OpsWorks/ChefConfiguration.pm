package Paws::OpsWorks::ChefConfiguration {
  use Moose;
  has BerkshelfVersion => (is => 'ro', isa => 'Str');
  has ManageBerkshelf => (is => 'ro', isa => 'Bool');
}
1;
