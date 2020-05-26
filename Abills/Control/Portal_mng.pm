=head NAME

 Portal_mng functions

=cut

use strict;
use warnings FATAL => 'all';

our Abills::HTML $html;
our (
  %lang,
  $Conf,
  $db,
  $admin
);

#**********************************************************
=head2 get_info_fields_read_only_view($attr)

  Arguments:
    COMPANY                - Company info fields
    VALUES                 - Info field value hash_ref
    RETURN_AS_ARRAY        - returns hash_ref for name => $input (for custom design logic)
    CALLED_FROM_CLIENT_UI  - apply client_permission view/edit logic

  Returns:
    Return formed HTML

=cut
#**********************************************************
sub get_info_fields_read_only_view {
  my ($attr) = @_;

  if (!$users && $user) {
    $users = $user;
  }

  my @field_result = ();
  my @name_view_arr = ();

  my $prefix = $attr->{COMPANY} ? 'ifc*' : 'ifu*';
  my $list;

  if (!$conf{info_fields_new}) {
    $list = $Conf->config_list(
      {
        PARAM => $prefix,
        SORT  => 2
      }
    );
  }
  else {
    $list = new_info_fields($list, { 
      POPUP   => $attr->{POPUP}, 
      COMPANY => $attr->{COMPANY}
    }); 
  }

  my $uid = $FORM{UID} || q{};

  if ($FORM{json}) {
    return [];
  }

  my %FIELD_TYPE_ID = (
    'STRING'         => 0,
    'INTEGER'        => 1,
    'LIST'           => 2,
    'TEXT'           => 3,
    'FLAG'           => 4,
    'BLOB'           => 5,
    'PCRE'           => 6,
    'AUTOINCREMENT'  => 7,
    'ICQ'            => 8,
    'URL'            => 9,
    'PHONE'          => 10,
    'E-MAIL'         => 11,
    'SKYPE'          => 12,
    'FILE'           => 13,
    ''               => 14,
    'PHOTO'          => 15,
    'SOCIAL NETWORK' => 16,
    'CRYPT'          => 17,
  );

  if ($list) {
    foreach my $line (@{ $list }) {
      my $field_id = '';
      if ($line->[0] =~ /$prefix(\S+)/) {
        $field_id = $1;
      }
      my (undef, $type, $name, $user_portal) = split(/:/, $line->[1]);
      next if ($attr->{CALLED_FROM_CLIENT_UI} && !$user_portal);

      $type //= 0;

      next if (
        $type == $FIELD_TYPE_ID{'SOCIAL NETWORK'}
          || $type == $FIELD_TYPE_ID{BLOB}
          || $type == $FIELD_TYPE_ID{CRYPT}
      );

      my $field_name = uc($field_id);
      my $value = $attr->{VALUES}->{$field_name} // '';
      my $value_view = '';

      if ($type eq $FIELD_TYPE_ID{LIST}) {
        my $field_value_list = $users->info_lists_list({ LIST_TABLE => $field_id . '_list', COLS_NAME => 1 });
        if (
          # No list or broken list
          !$field_value_list || !ref $field_value_list eq 'ARRAY'
            # Empty list
            || !$field_value_list->[0]
            # Broken value
            || !ref $field_value_list->[0] eq 'HASH'
        ) {
          $value_view = $html->element(
            'span',
            $lang{ERR_NO_DATA},
            { OUTPUT2RETURN => 1 }
          );
        }
        else {
          $value_view = $html->element(
            'span',
            $value,
            { OUTPUT2RETURN => 1 }
          );
        }
      }
      elsif ($type eq $FIELD_TYPE_ID{FLAG}) {
        $value_view = $html->element(
          'span',
          ($value)
            ? $lang{YES}
            : $lang{NO},
          { OUTPUT2RETURN => 1 }
        );
      }
      elsif ($type == $FIELD_TYPE_ID{URL}) {

        if ($attr->{VALUES}->{$field_name}) {
          $value_view = $html->button(
            $lang{GO},
            '',
            {
              GLOBAL_URL => $attr->{VALUES}->{$field_name},
              ADD_ICON   => 'glyphicon glyphicon-globe'
            }
          );
        }
        else {
          $value_view = $html->element('span', $lang{ERR_NO_DATA}, { OUTPUT2RETURN => 1 });
        }
      }
      elsif ($type == $FIELD_TYPE_ID{TEXT}) {
        $value_view = $html->element('p', $attr->{VALUES}->{$field_name}, { OUTPUT2RETURN => 1 }),
      }
      elsif ($type == $FIELD_TYPE_ID{FILE}) {
        my $Attach = Attach->new($db, $admin, \%conf);
        my $file_id = $value || q{};

        $Attach->attachment_info({ ID => $file_id, TABLE => $field_id . '_file' });

        my $file_name = q{};
        if (!$Attach->{TOTAL}) {
          $value_view = $html->element('span', $lang{NO}, { OUTPUT2RETURN => 1 });
        }
        else {
          $file_name = $Attach->{FILENAME};

          my $file_download_url = "?qindex=" . (get_function_index('user_pi') || $index)
            . "&ATTACHMENT=$field_id:$file_id"
            . (($uid) ? "&UID=$uid" : '');

          $value_view = $html->button($lang{DOWNLOAD}, '', {
            GLOBAL_URL => $file_download_url,
            ADD_ICON   => 'glyphicon glyphicon-download'
          });

        }

      }
      elsif ($type == $FIELD_TYPE_ID{PHOTO}) {

        if ($html && $html->{TYPE} eq 'html') {
          # Modal for preview
          $value_view = qq{
            <div class="modal fade" id="$name\_preview" tabindex="-1" role="dialog">
              <div class="modal-dialog" role="document">
                <div class="modal-content">
                  <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                    <h4 class="modal-title">$name</h4>
                  </div>
                  <div class="modal-body">
                    <img class='img img-responsive' src="$SELF_URL?qindex=$index&PHOTO=$uid&UID=$uid" alt="$field_name">
                  </div>
                  <div class="modal-footer">
                    <button type="button" class="btn btn-default" data-dismiss="modal">$lang{CLOSE}</button>
                  </div>
                </div>
              </div>
            </div>
            <button type="button" class="btn btn-xs btn-default" data-toggle="modal" data-target="#$name\_preview">
              <span class="glyphicon glyphicon-picture"></span>$lang{PREVIEW}
            </button>
          };
        }
        else {
          $value_view = $html->button('', "index=$index&PHOTO=$uid&UID=$uid", { ICON => 'glyphicon glyphicon-camera' });
        }
      }
      else {
        $value_view = $html->element(
          'span',
          (($attr->{VALUES} && $attr->{VALUES}->{$field_name}) || $FORM{$field_name})
            ? $attr->{VALUES}->{$field_name}
            : '',
          { OUTPUT2RETURN => 1 }
        );
      }

      if ($attr->{RETURN_AS_ARRAY}) {
        push(@name_view_arr, {
          ID   => $field_id,
          TYPE => $type,
          NAME => _translate($name),
          VIEW => $value_view
        });
        next;
      }

      $attr->{VALUES}->{ 'FORM_' . $field_name } = $value_view;

      push @field_result,
        $html->tpl_show(
          templates('form_row_dynamic_size'),
          {
            ID         => "$field_id",
            NAME       => (_translate($name)),
            VALUE      => $value_view,
            COLS_LEFT  => $attr->{COLS_LEFT} || 'col-xs-4',
            COLS_RIGHT => $attr->{COLS_RIGHT} || 'col-xs-8',
          },
          { OUTPUT2RETURN => 1, ID => "$field_id" }
        );
    }
  }

  if ($attr->{RETURN_AS_ARRAY}) {
    return \@name_view_arr;
  }

  my $info = join((($FORM{json}) ? ',' : ''), @field_result);

  return $info;
}

