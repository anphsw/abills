package Storage::Installation;

use strict;
use warnings FATAL => 'all';

my Abills::HTML $html;

my $Storage;
my $Errors;

use Abills::Base qw/in_array/;

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  use Storage;
  $Storage = Storage->new($db, $admin, $conf);

  use Control::Errors;
  $Errors = Control::Errors->new($db, $admin, $conf, { lang => $attr->{lang}, module => 'Storage' });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 change_installation($attr)

=cut
#**********************************************************
sub change_installation {
  my $self = shift;
  my ($attr) = @_;

  $Storage->storage_installation_info({ ID => $attr->{ID} });
  return $Storage if ($Storage->{TOTAL} && $Storage->{TYPE} && $Storage->{TYPE} eq '4');

  delete $attr->{COUNT} if defined $attr->{COUNT} && (!$attr->{COUNT} || $attr->{COUNT} < 1);

  my $old_count = $Storage->{COUNT} || 0;
  my $new_count = $attr->{COUNT};
  my $incoming_articles_count = 0;
  my $incoming_article_id = $Storage->{STORAGE_INCOMING_ARTICLES_ID};

  if ($new_count && $new_count > 0 && $new_count != $old_count && $incoming_article_id) {
    my $article_info = $Storage->storage_incoming_articles_info({ ID => $incoming_article_id });
    my $residue = $article_info->{COUNT} || 0;

    if ($new_count < $old_count) {
      $incoming_articles_count = $residue + ($old_count - $new_count);
    }
    else {
      if (($residue + $old_count) < $new_count) {
        return $Errors->throw_error(1180001);
      }

      $incoming_articles_count = $residue - ($new_count - $old_count);
    }
  }

  $Storage->storage_installation_change($attr);
  return $Storage if $Storage->{errno};

  if ($incoming_articles_count) {
    $Storage->storage_incoming_articles_change({ ID => $incoming_article_id, COUNT => $incoming_articles_count });
  }

  return $Storage;
}

1;