
class App < Sequel::Model(:apps)
    set_schema do
        primary_key :id
        text :name
    end

    validates_uniqueness_of :name
end

init_model(App)

