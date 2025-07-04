package Storage::Installation;

use strict;
use warnings FATAL => 'all';

my Abills::HTML $html;

my $Storage;
my $Errors;
use Abills::Base qw/in_array days_in_month/;
my $INSTALLATION_ACTIONS = {
  1 => 12,
  2 => 13,
  3 => 15
};

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
=head2 storage_change_installation($attr)

=cut
#**********************************************************
sub storage_change_installation {
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

#**********************************************************
=head2 storage_add_installation($attr) - Add storage installation

  Arguments:
    $attr
      ARTICLE_ID             - ID of the article in storage (required)
      COUNT                  - Number of items to install (default: 0)
      UID                    - User ID (optional)
      NAS_ID                 - NAS ID (optional)
      LOCATION_ID            - Location ID (optional)
      STATUS                 - Installation status:
                                 0 - Install
                                 1 - Sell
                                 2 - Rent
                                 3 - Installments
      MONTHES                - Number of months (used for installments)
      ACTUAL_SELL_PRICE      - Actual selling price override (optional)
      SERIAL                 - Serial number (optional)
      USER_INFO              - Preloaded user info (optional)

  Returns:
    $Storage object or error

  Example:
    $Installation->storage_add_installation({
      ARTICLE_ID => 123,
      COUNT      => 1,
      UID        => 456,
      STATUS     => 1
    });

=cut
#**********************************************************
sub storage_add_installation {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{ARTICLE_ID}) {
    return $Errors->throw_error(1180004);
  }

  my $incoming_article_info = $Storage->storage_incoming_articles_info({ ID => $attr->{ARTICLE_ID} });
  if (!$Storage->{TOTAL} || $Storage->{TOTAL} < 1) {
    return $Errors->throw_error(1180004);
  }

  $attr->{COUNT} = $attr->{COUNT} && $attr->{COUNT} > 0 ? $attr->{COUNT} : 0;
  my $stock_balance = $incoming_article_info->{COUNT} || 0;
  if ($attr->{COUNT} < 1 || $stock_balance < 1 || ($stock_balance - $attr->{COUNT} < 0)) {
    return $Errors->throw_error(1180001);
  }

  if (!$attr->{UID} && !$attr->{NAS_ID} && !$attr->{LOCATION_ID}) {
    return $Errors->throw_error(1180006);
  }

  $attr->{MONTHES} //= $attr->{MONTHS};

  $attr->{SELL_PRICE} = $incoming_article_info->{SELL_PRICE} ? $incoming_article_info->{SELL_PRICE} * int($attr->{COUNT}) : 0;
  $attr->{RENT_PRICE} = $incoming_article_info->{RENT_PRICE} ? $incoming_article_info->{RENT_PRICE} * int($attr->{COUNT}) : 0;
  $attr->{IN_INSTALLMENTS_PRICE} = ($incoming_article_info->{IN_INSTALLMENTS_PRICE} && $attr->{MONTHES}) ?
    $incoming_article_info->{IN_INSTALLMENTS_PRICE} / $attr->{MONTHES} : 0;

  $attr->{SELL_PRICE} = $attr->{ACTUAL_SELL_PRICE} if ($attr->{ACTUAL_SELL_PRICE} && $attr->{ACTUAL_SELL_PRICE} > 0);

  $Storage->{db}{db}->{AutoCommit} = 0;
  $Storage->{db}->{TRANSACTION} = 1;
  my DBI $db_ = $Storage->{db}{db};

  if ($attr->{SERIAL} && $attr->{COUNT} == 1 && !$incoming_article_info->{SN}) {
    if ($incoming_article_info->{SIA_COUNT} && $incoming_article_info->{SIA_COUNT} > 1) {
      $Storage->storage_incoming_articles_divide({
        ARTICLE_ID          => $incoming_article_info->{ARTICLE_ID},
        COUNT               => $incoming_article_info->{COUNT},
        DIVIDE              => 1,
        SUM                 => $incoming_article_info->{SUM} / $incoming_article_info->{COUNT},
        SN                  => $incoming_article_info->{SN},
        MAIN_ARTICLE_ID     => $incoming_article_info->{ID},
        STORAGE_INCOMING_ID => $incoming_article_info->{STORAGE_INCOMING_ID},
        SUM_TOTAL           => $incoming_article_info->{SUM},
      });

      if ($Storage->{errno} || !$Storage->{INCOMING_ARTICLE_ID}) {
        $db_->rollback();
        return $Errors->throw_error(1180004);
      }

      if (!$Storage->{errno} && $Storage->{INCOMING_ARTICLE_ID}) {
        $Storage->storage_incoming_articles_change({
          ID     => $Storage->{INCOMING_ARTICLE_ID},
          SERIAL => $attr->{SERIAL}
        });

        if ($Storage->{errno}) {
          $db_->rollback();
          return $Storage;
        }

        $incoming_article_info = $Storage->storage_incoming_articles_info({ ID => $Storage->{INCOMING_ARTICLE_ID} });
      }
    }
    else {
      $Storage->storage_incoming_articles_change({
        ID     => $incoming_article_info->{ID},
        SERIAL => $attr->{SERIAL}
      });

      if ($Storage->{errno}) {
        $db_->rollback();
        return $Storage;
      }
    }
  }

  if ($attr->{STATUS} && $attr->{STATUS} == 3 && $attr->{IN_INSTALLMENTS_PRICE} > 0) {
    $attr->{MONTHES} = $attr->{MONTHES} - 1 if ($attr->{MONTHES});
    $attr->{AMOUNT_PER_MONTH} = $attr->{IN_INSTALLMENTS_PRICE};
  }

  $attr->{STATUS} //= 0;
  $Storage->storage_installation_user_add({
    %{$attr},
    COUNT_INCOMING      => $incoming_article_info->{COUNT},
    SUM_TOTAL           => $incoming_article_info->{SUM},
    MAIN_ARTICLE_ID     => $incoming_article_info->{ID},
    ACTION              => $INSTALLATION_ACTIONS->{$attr->{STATUS}} || '',
    INSTALLATION_SOURCE => $incoming_article_info->{STORAGE_ID} ? "STORAGE_ID: $incoming_article_info->{STORAGE_ID}" : ''
  });
  my $installation_id = $Storage->{INSTALLATION_ID};

  if ($Storage->{errno} || !$installation_id) {
    $db_->rollback();
    return $Storage->{errno} ? $Storage : $Errors->throw_error(1180005);
  }

  if (!$attr->{USER_INFO} && $attr->{UID}) {
    use Users;
    my Users $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->info($attr->{UID});
    if ($Users->{TOTAL} && $Users->{TOTAL} == 1) {
      $attr->{USER_INFO} = $Users;
    }
  }

  my $fee_result = $self->_storage_make_installation_fee($incoming_article_info, $attr);

  if ($fee_result) {
    delete $Storage->{db}->{TRANSACTION};
    $db_->commit();
    $db_->{AutoCommit} = 1;
  }
  else {
    $db_->rollback();
    return $Errors->throw_error(1180005);
  }

  if ($attr->{UID} && $attr->{COUNT} == 1 && $self->{conf}{STORAGE_INTERNET_ASSIGN}) {
    $self->_storage_assign_internet_parameters($installation_id, $attr->{UID});
    $Storage->{INSTALLATION_ID} = $installation_id;
  }

  return $Storage;
}

