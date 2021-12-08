package Abills::Api::Paths;

sub list {
  return {
    users     => [
      {
        method      => 'GET',
        path        => '/users/:uid/',
        handler     => 'info(:uid)',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/users/:uid/',
        handler     => 'change(:uid, {
          ...PARAMS
        })',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/users/:uid/',
        handler     => 'del({
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/pi/',
        handler     => 'pi({ UID => :uid })',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/',
        handler     => 'add({
          ...PARAMS
        })',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/pi/',
        handler     => 'pi({ UID => :uid })',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/:uid/pi/',
        handler     => 'pi_add({
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/users/:uid/pi/',
        handler     => 'pi_change({
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Users',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/abon/',
        handler     => 'user_tariff_list(:uid, {
          COLS_NAME => 1
        })',
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/:uid/internet/',
        handler     => 'user_add({
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/internet/',
        handler     => 'user_list({
          UID       => :uid,
          CID             => "_SHOW",
          INTERNET_STATUS => "_SHOW",
          TP_NAME         => "_SHOW",
          MONTH_FEE       => "_SHOW",
          DAY_FEE         => "_SHOW",
          TP_ID           => "_SHOW",
          COLS_NAME       => 1,
          ...PARAMS
        })',
        module      => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/internet/:id/',
        handler     => 'user_info(:uid, {
          ID        => :id,
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Internet',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/contacts/',
        handler     => "contacts_list({
          ...PARAMS,
          UID => '_SHOW'
        })",
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/contacts/',
        handler     => "contacts_list({
          UID       => :uid,
          VALUE     => '_SHOW',
          PRIORITY  => '_SHOW',
          TYPE      => '_SHOW',
          TYPE_NAME => '_SHOW',
        })",
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/users/:uid/contacts/',
        handler     => "contacts_add({
          UID => :uid,
          ...PARAMS
        })",
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/users/:uid/contacts/:id/',
        handler     => "contacts_del({
          ID  => :id,
          UID => :uid,
          ...PARAMS
        })",
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/users/:uid/contacts/:id/',
        handler     => "contacts_change({
          ID  => :id,
          UID => :uid,
          ...PARAMS
        })",
        module      => 'Contacts',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/iptv/',
        handler     => 'user_list({
          UID          => :uid,
          SERVICE_ID   => "_SHOW",
          TP_FILTER    => "_SHOW",
          MONTH_FEE    => "_SHOW",
          DAY_FEE      => "_SHOW",
          TP_NAME      => "_SHOW",
          SUBSCRIBE_ID => "_SHOW",
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Iptv',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/users/:uid/iptv/:id/',
        handler     => 'user_info(:id, {
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Iptv',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    admins    => [
      {
        method      => 'POST',
        path        => '/admins/:aid/contacts/',
        handler     => 'admin_contacts_add({
          AID     => :aid,
          ...PARAMS
        })',
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/admins/:aid/contacts/',
        handler     => 'admin_contacts_change({
          AID     => :aid,
          ...PARAMS
        })',
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/admins/:aid/',
        handler     => 'info(:aid, {
          ...PARAMS
        })',
        module      => 'Admins',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    tp        => [
      {
        method      => 'GET',
        path        => '/tp/:tpID/',
        handler     => 'info(undef, {
          TP_ID => :tpID,
          ...PARAMS
        })',
        module      => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/tp/:tpID/intervals/',
        handler     => 'ti_list({
          TP_ID => :tpID,
          COLS_NAME => 1
        })',
        module      => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    abon      => [
      {
        method      => 'GET',
        path        => '/abon/tariffs/',
        handler     => 'tariff_list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/abon/tariffs/',
        handler     => 'tariff_add({
          ...PARAMS
        })',
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/abon/tariffs/:id/',
        handler     => 'tariff_info(:id)',
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/abon/tariffs/:id/users/:uid/',
        handler     => 'user_tariff_change({
          IDS => :id,
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/abon/tariffs/:id/users/:uid/',
        handler     => 'user_tariff_change({
          DEL => :id,
          UID => :uid,
        })',
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/abon/users/',
        handler     => 'user_list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Abon',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    intervals => [
      {
        method      => 'GET',
        path        => '/intervals/:tpID/',
        handler     => 'ti_info(:tpID)',
        module      => 'Tariffs',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    groups    => [
      {
        method      => 'GET',
        path        => '/groups/',
        handler     => 'groups_list({
          NAME           => "_SHOW",
          DOMAIN_ID      => "_SHOW",
          DESCR          => "_SHOW",
          DISABLE_CHG_TP => "_SHOW",
          COLS_NAME      => 1
        })',
        module      => 'Users',
        type        => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    msgs      => [
      {
        method      => 'POST',
        path        => '/msgs/',
        handler     => 'message_add({
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/msgs/:id/',
        handler     => 'message_info(:id)',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/msgs/list/',
        handler     => 'messages_list({
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
      },
      {
        method      => 'POST',
        path        => '/msgs/:id/reply/',
        handler     => 'message_reply_add({
          ID    => :id,
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/msgs/:id/reply/',
        handler     => 'messages_reply_list({
          MSG_ID    => :id,
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
        method       => 'POST',
        path         => '/msgs/reply/:reply_id/attachment/',
        handler      => 'attachment_add({
          REPLY_ID  => :reply_id,
          COLS_NAME => 1,
          ...PARAMS
        })',
        module       => 'Msgs',
        credentials  => [
          'ADMIN'
        ],
        use_function => '1'
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
    ],
    pages     => [],
    version   => [],
    currency  => [],
    builds    => [
      {
        method      => 'GET',
        path        => '/builds/',
        handler     => "build_list({
          COLS_NAME => 1,
          DISTRICT_NAME => '_SHOW',
          STREET_NAME   => '_SHOW',
          ...PARAMS
        })",
        module      => 'Address',
        type        => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/builds/:id/',
        handler     => "build_info({
          COLS_NAME => 1,
          ID => :id,
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/builds/',
        handler     => "build_add({
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/builds/:id/',
        handler     => "build_change({
          ID => :id,
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    streets   => [
      {
        method      => 'GET',
        path        => '/streets/',
        handler     => "street_list({
          COLS_NAME => 1,
          STREET_NAME => '_SHOW',
          BUILD_COUNT => '_SHOW',
          DISTRICT_ID => '_SHOW',
          ...PARAMS
        })",
        module      => 'Address',
        type        => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/streets/:id/',
        handler     => "street_info({
          COLS_NAME => 1,
          ID        => :id,
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/streets/',
        handler     => "street_add({
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/streets/:id/',
        handler     => "street_change({
          ID => :id,
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    districts => [
      {
        method      => 'GET',
        path        => '/districts/',
        handler     => "district_list({
          COLS_NAME => 1,
          ...PARAMS
        })",
        module      => 'Address',
        type        => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/districts/',
        handler     => "district_add({
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/districts/:id/',
        handler     => "district_info({
          COLS_NAME => 1,
          ID        => :id,
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'PUT',
        path        => '/districts/:id/',
        handler     => "district_change({
          ID => :id,
          ...PARAMS
        })",
        module      => 'Address',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    online    => [
      {
        method      => 'GET',
        path        => '/online/:uid/',
        handler     => "online({
          UID             => :uid,
          CLIENT_IP_NUM   => '_SHOW',
          NAS_ID          => '_SHOW',
          USER_NAME       => '_SHOW',
          CLIENT_IP       => '_SHOW',
          DURATION        => '_SHOW',
          STATUS          => '_SHOW',
        })",
        module      => 'Sessions',
        subpackage  => 'Internet',
        type        => 'ARRAY',
        credentials => [
          'ADMIN'
        ]
      },
    ],
    payments  => [
      {
        method      => 'GET',
        path        => '/payments/types/',
        handler     => 'payment_type_list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/payments/users/:uid/',
        handler     => 'list({
          UID       => :uid,
          DESC      => "DESC",
          SUM       => "_SHOW",
          REG_DATE  => "_SHOW",
          METHOD    => "_SHOW",
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/payments/users/:uid/',
        handler     => 'add({ UID => :uid }, {
          UID       => :uid,
          ...PARAMS
        })',
        module      => 'Payments',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    fees      => [
      {
        method      => 'GET',
        path        => '/fees/types/',
        handler     => 'fees_type_list({
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'GET',
        path        => '/fees/users/:uid/',
        handler     => 'list({
          UID       => :uid,
          SUM       => "_SHOW",
          DESCRIBE  => "_SHOW",
          REG_DATE  => "_SHOW",
          METHOD    => "_SHOW",
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      },
      {
        method      => 'POST',
        path        => '/fees/users/:uid/:sum/',
        handler     => 'take({ UID => :uid },:sum, {
          UID       => :uid,
          ...PARAMS
        })',
        module      => 'Fees',
        credentials => [
          'ADMIN'
        ]
      }
    ],
    user      => [
      {
        method      => 'GET',
        path        => '/user/:uid/',
        handler     => 'info(:uid)',
        module      => 'Users',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/pi/',
        handler     => 'pi({ UID => :uid })',
        module      => 'Users',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/credit/',
        handler     => 'user_set_credit({
          UID           => :uid,
          COLS_NAME     => 1,
          PAGE_ROWS     => 1,
          change_credit => 1
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/credit/',
        handler     => 'user_set_credit({
          UID       => :uid,
          COLS_NAME => 1,
          PAGE_ROWS => 1
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/',
        handler     => 'user_list({
          UID             => :uid,
          CID             => "_SHOW",
          INTERNET_STATUS => "_SHOW",
          TP_NAME         => "_SHOW",
          MONTH_FEE       => "_SHOW",
          DAY_FEE         => "_SHOW",
          TP_ID           => "_SHOW",
          COLS_NAME       => 1,
          PAGE_ROWS       => 1
        })',
        module      => 'Internet',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/speed/',
        handler     => 'get_speed({
          UID             => :uid,
          COLS_NAME       => 1,
          PAGE_ROWS       => 1
        })',
        module      => 'Internet',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/speed/:tpid/',
        handler     => 'get_speed({
          TP_NUM          => :tpid,
          COLS_NAME       => 1,
          PAGE_ROWS       => 1
        })',
        module      => 'Internet',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/internet/:id/holdup/',
        handler     => 'user_holdup({
          UID          => :uid,
          ID           => :id,
          COLS_NAME    => 1,
          PAGE_ROWS    => 1,
          add          => 1,
          ACCEPT_RULES => 1,
          ...PARAMS
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'DELETE',
        path        => '/user/:uid/internet/:id/holdup/',
        handler     => 'user_holdup({
          UID       => :uid,
          ID        => :id,
          del       => 1,
          COLS_NAME => 1,
          PAGE_ROWS => 1
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/tariffs/',
        handler     => 'available_tariffs({
          SKIP_NOT_AVAILABLE_TARIFFS => 1,
          UID                        => :uid,
          MODULE                     => "Internet"
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/tariffs/all/',
        handler     => 'available_tariffs({
          UID                        => :uid,
          MODULE                     => "Internet"
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/internet/:id/warnings/',
        handler     => 'service_warning({
          UID    => :uid,
          ID     => :id,
          MODULE => "Internet"
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'PUT',
        path        => '/user/:uid/internet/:id/',
        handler     => 'user_chg_tp({
          UID    => :uid,
          ID     => :id,
          MODULE => "Internet",
          ...PARAMS
        })',
        module      => 'Control::Service_control',
        credentials => [
          'USER'
        ]
      },

      {
        method      => 'GET',
        path        => '/user/:uid/msgs/',
        handler     => 'messages_list({
          COLS_NAME     => 1,
          SUBJECT       => "_SHOW",
          STATE_ID      => "_SHOW",
          DATE          => "_SHOW",
          MESSAGE       => "_SHOW",
          CHAPTER_NAME  => "_SHOW",
          CHAPTER_COLOR => "_SHOW",
          STATE         => "_SHOW",
          UID           => :uid
        })',
        module      => 'Msgs',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/msgs/',
        handler     => 'message_add({
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/msgs/:id/',
        handler     => 'message_info(:id, { UID => :uid })',
        module      => 'Msgs',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/msgs/:id/reply/',
        handler     => 'messages_reply_list({
          MSG_ID    => :id,
          UID       => :uid,
          LOGIN     => "_SHOW",
          ADMIN     => "_SHOW",
          COLS_NAME => 1
        })',
        module      => 'Msgs',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/msgs/:id/reply/',
        handler     => 'message_reply_add({
          ID  => :id,
          UID => :uid,
          ...PARAMS
        })',
        module      => 'Msgs',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/abon/',
        handler     => 'user_tariff_list(:uid, {
          COLS_NAME => 1
        })',
        module      => 'Abon',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/payments/',
        handler     => 'list({
          UID       => :uid,
          DSC       => "_SHOW",
          SUM       => "_SHOW",
          REG_DATE  => "_SHOW",
          METHOD    => "_SHOW",
          EXT_ID    => "_SHOW",
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Payments',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'POST',
        path        => '/user/:uid/payments/add',
        handler     => 'add({ UID => :uid }, {
          UID       => :uid,
          ...PARAMS
        })',
        module      => 'Payments',
        credentials => [
          'USER'
        ]
      },
      {
        method      => 'GET',
        path        => '/user/:uid/fees/',
        handler     => 'list({
          UID       => :uid,
          SUM       => "_SHOW",
          DESCRIBE  => "_SHOW",
          REG_DATE  => "_SHOW",
          METHOD    => "_SHOW",
          COLS_NAME => 1,
          ...PARAMS
        })',
        module      => 'Fees',
        credentials => [
          'USER'
        ]
      },
    ]
  };
}

1;