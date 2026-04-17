package Storage::Incoming_article;

use strict;
use warnings FATAL => 'all';

my $Storage;
my $Errors;
use Abills::Base qw/in_array days_in_month/;
use Digest::MD5 qw(md5_hex);

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    lang    => $attr->{lang} || {},
    html    => $attr->{html} || undef,
    libpath => $attr->{libpath}
  };

  use Storage;
  $Storage = Storage->new($db, $admin, $conf);

  use Control::Errors;
  $Errors = Control::Errors->new($db, $admin, $conf, { lang => $attr->{lang}, module => 'Storage' });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 _start_transaction() - Initialize transaction manager

  Arguments:
    None

  Returns:
    HASHREF
      {
        rollback => sub { ... }, # Rollback transaction if needed
        commit   => sub { ... }  # Commit transaction if needed
      }

  Example:
    my $transaction = $self->_start_transaction();
    $transaction->{commit}->();

=cut
#**********************************************************
sub _start_transaction {
  my ($self) = @_;

  my $db = $Storage->{db}{db};
  my $manage_transaction = !$Storage->{db}->{TRANSACTION};

  if ($manage_transaction) {
    $db->{AutoCommit} = 0;
    $Storage->{db}->{TRANSACTION} = 1;
  }

  return {
    rollback => sub {
      return if !$manage_transaction;

      delete $Storage->{db}->{TRANSACTION};
      $db->rollback();
      $db->{AutoCommit} = 1;
    },
    commit => sub {
      return if !$manage_transaction;

      delete $Storage->{db}->{TRANSACTION};
      $db->commit();
      $db->{AutoCommit} = 1;
    }
  };
}

#**********************************************************
=head2 storage_incoming_articles_divide($self, $attr)

  Arguments:
    $self - Object instance
    $attr - HashRef with the following keys:
        INCOMING_ARTICLE_ID - ID of the article to divide (required)
        DIVIDED_ITEMS       - ArrayRef of items to create (required)

  Returns:
    $Storage - Result of the operation or error object

  Example:

    my $result = $storage->storage_incoming_articles_divide({
      INCOMING_ARTICLE_ID => 1205,
      DIVIDED_ITEMS       => [
        { SERIAL => 'A1', QRCODE_HASH => '...' },
        { SERIAL => 'A2' }
      ]
    });

