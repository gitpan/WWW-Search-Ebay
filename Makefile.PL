use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME'	=> 'WWW::Search::Ebay',
              'VERSION_FROM' => 'Ebay.pm',
              'PREREQ_PM' => {
                              'HTML::Form' => 0,
                              'HTML::TreeBuilder' => 3,
                              # The module's version, not the
                              # distribution's version:
                              'WWW::Search' => 2.18,
                             },
             );
