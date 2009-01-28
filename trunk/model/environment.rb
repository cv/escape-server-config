
class Environment < Sequel::Model(:environments)
    many_to_one :owner
    many_to_many :app
    set_schema do
        primary_key :id
        text :name
    end

    validates_uniqueness_of :name
end

init_model(Environment)