=cut
#**********************************************************
sub storage_incoming_articles_divide {
  my ($self, $attr) = @_;

  if (!$attr->{INCOMING_ARTICLE_ID}) {
    return $Errors->throw_error(1180004);
  }

  if (!$attr->{DIVIDED_ITEMS} || ref($attr->{DIVIDED_ITEMS}) ne 'ARRAY') {
    return $Errors->throw_error(1180008);
  }

  my $incoming_article = $Storage->storage_incoming_articles_list2({
    ID                    => $attr->{INCOMING_ARTICLE_ID},
    TOTAL                 => '_SHOW',
    SIA_COUNT             => '_SHOW',
    TOTAL_SUM             => '_SHOW',
    SIA_SUM               => '_SHOW',
    INVOICE_ID            => '_SHOW',
    SELL_PRICE            => '_SHOW',
    RENT_PRICE            => '_SHOW',
    IN_INSTALLMENTS_PRICE => '_SHOW',
    FEES_METHOD           => '_SHOW',
    SA_ID                 => '_SHOW',
    ABON_DISTRIBUTION     => '_SHOW',
    COLS_NAME             => 1
  });

  if (!$Storage->{TOTAL} || $Storage->{TOTAL} < 1) {
    return $Errors->throw_error(1180004);
  }

  my $incoming_article_info = $incoming_article->[0];
  my $count_of_divided_items = scalar(@{$attr->{DIVIDED_ITEMS}});
  my $sum_per_item = 0;
  if ($incoming_article_info->{sia_sum} && $incoming_article_info->{total} && $incoming_article_info->{total} > 0) {
    $sum_per_item = $incoming_article_info->{sia_sum} / $incoming_article_info->{total};
  }

  if (defined($Storage->{STORAGE_ADMIN_PERMISSIONS}) && $incoming_article_info->{storage_id}) {
    if (!$Storage->{STORAGE_ADMIN_PERMISSIONS}{$incoming_article_info->{storage_id}}) {
      return $Errors->throw_error(1180002);
    }
  }

  if (!$incoming_article_info->{total} ||  $incoming_article_info->{total} < $count_of_divided_items) {
    return $Errors->throw_error(1180008);
  }

  my $transaction = $self->_start_transaction();

  my $new_incoming_article_ids = [];
  foreach my $article (@{$attr->{DIVIDED_ITEMS}}) {
    $Storage->storage_incoming_articles_add({
      INVOICE_ID                 => $incoming_article_info->{invoice_id},
      COUNT                      => 1,
      SUM                        => $sum_per_item,
      ARTICLE_ID                 => $incoming_article_info->{sa_id},
      SELL_PRICE                 => $incoming_article_info->{sell_price},
      RENT_PRICE                 => $incoming_article_info->{rent_price},
      IN_INSTALLMENTS_PRICE      => $incoming_article_info->{in_installments_price},
      FEES_METHOD                => $incoming_article_info->{fees_method},
      ABON_DISTRIBUTION          => $incoming_article_info->{abon_distribution},
      PARENT_INCOMING_ARTICLE_ID => $attr->{INCOMING_ARTICLE_ID}
    });

    if ($Storage->{errno}) {
      $transaction->{rollback}->();
      return $Storage;
    }

    my $new_incoming_article_id = $Storage->{INSERT_ID};

    if (!$article->{QRCODE_HASH}) {
      $article->{QRCODE_HASH} = md5_hex($new_incoming_article_id);
    }
    $Storage->storage_incoming_articles_change({ %{$article}, ID => $new_incoming_article_id });
    if ($Storage->{errno}) {
      $transaction->{rollback}->();
      return $Storage;
    }
    push @{$new_incoming_article_ids}, $new_incoming_article_id;
  }

  my $new_count = $incoming_article_info->{sia_count} - $count_of_divided_items;
  $Storage->storage_incoming_articles_change({
    ID            => $attr->{INCOMING_ARTICLE_ID},
    COUNT         => $new_count,
    SUM           => $sum_per_item * $new_count,
    DIVIDED_ITEMS => $new_incoming_article_ids
  });

  if ($Storage->{errno}) {
    $transaction->{rollback}->();
    return $Storage;
  }

  $Storage->{DIVIDED_ARTICLE_IDS} = $new_incoming_article_ids;
  $Storage->{DIVIDED_COUNT} = scalar(@{$new_incoming_article_ids});

  $transaction->{commit}->();

  return $Storage;
}

#**********************************************************
=head2 storage_incoming_articles_move($self, $incoming_article_id, $new_incoming_article)

  Arguments:
    $self - Object instance

    $incoming_article_id - Incoming article ID (required)

    $new_incoming_article - HashRef with keys:
        STORAGE_ID - Target storage ID (required)
        COUNT      - Number of items to move (required)

  Returns:
    $Storage - Operation result

    or HashRef:
      INCOMING_ARTICLE_ID - ID of created incoming article (for partial move)

  Example:

    my $result = $storage->storage_incoming_articles_move(
      1205,
      {
        STORAGE_ID => 4,
        COUNT      => 3
      }
    );

