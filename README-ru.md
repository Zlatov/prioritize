# Prioritize

Позволяет сортировать как простые так и вложенные списки (например списки на основе гема closure_tree).

__Выбрать язык README.md__

-   en [English](README.md)
-   ru [Русский](README-ru.md)

__Важно!__ Работает только с PostgreSQL бд. Обновление данных происходит за 1
  запрос, Пока что нет "ActiveRecord" алгоритма, на подобии: выбрать данные ->
  перебрать-преобразовать -> сохранить. Только SQL, только хардкор.

_Prioritize_ добавляет следующие возможности:

1.   Добавляет в класс и экземпляр класса метод
`.priority_after(prev_id, moved_id)`, который обновит значения колонки
`my_column` (указанной в настройках) так, чтобы при
`Section.order(my_column: :asc)` элемент `moved` следавал за `prev`.

2.   Если при сохранении экземпляра модели в дополнительном поле `priority_prev`
указать идентификатор предыдущего элемента или строку '^' (при перемещении в
начало), тогда сработает поведение и значения колонки `my_column` обновятся в
соответствии с перемещением.




## Установка

Добавьте эту строку в Gemfile вашего приложения:

```ruby
gem 'prioritize', '~> 1.0'
```

Затем выполните:

```sh    
bundle install
```

Или установить его самостоятельно как:

```sh    
gem install prioritize
```




## Использование

Выполните подобную миграцию для вашей модели, если это необходимо:

```rb
add_column :sections, "order", :integer , null: false, default: 0
add_index :sections, "order"
```

Добавте настроечный метод в код класса:

```rb
class Section < ApplicationRecord
  prioritize_column(:order)
end
```

Настройка окончена, наблюдаем результат в консоли:

```sh
# Создадим несколько экземпляров
Section.create
=> #<Section... id: 1, order: 0...>
Section.create
=> #<Section... id: 2, order: 0...>

# Выведем идентификаторы с необходимым порядком.
Section.order(order: :asc).pluck(:id)
=> [1, 2]

# Приоритет: после 2 следует 1
Section.priority_after(2, 1)
Section.order(order: :asc).pluck(:id)
=> [2, 1]

# Переместим элемент 1 в начало
Section.find(1).priority_after(nil)
Section.order(order: :asc).pluck(:id)
=> [1, 2]
```

При перемещении элементов на фронтэнде (например с jquery-ui) нам необходимо отправить на контроллер
PATCH запрос примерно следующего характера с дополнительным полем `priority_prev`:

```js
$.ajax({
  url: "/sections/1.json",
  type: "PATCH",
  data: {
    section: {
      priority_prev: 2
    }
  }
})
```

В контроллере необходимо разрешить параметр `priority_prev`:

```rb
  def section_params
    params.require(:section).permit(
      ...
      :order,
      :priority_prev
    )
  end
```

При присутствии значения в поле `priority_prev` будет срабатывать обратный вызов, в котором
вызывается `.priority_after` метод.




### Использование при сортировки древовидных структур

Модель

```rb
class Catalog < ApplicationRecord
  prioritize_column(:order, nested: true)
end
```

При обновлении значений колонки :order используются только элементы с тем же
предком что и перемещаемый элемент.




## Разработка

При желании протестировать изменения гема с вашим приложением необходимо перенастроить Gemfile:

```ruby
# Сортировка
# gem 'prioritize', '~> 1.0'
gem 'prioritize', path: '/home/username/path/to/cloned/prioritize'
```

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to [rubygems.org]
(https://rubygems.org).

```sh
bundle
rake spec
```

## Содействие

Отчеты об ошибках и запросы на включение приветствуются на GitHub https://github.com/Zlatov/prioritize.


## Лицензия

Гем доступен с открытым исходным кодом в соответствии с условиями
[MIT License](https://opensource.org/licenses/MIT).
