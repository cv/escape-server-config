
class Environment < Sequel::Model(:environments)
    many_to_many :apps

    set_schema do
        primary_key :id
        text :name
    end

    validates_uniqueness_of :name
end

init_model(Environment)