=cut
#**********************************************************
sub storage_incoming_articles_move {
  my ($self, $incoming_article_id, $new_incoming_article) = @_;

  if (!$new_incoming_article || !$new_incoming_article->{STORAGE_ID}) {
    return $Errors->throw_error(1180004);
  }

  my $incoming_article = $Storage->storage_incoming_articles_info({ ID => $incoming_article_id });
  if (!$Storage->{TOTAL} || $Storage->{TOTAL} < 1) {
    return $Errors->throw_error(1180004);
  }

  if (!$incoming_article->{STORAGE_ID} || $incoming_article->{STORAGE_ID} == $new_incoming_article->{STORAGE_ID}) {
    return $Errors->throw_error(1180009);
  }

  my $stock_balance = $incoming_article->{COUNT} || 0;

  my $accountability_items = $Storage->storage_accountability_list({
    STORAGE_INCOMING_ARTICLES_ID => $incoming_article_id,
    COUNT                        => '!',
    COLS_NAME                    => 1,
    COLS_UPPER                   => 1
  });
  my $reserve = $Storage->storage_reserve_list({
    STORAGE_INCOMING_ARTICLES_ID => $incoming_article_id,
    COUNT                        => '!',
    COLS_NAME                    => 1,
    COLS_UPPER                   => 1
  });

  for my $item (@$accountability_items, @$reserve) {
    $stock_balance -= $item->{COUNT} if ($item->{COUNT} && $item->{COUNT} > 0);
  }

  if (!$new_incoming_article->{COUNT} || $new_incoming_article->{COUNT} > $stock_balance) {
    return $Errors->throw_error(1180001);
  }

  my $transaction = $self->_start_transaction();

  $Storage->storage_income_add({
    STORAGE_ID => $new_incoming_article->{STORAGE_ID}
  });

  if ($Storage->{errno}) {
    $transaction->{rollback}->();
    return $Storage;
  }
  my $incoming_id = $Storage->{INSERT_ID};
  my $is_full_move = ($new_incoming_article->{COUNT} == $incoming_article->{COUNT});

  if ($is_full_move) {
    $Storage->storage_incoming_articles_change({
      ID                  => $incoming_article_id,
      STORAGE_INCOMING_ID => $incoming_id,
      MOVE_ITEMS          => $new_incoming_article->{COUNT},
      OLD_STORAGE_ID      => $incoming_article->{STORAGE_ID},
      NEW_STORAGE_ID      => $new_incoming_article->{STORAGE_ID},
    });
    if ($Storage->{errno}) {
      $transaction->{rollback}->();
      return $Storage;
    }

    $transaction->{commit}->();
    return $Storage;
  }

  my $price_for_one_piece = $incoming_article->{SUM} / $incoming_article->{COUNT};
  my $sum_for_new_items = $price_for_one_piece * $new_incoming_article->{COUNT};
  my $sum_for_old_items = $incoming_article->{SUM} - $sum_for_new_items;

  $Storage->storage_incoming_articles_change({
    ID             => $incoming_article_id,
    SUM            => $sum_for_old_items,
    COUNT          => $incoming_article->{COUNT} - $new_incoming_article->{COUNT},
    INVOICE_ID     => $incoming_article->{STORAGE_INCOMING_ID},
    MOVE_ITEMS     => $new_incoming_article->{COUNT},
    OLD_STORAGE_ID => $incoming_article->{STORAGE_ID},
    NEW_STORAGE_ID => $new_incoming_article->{STORAGE_ID},
  });
  if ($Storage->{errno}) {
    $transaction->{rollback}->();
    return $Storage;
  }

  delete $incoming_article->{ID};
  $Storage->storage_incoming_articles_add({
    %{$incoming_article},
    SUM            => $sum_for_new_items,
    COUNT          => $new_incoming_article->{COUNT},
    INVOICE_ID     => $incoming_id,
    MOVE_ITEMS     => 1,
    OLD_STORAGE_ID => $incoming_article->{STORAGE_ID},
    STORAGE_ID     => $new_incoming_article->{STORAGE_ID}
  });
  if ($Storage->{errno}) {
    $transaction->{rollback}->();
    return $Storage;
  }

  $transaction->{commit}->();
  return {
    INCOMING_ARTICLE_ID => $Storage->{INSERT_ID}
  };
}

1;