use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'	=> 'WWW::Search::Ebay',
              'VERSION' => '2.06',
              'PREREQ_PM' => {
                              'HTML::Form' => 0,
                              'HTML::TreeBuilder' => 3,
                              # The module's version, not the
                              # distribution's version:
                              'WWW::Search' => 2.18,
                              'WWW::Search::Test' => 2.12,
                             },
             );
