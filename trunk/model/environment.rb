
class Environment < Sequel::Model(:environments)
    many_to_one :owner
    many_to_one :app
    set_schema do
        primary_key :id
        text :name
    end
end

init_model(Environment)