#**********************************************************
=head2 storage_del_installation($attr) - Del storage installation

  Arguments:
    $attr
      INSTALLATION_ID        - ID of the installation (required)
      COUNT                  - Number of items to install (default: 0)
      UID                    - User ID (optional)
      USER_INFO              - Preloaded user info (optional)

  Returns:
    $Storage object or error

  Example:
    $Installation->storage_del_installation({
      ARTICLE_ID => 123,
      COUNT      => 1,
      UID        => 456,
      STATUS     => 1
    });

=cut
#**********************************************************
sub storage_del_installation {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{INSTALLATION_ID}) {
    return $Errors->throw_error(1180007);
  }

  my $installations = $Storage->storage_installation_list({
    ID                           => $attr->{INSTALLATION_ID},
    STORAGE_INCOMING_ARTICLES_ID => '_SHOW',
    COUNT                        => '_SHOW',
    SUM                          => '_SHOW',
    STA_NAME                     => '_SHOW',
    STREET                       => '_SHOW',
    UID                          => '_SHOW',
    STATUS                       => '_SHOW',
    STORAGE_ID                   => '_SHOW',
    COLS_NAME                    => 1
  });

  if (!$Storage->{TOTAL} || $Storage->{TOTAL} < 1 || scalar(@{$installations}) < 1) {
    return $Errors->throw_error(1180007);
  }
  my $installation_info = $installations->[0] || {};

  if (defined($Storage->{STORAGE_ADMIN_PERMISSIONS}) && $installation_info->{storage_id}) {
    if (!$Storage->{STORAGE_ADMIN_PERMISSIONS}{$installation_info->{storage_id}}) {
      return $Errors->throw_error(1180002);
    }
  }

  my $incoming_articles = $Storage->storage_incoming_articles_list({
    ID         => $installation_info->{storage_incoming_articles_id},
    IDENT1     => '_SHOW',
    IDENT2     => '_SHOW',
    IDENT3     => '_SHOW',
    COLS_UPPER => 1,
    COLS_NAME  => 1
  });

  if (!$Storage->{TOTAL} || $Storage->{TOTAL} < 1 || scalar(@{$incoming_articles}) < 1) {
    return $Errors->throw_error(1180004);
  }

  my $incoming_article_info = $incoming_articles->[0];
  my $storage_id = $incoming_article_info->{storage_id} || 0;
  return $Storage if $Storage->{errno};

  $Storage->storage_installation_return({
    COUNT_INCOMING  => $incoming_article_info->{sia_count},
    SUM_TOTAL       => $incoming_article_info->{total_sum},
    MAIN_ARTICLE_ID => $incoming_article_info->{sia_id},
    COUNT           => $installation_info->{count},
    ID_INSTALLATION => $attr->{INSTALLATION_ID},
    SUM             => $installation_info->{sum},
    UID             => $attr->{UID},
    COMMENTS        => $attr->{COMMENTS},
    RETURN_STATUS   => 1
  });
  return $Storage if $Storage->{errno};

  if ($installation_info->{count} == 1 && $self->{conf}{STORAGE_INTERNET_ASSIGN} && $installation_info->{uid}) {
    $self->_storage_clear_internet_parameters($incoming_article_info, $installation_info->{uid});
  }

  my $storage_storages = $Storage->storages_names();
  my $storage_name = $storage_storages->[$storage_id];

  if (!$self->{conf}{STORAGE_MOVE_TO_ACCOUNTABILITY_ON_DELETE}) {
    return {
      STA_NAME     => $installation_info->{sta_name} || '',
      COUNT        => $installation_info->{count} || '',
      STREET       => $installation_info->{street} || '',
      STORAGE_NAME => $storage_name || '',
      TO_STORAGE   => 1
    };
  }

  $Storage->storage_accountability_add({
    STORAGE_INCOMING_ARTICLES_ID => $incoming_article_info->{sia_id},
    COUNT                        => $installation_info->{count},
    AID                          => $self->{admin}{AID},
    ADDED_BY_AID                 => $self->{admin}{AID},
    COMMENTS                     => $attr->{COMMENTS}
  });
  if ($Storage->{errno}) {
    return {
      STA_NAME     => $installation_info->{sta_name} || '',
      COUNT        => $installation_info->{count} || '',
      STREET       => $installation_info->{street} || '',
      STORAGE_NAME => $storage_name || '',
      TO_STORAGE   => 1
    };
  }

  return {
    STA_NAME          => $installation_info->{sta_name} || '',
    COUNT             => $installation_info->{count} || '',
    AID               => $self->{admin}{AID} || '',
    TO_ACCOUNTABILITY => 1
  };
}

