# Ebay/ByEndDate.pm
# by Martin Thurn
# $Id: Ebay.pm,v 1.7 2001/07/30 18:05:35 mthurn Exp $

=head1 NAME

WWW::Search::Ebay::Mature - backend for searching www.ebay.com for auctions only in the "Mature Audiences" categories

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::Mature');
  my $sQuery = WWW::Search::escape_query("Kobe Tai");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

The search is done against CURRENT running auctions only.

The query is applied to TITLES only.

The results are ordered auctions ending soon first (order of
increasing auction ending date).  In the WWW::Search::Result objects,
the change_date field contains the auction ending date & time exactly
as returned by ebay.com; this can have values like "in 12 mins".

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay::Mature> was written by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Ebay::Mature> is maintained by Martin Thurn
(mthurn@cpan.org).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

=head2 2.01, 2002-07-31

First publicly-released version.

=cut

#####################################################################

package WWW::Search::Ebay::Mature;

use WWW::Search::Ebay;
@ISA = qw( WWW::Search::Ebay );

$VERSION = '2.01';
$MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

# private
sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;

  $rhOptsArg ||= [];
  # $rhOptsArg->{'MfcISAPICommand'} = 'GetResult';
  $rhOptsArg->{'categoryid'} = '';
  # $rhOptsArg->{'ht'} = 1;
  $rhOptsArg->{'category1'} = 319;
  $rhOptsArg->{'search1'} = 'Search';
  $rhOptsArg->{'BasicSearch'} = '';
  # Set a cookie so that ebay.com allows us to see Mature auctions:
  $self->cookie_jar->set_cookie(undef,
                                's', # key
                                'AQAAAAcAAAASAAAARQAAANakST1W31I9QDE0Ny44MS4zLjE5N2UxdGVzdENvb2tpZSAkMiRNb3ppbGxhLyROWTR0QWVsbUljdTQ0d3FyMG4vNGkvABEAAABLAAAA5qRJPT6nST1AMTQ3LjgxLjMuMTk3ZTEwMDA5NG1hcnRpbnRodXJuICQyJE1vemlsbGEvJHB0T3V0azl5YmZ3V3I3dll6ZTE4UTEABgAAAAoAAADmpEk99rJJPTA5AQAAAEYAAADxpEk9DrNJPUAxNDcuODEuMy4xOTdlMW1hcnRpbnRodXJuICQyJE1vemlsbGEvJHBaUFcwSDRXUEJBV3ozRGVYM2xmbjAAAwAAAD4AAADxpEk9DrNJPUAxNDcuODEuMy4xOTdlMTUxMSAkMiRNb3ppbGxhLyQ2bkN4RUdieDZnd1FyZjhQUG4vUXAvAAwAAABBAAAA8aRJPQGzST1AMTQ3LjgxLjMuMTk3ZTEyMzAwNjcgJDIkTW96aWxsYS8kNTM2NURmZGxBZS80amZBUFU0Z2JsMAACAAAAIQAAAP6kST0Os0k9MFpFYTB6ZEVEcmdOYnBqVXpqUTNwUkEqKg**k', # value
                                '/', # path
                                '.ebay.com', # host
                                undef, # port
                                1, # $path_spec,
                                0, # $secure,
                                999999, # $maxage,
                                # $discard
                               );
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

1;

__END__
