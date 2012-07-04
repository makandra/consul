Consul - A scope-based authorization solution
=============================================

Consul is a authorization solution for Ruby on Rails that uses scopes to control what a user can see or edit.

We have used Consul in combination with [assignable_values](https://github.com/makandra/assignable_values) to solve a variety of authorization requirements ranging from boring to bizarre.


Describing a power for your application
---------------------------------------

You describe access to your application by putting a `Power` model into `app/models/power.rb`:

    class Power
      include Consul::Power

      def initialize(user)
        @user = user
      end

      power :notes do
        Note.by_author(@user)
      end

      power :users do
        User if @user.admin?
      end

      power :dashboard do
        true # not a scope, but a boolean power. This is useful to control access to stuff that doesn't live in the database.
      end

    end

There are no restrictions on the name or constructor arguments of your power class.


Querying a power
----------------

Common things you might want from a power:

1. Get its scope
2. Ask whether it is there
3. Raise an error unless it its there
4. Ask whether a given record is included in its scope
5. Raise an error unless a given record is included in its scope

Here is how to do all of that:

    power = Power.new(user)
    power.notes # => returns an ActiveRecord::Scope
    power.notes? # => returns true if Power#notes returns a scope
    power.notes! # => raises Consul::Powerless unless Power#notes returns a scope
    power.note?(Note.last) # => returns whether the given Note is in the Power#notes scope. Caches the result for subsequent queries.
    power.note!(Note.last) # => raises Consul::Powerless unless the given Note is in the Power#notes scope

You can also write power checks like this:

    power.include?(:notes)
    power.include!(:notes)
    power.include?(:note, Note.last)
    power.include!(:note, Note.last)


Boolean powers
--------------

Boolean powers are useful to control access to stuff that doesn't live in the database:

    class Power
      ...

      power :dashboard do
        true
      end

    end

You can query it like the other powers:

    power.dashboard? # => true
    power.dashboard! # => raises Consul::Powerless unless Power#dashboard? returns true


Role-based permissions
----------------------

Consul has no built-in support for role-based permissions, but you can easily implement it yourself. Let's say your `User` model has a string column `role` which can be `"author"` or `"admin"`:

    class Power
      include Consul::Power

      def initialize(user)
        @user = user
      end

      power :notes do
        case role
          when :admin then Note
          when :author then Note.by_author
        end
      end

      private

      def role
        @user.role.to_sym
      end

    end


Controller integration
----------------------

It is convenient to expose the power for the current request to the rest of the application. Consul will help you with that if you tell it how to instantiate a power for the current request:

    class ApplicationController < ActionController::Base
      include Consul::Controller

      current_power do
        Power.new(current_user)
      end

    end

You now have a helper method `current_power` for your controller and views. Everywhere else, you can access it from `Power.current`. The power will be instantiated when the request is handed over from routing to `ApplicationController`, and will be nilified once the request was processed.

You can now use power scopes to control access:

    class NotesController < ApplicationController

      def show
        @note = current_power.notes.find(params[:id])
      end

    end


### Protect entry into controller actions

To make sure a power is given before every action in a controller:

    class NotesController < ApplicationController
      power :notes
    end

You can use `:except` and `:only` options like in before filters.

You can also map different powers to different actions:

    class NotesController < ApplicationController
      power :notes, :map => { [:edit, :update, :destroy] => :changable_notes }
    end

Actions that are not listed in `:map` will get the default action `:notes`.

Note that in moderately complex authorization scenarios you will often find yourself writing a map like this:

    class NotesController < ApplicationController
      power :notes, :map => {
        [:edit, :update] => :updatable_notes
        [:new, :create] => :creatable_notes
        [:destroy] => :destroyable_notes
      }
    end

Because this pattern is so common, there is a shortcut `:crud` to do the same:

    class NotesController < ApplicationController
      power :crud => :notes
    end


### Auto-mapping a power scope to a controller method

It is often convenient to map a power scope to a private controller method:

    class NotesController < ApplicationController

      power :notes, :as => end_of_association_chain

      def show
        @note = end_of_association_chain.find(params[:id])
      end

    end

This is especially useful when you are using a RESTful controller library like [resource_controller](https://github.com/jamesgolick/resource_controller). The mapped method is aware of the `:map` option.


### How to never forget a power check

You can force yourself to use a `power` check in every controller. This will raise `Consul::UncheckedPower` if you ever forget it:

    class ApplicationController < ActionController::Base
      include Consul::Controller
      require_power_check
    end

Should you for some obscure reason want to forego the power check:

    class ApiController < ApplicationController
      skip_power_check
    end


Validating assignable values
----------------------------

Sometimes a scope is not enough to express what a user can edit. You will often want to give a user write access to a record, but restrict the values she can assign to a given field.

Consul leverages the [assignable_values](https://github.com/makandra/assignable_values) gem to add an optional authorization layer to your models. This layer adds additional validations in the context of a request, but skips those validations in other contexts (console, background jobs, etc.).

You can enable the authorization layer by using the macro `authorize_values_for`:

    class Story < ActiveRecord::Base
      authorize_values_for :state
    endy

The macro defines an accessor `power` on instances of `Story`. If that field is set to a power, the values of `state` will be validated against a whitelist of values provided by that power. If that field is `nil`, the validation is skipped.

Here is a power implementation that can provide a list of assignable values for the example above:

    class Power
      ...

      def assignable_story_states(story)
        if admin?
          ['delivered', 'accepted', 'rejected']
        else
          ['delivered']
        end
      end

    end

Here you can see how to activate the authorization layer and use the new validations:

    story = Story.new
    Power.current = Power.new(:role => :guest) # activate the authorization layer

    story.assignable_states # ['delivered'] # apparently we're not admins

    story.state = 'accepted' # a disallowed value
    story.valid? # => false

    story.state = 'delivered' # an allowed value
    story.valid? # => true

You can not only authorize scalar attributes like strings or integers that way, you can also authorize `belongs_to` associations:

    class Story < ActiveRecord::Base
      belongs_to :project
      authorize_values_for :project
    end

    class Power
      ...

      def assignable_story_projects(story)
        user.account.projects
      end
    end

The `authorize_values_for` macro comes with many useful options and details best explained in the [assignable_values README](https://github.com/makandra/assignable_values), so head over there for more. The macro is basically a shortcut for this:

    assignable_values_for :field, :through => lambda { Power.current }


Installation
------------

Add the following to your `Gemfile`:

    gem 'consul'

Now run `bundle install` to lock the gem into your project.


Development
-----------

A Rails 2 test application lives in `spec/app_root`. You can run specs from the project root by saying:

  bundle exec rake spec

If you would like to contribute:

- Fork the repository.
- Push your changes **with specs**.
- Send me a pull request.

I'm very eager to keep this gem leightweight and on topic. If you're unsure whether a change would make it into the gem, [talk to me beforehand](mailto:henning.koch@makandra.de).


Credits
-------

Henning Koch from [makandra](http://makandra.com/)