#**********************************************************
=head2 _storage_make_installation_fee($incoming_article_info, $attr) - Charge user for equipment installation

  Arguments:
    $incoming_article_info - HashRef of article details from storage_incoming_articles_info()
    $attr
      STATUS                - Installation status:
                                1 - Sell
                                2 - Rent
                                3 - Installments
      USER_INFO             - User object (required for charging)
      SELL_PRICE            - Selling price (used if STATUS=1)
      RENT_PRICE            - Rent price (used if STATUS=2)
      IN_INSTALLMENTS_PRICE - Price per installment (used if STATUS=3)

  Returns:
    1 on success, 0 on failure

  Example:
    $self->_storage_make_installation_fee($incoming_article_info, $attr);

=cut
#**********************************************************
sub _storage_make_installation_fee {
  my $self = shift;
  my $incoming_article_info = shift;
  my ($attr) = @_;

  return 1 if !$attr->{STATUS};
  return 0 if !$attr->{USER_INFO} && $attr->{UID};

  require Finance;
  Finance->import();
  my $Fees = Finance->fees($self->{db}, $self->{admin}, $self->{conf});

  $self->{lang}{PAY_FOR_SELL} //= 'Payment for the sale of equipment  - ';
  $self->{lang}{PAY_FOR_RENT} //= 'Payment for rental equipment  - ';
  $self->{lang}{BY_INSTALLMENTS} //= 'By installments';
  $self->{lang}{ABON_DISTRIBUTION} //= 'Abon. payments distribution';

  if ($attr->{STATUS} == 1 && $attr->{SELL_PRICE} > 0) {
    $incoming_article_info->{SERIAL} //= '';
    $incoming_article_info->{ARTICLE_NAME} //= '';
    $Fees->take($attr->{USER_INFO}, $attr->{SELL_PRICE}, {
      DESCRIBE => "$self->{lang}{PAY_FOR_SELL} $incoming_article_info->{ARTICLE_NAME} ($incoming_article_info->{SERIAL})",
      METHOD   => $incoming_article_info->{FEES_METHOD} || 0
    });
    return $Fees->{errno} ? 0 : 1;
  }

  if ($attr->{STATUS} == 2 && $attr->{RENT_PRICE} > 0) {
    $incoming_article_info->{ARTICLE_NAME} //= '';
    my $describe = "$self->{lang}{PAY_FOR_RENT} $incoming_article_info->{ARTICLE_NAME}";
    if ($incoming_article_info->{ABON_DISTRIBUTION}) {
      $attr->{RENT_PRICE} = sprintf("%.6f", $attr->{RENT_PRICE} / days_in_month());
      $describe .= " - $self->{lang}{ABON_DISTRIBUTION}";
    }

    $Fees->take($attr->{USER_INFO}, $attr->{RENT_PRICE}, { DESCRIBE => $describe, METHOD => $incoming_article_info->{FEES_METHOD} || 0 });
    return $Fees->{errno} ? 0 : 1;
  }

  if ($attr->{STATUS} == 3 && $attr->{IN_INSTALLMENTS_PRICE} > 0) {
    $incoming_article_info->{ARTICLE_NAME} //= '';
    $Fees->take($attr->{USER_INFO}, $attr->{IN_INSTALLMENTS_PRICE}, {
      DESCRIBE => "$self->{lang}{BY_INSTALLMENTS} $incoming_article_info->{ARTICLE_NAME}",
      METHOD   => $incoming_article_info->{FEES_METHOD} || 0
    });
    return $Fees->{errno} ? 0 : 1;
  }

  return 1;
}

