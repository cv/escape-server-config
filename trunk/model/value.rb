
class Value < Sequel::Model(:values)
    many_to_one :apps
    many_to_one :environments
    set_schema do
        primary_key :id
        text :key
        text :value
        foreign_key :app, :table => :apps
        foreign_key :environment, :table => :environments
    end
end

init_model(Value)

