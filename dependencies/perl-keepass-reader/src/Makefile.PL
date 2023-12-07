use 5.008005;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME           => 'KeePass::Reader',
    VERSION_FROM   => 'lib/KeePass/Reader.pm',
    PREREQ_PM      => { 'Test::More' => 0 },
    ABSTRACT_FROM  => 'lib/KeePass/Reader.pm',
    AUTHOR         => 'Quentin Garnier',
    LIBS           => [],
    DEFINE         => '',
    INC            => '',
    OBJECT         => ''
);
