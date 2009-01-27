
class App < Sequel::Model(:apps)
    set_schema do
        primary_key :id
        text :name
    end
end

App.create_table!