#**********************************************************
=head2 _storage_assign_internet_parameters($installation_id, $uid) - Assign internet parameters to installed equipment

  Arguments:
    $installation_id - ID of the storage installation
    $uid             - User ID to assign parameters to

  Returns:
    Nothing

  Example:
    $self->_storage_assign_internet_parameters(123, 456);

=cut
#**********************************************************
sub _storage_assign_internet_parameters {
  my $self = shift;
  my ($installation_id, $uid) = @_;

  $Storage->storage_installation_info({
    ID     => $installation_id,
    IDENT1 => '_SHOW',
    IDENT2 => '_SHOW',
    IDENT3 => '_SHOW'
  });

  if (!grep {$Storage->{$_}} qw(SERIAL IDENT1 IDENT2 IDENT3)) {
    return;
  }

  require Internet::Services;
  Internet::Services->import();
  my $Internet_services = Internet::Services->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{lang} });

  my $internet_info = $Internet_services->user_info({ UID => $uid });
  if (!$internet_info->{TOTAL} || $internet_info->{TOTAL} != 1) {
    return;
  }

  my @changeable_fields = qw(CID CPE_MAC);
  my $internet_params = {};

  for my $pair (split(/;/, $self->{conf}{STORAGE_INTERNET_ASSIGN})) {
    my ($key, $value) = split(/=/, $pair, 2);

    if (!grep {$_ eq $key} @changeable_fields) {
      next;
    }

    if ($value =~ /:/) {
      my @candidates = split(/:/, $value);
      for my $candidate (@candidates) {
        if (defined $Storage->{$candidate} && $Storage->{$candidate} ne '') {
          $internet_params->{$key} = $Storage->{$candidate};
          last;
        }
      }
    }
    elsif (defined $Storage->{$value} && $Storage->{$value}) {
      $internet_params->{$key} = $Storage->{$value};
    }
  }

  if (%{$internet_params}) {
    $Internet_services->user_change({
      %{$internet_params},
      ID  => $internet_info->{ID},
      UID => $uid
    });
  }
}

