
# $Id: Motors.pm,v 1.8 2008/02/25 01:24:46 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::Motors - backend for searching eBay Motors

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Ebay::Motors');
  my $sQuery = WWW::Search::escape_query("Buick Star Wars");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    { print $oResult->url, "\n"; }

=head1 DESCRIPTION

This class is a Ebay Motors specialization of WWW::Search.
It handles making and interpreting Ebay searches
F<http://www.ebay.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

Same as L<WWW::Search::Ebay>.

=head1 OPTIONS

Same as L<WWW::Search::Ebay>.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 CAVEATS

=head1 BUGS

Please tell the author if you find any!

=head1 AUTHOR

C<WWW::Search::Ebay::Motors> was written by and is maintained by
Martin Thurn C<mthurn@cpan.org>, L<http://tinyurl.com/nn67z>.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::Ebay::Motors;

use strict;
use warnings;

use Carp;
use Data::Dumper;
use base 'WWW::Search::Ebay';
our
$VERSION = do { my @r = (q$Revision: 1.8 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };
our $MAINTAINER = 'Martin Thurn <mthurn@cpan.org>';

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://motors.search.ebay.com';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

sub result_count_element_specs
  {
  return (
          '_tag' => 'div',
          id => 'matchesFound'
         );
  } # result_count_element_specs

sub result_count_pattern
  {
  return qr'(\d+)\s+match(es)?\s+found';
  } # result_count_pattern

sub title_element_specs
  {
  return (
          '_tag' => 'td',
          'class' => 'details',
         );
  } # title_element_specs

sub columns
  {
  my $self = shift;
  return qw( bids price shipping enddate );
  } # columns

1;

__END__

