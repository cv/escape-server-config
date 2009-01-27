
class Value < Sequel::Model(:values)
    set_schema do
        set_primary_key [:app, :environment]
        text :key
        text :value
    end
end

Value.create_table!

