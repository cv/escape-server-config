
class App < Sequel::Model(:apps)
    many_to_many :environments
    set_schema do
        primary_key :id
        text :name
    end

    validates_uniqueness_of :name
end

init_model(App)
