use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'POE::Component::Logger',
    'VERSION_FROM' => 'lib/POE/Component/Logger.pm',
    'PREREQ_PM' => {
        Log::Dispatch::Config => '0.10',
        POE => 0.11,
    },
    'ABSTRACT_FROM' => 'lib/POE/Component/Logger.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);
