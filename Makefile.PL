use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'	=> 'WWW::Search::Ebay',
              'VERSION' => '2.13',
              'PREREQ_PM' => {
                              # The module's version, not the
                              # distribution's version:
                              # 'WWW::Search' => 2.27,
                              'WWW::Search::Test' => 2.12,
                             },
             );
