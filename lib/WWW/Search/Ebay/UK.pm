
# $Id: UK.pm,v 1.4 2005/05/19 02:26:50 Daddy Exp $

=head1 NAME

WWW::Search::Ebay::UK - backend for searching auctions at www.ebay.co.uk

=head1 DESCRIPTION

Acts just like WWW::Search::Ebay.

=head1 AUTHOR

C<WWW::Search::Ebay::UK> was written by Martin Thurn
(mthurn@cpan.org).

C<WWW::Search::Ebay::UK> is maintained by Martin Thurn
(mthurn@cpan.org).

=cut

package WWW::Search::Ebay::UK;

use Carp;
use WWW::Search::Ebay;
use vars qw( @ISA $VERSION );
@ISA = qw( WWW::Search::Ebay );
$VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

sub native_setup_search
  {
  my ($self, $native_query, $rhOptsArg) = @_;
  $rhOptsArg ||= {};
  unless (ref($rhOptsArg) eq 'HASH')
    {
    carp " --- second argument to native_setup_search should be hashref, not arrayref";
    return undef;
    } # unless
  $rhOptsArg->{search_host} = 'http://search.ebay.co.uk';
  return $self->SUPER::native_setup_search($native_query, $rhOptsArg);
  } # native_setup_search

# This is what we look_down for to find the HTML element that contains
# the result count:
sub _result_count_td_specs
  {
  return (
          '_tag' => 'td',
          width => '98%'
         );
  } # _result_count_td_specs

# This is what we look_down for to find the <TD> that contain auction titles:
sub _title_td_specs
  {
  return (
          '_tag' => 'td',
          'valign' => 'middle',
         );
  } # _title_td_specs

sub currency_pattern
  {
  # A pattern to match all possible currencies found in eBay listings
  # (if one character looks weird, it's really a British Pound symbol
  # but Emacs shows it wrong):
  return qr{(?:US\s?\$|�)}; # } } # Emacs indentation bugfix
  } # currency_pattern

1;

__END__