#**********************************************************
=head2 new_info_fields($list, $attr) - 

  Arguments:
    $list             - Empty list

    COMPANY           - 
    DOMAIN_ID         -

  Returns:
    list value fields

=cut
#**********************************************************
sub new_info_fields {
    my ($list, $attr) = @_;

    require Info_fields;
    Info_fields->import();

    my $Info_fields = Info_fields->new($db, $admin, \%conf);

    my $fields_list = $Info_fields->fields_list({
      COMPANY   => ($attr->{COMPANY} || 0),
      DOMAIN_ID => $users->{DOMAIN_ID} || 0,
      SORT      => 5,
    });
    my $iter = 0;

    foreach my $line (@$fields_list) {
      next if ( 
        $attr->{POPUP} && 
        !$attr->{POPUP}->{ $line->{SQL_FIELD} }
      );

      $list->[$iter]->[0] = ($attr->{COMPANY} ? 'ifc' : 'ifu') . $line->{SQL_FIELD};
      $list->[$iter]->[1] = join(':',
        ($line->{PRIORITY} || 0),
         $line->{TYPE},
         $line->{NAME},
         $line->{ABON_PORTAL},
         $line->{USER_CHG},
        ($line->{PATTERN} || ''),
        ($line->{TITLE} || ''),
        ($line->{PLACEHOLDER} || ''),
      );
      
      $iter++;
    }
  
  return $list || '';
}

1;