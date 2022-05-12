# Prioritize

Allows you to sort both simple and nested lists (for example, lists based on the
closure_tree gem).

__Select language README.md__

-   en [English](README.md)
-   ru [Русский](README-ru.md)

__Important!__ Only works with PostgreSQL databases. Updating data occurs in 1
  request, So far there is no "ActiveRecord" algorithm, like: select data ->
  sort-transform data -> save. Only SQL, only hardcore.

_Prioritize_ adds the following features:

1. Adds a method `.priority_after(prev_id, moved_id)` to the class and class
instance, which will update the values of the `my_column` column (specified in
the settings) so that when `Section.order(my_column: :asc)` the `moved` element
followed the `prev`.

2. If, when saving a model instance, in the additional field `priority_prev`
specify the identifier of the previous element or the string '^' (when moving
to the beginning), then the behavior will work and the values of the
`my_column` column will be updated in accordance with the movement.




## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prioritize', '~> 1.0'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install prioritize




## Usage

Perform a similar migration for your model if necessary:

```rb
add_column :sections, "order", :integer , null: false, default: 0
add_index :sections, "order"
```

Add a setup method to the class code:

```rb
class Section < ApplicationRecord
  prioritize_column(:order)
end
```

The setup is over, we observe the result in the console:

```sh
# Let's create multiple instances
Section.create
=> #<Section... id: 1, order: 0...>
Section.create
=> #<Section... id: 2, order: 0...>

# Let's derive the identifiers with the required order.
Section.order(order: :asc).pluck(:id)
=> [1, 2]

# Priority: 2 followed by 1
Section.priority_after(2, 1)
Section.order(order: :asc).pluck(:id)
=> [2, 1]

# Move element 1 to the beginning
Section.find(1).priority_after(nil)
Section.order(order: :asc).pluck(:id)
=> [1, 2]
```

When moving elements on the frontend (for example, with jquery-ui), we need to
send a PATCH request to the controller of the following nature with an
additional `priority_prev` field:

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

In the controller, the `priority_prev` parameter must be enabled:

```rb
  def section_params
    params.require(:section).permit(
      ...
      :order,
      :priority_prev
    )
  end
```

If there is a value in the `priority_prev` field, a callback will be fired in
which the `.priority_after` method is called.




## Development

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Zlatov/prioritize.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
