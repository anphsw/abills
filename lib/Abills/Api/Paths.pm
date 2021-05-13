package Abills::Api::Paths;

sub list {
  return {
    users => [
      {
        method  => 'GET',
        path    => '/users/:uid/',
        handler => 'info(:uid)',
        module  => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'PUT',
        path    => '/users/:uid/',
        handler => 'change(:uid, {
          ...PARAMS
        })',
        module  => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'DELETE',
        path    => '/users/:uid/',
        handler => 'del({
          UID => :uid,
          ...PARAMS
        })',
        module  => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/users/:uid/pi/',
        handler => 'pi({ UID => :uid })',
        module  => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/users/',
        handler => 'add({
          ...PARAMS
        })',
        module  => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/users/pi/',
        handler => 'list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module  => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/users/:uid/pi/',
        handler => 'pi_add({
          UID => :uid,
          ...PARAMS
        })',
        module => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'PUT',
        path    => '/users/:uid/pi/',
        handler => 'pi_change({
          UID => :uid,
          ...PARAMS
        })',
        module => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/users/:uid/abon/',
        handler => 'user_tariff_list(:uid, {
          COLS_NAME => 1
        })',
        module => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/users/:uid/internet/',
        handler => 'add({
          UID => :uid,
          ...PARAMS
        })',
        module => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/users/:uid/internet/',
        handler => 'list({
          UID       => :uid,
          COLS_NAME => 1,
          ...PARAMS
        })',
        module => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/users/:uid/internet/:id/',
        handler => 'info(:uid, {
          ID        => :id,
          COLS_NAME => 1,
          ...PARAMS
        })',
        module => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/users/:uid/contacts/',
        handler => "contacts_add({
          UID => :uid,
          ...PARAMS
        })",
        module  => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'DELETE',
        path    => '/users/:uid/contacts/',
        handler => "contacts_del({
          UID => :uid,
          ...PARAMS
        })",
        module  => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'PUT',
        path    => '/users/:uid/contacts/',
        handler => "contacts_change({
          UID => :uid,
          ...PARAMS
        })",
        module  => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    admins => [
      {
        method  => 'POST',
        path    => '/admins/android/token/save/:aid/:type/',
        handler => 'admin_contacts_add({
          AID     => :aid,
          TYPE_ID => :type,
          ...PARAMS
        })',
        module  => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/admins/android/token/change/:aid/:type/',
        handler => 'admin_contacts_change({
          AID     => :aid,
          TYPE_ID => :type,
          ...PARAMS
        })',
        module  => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/admins/',
        handler => 'info(undef, {
          ...PARAMS
        })',
        module  => 'Admins',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    tp => [
      {
        method  => 'GET',
        path    => '/tp/:tpID/',
        handler => 'info(undef, {
          TP_ID => :tpID,
          ...PARAMS
        })',
        module  => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/tp/:tpID/intervals/',
        handler => 'ti_list({
          TP_ID => :tpID,
          COLS_NAME => 1
        })',
        module  => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    abon => [
      {
        method  => 'GET',
        path    => '/abon/tariffs/',
        handler => 'tariff_list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module  => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/abon/tariffs/:id/',
        handler => 'tariff_info(:id)',
        module  => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/abon/tariffs/',
        handler => 'tariff_add({
          ...PARAMS
        })',
        module  => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/abon/tariffs/:id/users/:uid/',
        handler => 'user_tariff_change({
          IDS => :id,
          UID   => :uid,
          ...PARAMS
        })',
        module  => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'DELETE',
        path    => '/abon/tariffs/:id/users/:uid/',
        handler => 'user_tariff_change({
          DEL => :id,
          UID   => :uid,
        })',
        module  => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/abon/users/',
        handler => 'user_list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module  => 'Abon',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    intervals => [
      {
        method  => 'GET',
        path    => '/intervals/:tpID/',
        handler => 'ti_info(:tpID)',
        module  => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    groups => [
      {
        method  => 'GET',
        path    => '/groups/',
        handler => 'groups_list({ COLS_NAME => 1 })',
        module  => 'Users',
        type    => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    msgs => [
      {
        method   => 'POST',
        path     => '/msgs/:uid/send/',
        handler  => 'message_add({
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method    => 'POST',
        path      => '/msgs/:id/reply/:aid/',
        handler   => 'message_reply_add({
          ID  => :id,
          AID => :aid,
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/msgs/:state_id/',
        handler => 'messages_list({
          COLS_NAME    => 1,
          STATE_ID     => :state_id,
          SUBJECT      => "_SHOW",
          DATE         => "_SHOW",
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/msgs/info/:id/',
        handler     => 'message_info(:id)',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/msgs/info/:msg_id/reply/',
        handler     => 'messages_reply_list({
          MSG_ID    => :msg_id,
          LOGIN     => "_SHOW",
          ADMIN     => "_SHOW",
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Msgs',
        type        => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/msgs/chapters/',
        handler     => 'chapters_list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/msgs/all/',
        handler => 'messages_list({
          COLS_NAME    => 1,
          SUBJECT      => "_SHOW",
          STATE_ID     => "_SHOW",
          DATE         => "_SHOW",
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    inventory => [
      {
        method      => 'POST',
        path        => '/inventory/send/bug/',
        handler     => 'bug_add({
          ...PARAMS
        })',
        module      => 'Inventory',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    pages => [],
    builds => [
      {
        method  => 'GET',
        path    => '/builds/',
        handler => "build_list({
          COLS_NAME => 1,
          DISTRICT_NAME => '_SHOW',
          STREET_NAME   => '_SHOW',
          ...PARAMS
        })",
        module  => 'Address',
        type    => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/builds/:id/',
        handler => "build_info({
          COLS_NAME => 1,
          ID => :id,
          ...PARAMS
        })",
        module  => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/builds/',
        handler => "build_add({
          ...PARAMS
        })",
        module  => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'PUT',
        path    => '/builds/:id/',
        handler => "build_change({
          ID => :id,
          ...PARAMS
        })",
        module  => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    streets => [
      {
        method  => 'GET',
        path    => '/streets/',
        handler => "street_list({
          COLS_NAME => 1,
          STREET_NAME => '_SHOW',
          ...PARAMS
        })",
        module  => 'Address',
        type    => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'GET',
        path    => '/streets/:id/',
        handler => "street_info({
          COLS_NAME => 1,
          ID => :id,
          ...PARAMS
        })",
        module  => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'POST',
        path    => '/streets/',
        handler => "street_add({
          ...PARAMS
        })",
        module  => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method  => 'PUT',
        path    => '/streets/:id/',
        handler => "street_change({
          ID => :id,
          ...PARAMS
        })",
        module  => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    online => [
      {
        method  => 'GET',
        path    => '/online/:uid/',
        handler => "online({
          UID             => :uid,
          CLIENT_IP_NUM   => '_SHOW',
          NAS_ID          => '_SHOW',
          USER_NAME       => '_SHOW',
          CLIENT_IP       => '_SHOW',
          DURATION        => '_SHOW',
          STATUS          => '_SHOW',
        })",
        module  => 'Sessions',
        subpackage => 'Internet',
        type    => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
    ]
  };
}

1;