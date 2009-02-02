
class Value < Sequel::Model(:values)

    set_schema do
        primary_key :id
        text :value
        
        foreign_key :key_id, :table => :keys
        foreign_key :environment_id, :table => :environments
    end
end

EscData.init_model(Value)