#***********************************************************
=head2 _storage_clear_internet_parameters($installation_id, $uid) - Helper for Internet parameter clear

  Arguments:
    $installation
    $uid - User ID

  Returns: None

=cut
#***********************************************************
sub _storage_clear_internet_parameters {
  my $self = shift;
  my ($installation, $uid) = @_;

  if (!grep { $installation->{$_} } qw(SERIAL IDENT1 IDENT2 IDENT3)) {
    return;
  }

  if (!$uid || !$self->{conf}{STORAGE_INTERNET_ASSIGN}) {
    return;
  }

  require Internet::Services;
  Internet::Services->import();
  my $Internet_services = Internet::Services->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{lang} });

  my $internet_info = $Internet_services->user_info({ UID => $uid });
  if (!$internet_info->{TOTAL} || $internet_info->{TOTAL} != 1) {
    return;
  }

  my @changeable_fields = qw(CID CPE_MAC);
  my $internet_params = {};

  for my $pair (split(/;/, $self->{conf}{STORAGE_INTERNET_ASSIGN})) {
    my ($key, $value) = split(/=/, $pair, 2);

    if (!grep { $_ eq $key } @changeable_fields) {
      next;
    }

    if ($value =~ /:/) {
      my @candidates = split(/:/, $value);
      for my $candidate (@candidates) {
        if (defined $installation->{$candidate} && $installation->{$candidate} ne '') {
          $internet_params->{$key} = $installation->{$candidate};
          last;
        }
      }
    }
    elsif (defined $installation->{$value} && $installation->{$value}) {
      $internet_params->{$key} = $installation->{$value};
    }
  }

  if (!$self->{conf}{INTERNET_CID_FORMAT} && $internet_params->{CID}) {
    $internet_params->{CID} = Abills::Filters::_mac_former($internet_params->{CID});
  }

  if ($internet_params->{CPE_MAC} && $self->{conf}{INTERNET_CPE_FORMAT}) {
    $internet_params->{CPE_MAC} = Abills::Filters::_mac_former($internet_params->{CPE_MAC});
  }

  my $clear_params = {};
  foreach my $key (keys %{$internet_params}) {
    if ($internet_params->{$key} && $internet_info->{$key} && $internet_params->{$key} eq $internet_info->{$key}) {
      $clear_params->{$key} = '';
    }
  }

  if (%{$internet_params}) {
    $Internet_services->user_change({
      %{$clear_params},
      ID  => $internet_info->{ID},
      UID => $uid
    });
  }
}

1;