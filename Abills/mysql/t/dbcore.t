use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::MockObject;


use lib '.';
use lib '../';
use lib '../../../lib/';
use Admins;
use dbcore;

# Создаем тестируемый объект
my $changes = bless {
  conf => 1,
  admin => Test::MockObject->new,
  db    => Test::MockObject->new,
}, 'Admins';

# Подготовка заглушек для методов
$changes->{admin}->mock('action_add', sub { pass('admin->action_add called') });
$changes->{admin}->mock('system_action_add', sub { pass('system_action_add called') });
$changes->{db}->mock('query', sub {
  my ($self, $sql, $mode, $opts) = @_;
  pass("Query executed: $sql");
  $changes->{AFFECTED} = 1;
  return { id => 1, name => 'old_name', email => 'old@example.com' } if $mode eq 'hash';
  return 1;
});

# Тест 1: Ошибка email
$changes->{errno} = 0;
my $res = $changes->changes({
  TABLE => 'users',
  CHANGE_PARAM => 'id',
  FIELDS => { id => 'id', email => 'email' },
  DATA => { id => 1, email => 'wrong_email' },
});

is($res->{errno}, 11, 'Invalid email triggers errno 11');

# Тест 2: Обновление одного поля
$changes->{errno} = 0;
$res = $changes->changes({
  TABLE => 'users',
  CHANGE_PARAM => 'id',
  FIELDS => { id => 'id', name => 'name' },
  DATA => { id => 1, name => 'new_name' },
});

ok(!$res->{errno}, 'No error during change');
ok($res->{AFFECTED} == 1, 'One row affected');

# Тест 3: Нет изменений, изменений не происходит
$changes->{errno} = 0;
$res = $changes->changes({
  TABLE => 'users',
  CHANGE_PARAM => 'id',
  FIELDS => { id => 'id', name => 'name' },
  DATA => { id => 1, name => 'old_name' },
});

ok(!$res->{errno}, 'No error if no changes needed');
ok(!$res->{AFFECTED}, 'No rows affected if values are the same');

# Тест 4: Отсутствие conf вызывает exit (отлавливаем die)
my $test_obj = bless { admin => 1 }, 'Admins';

throws_ok {
  $test_obj->changes({ TABLE => 'users' });
} qr/Changes conf undefined/, 'Dies when conf is missing';

# Тест 5: Отсутствие admin вызывает exit (отлавливаем die)
$test_obj = bless { conf => 1 }, 'Admins';

throws_ok {
  $test_obj->changes({ TABLE => 'users' });
} qr/Changes Admin/, 'Dies when admin is missing';


# Завершение
done_testing();

1;