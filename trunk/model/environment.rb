
class Environment < Sequel::Model(:environments)
    many_to_one :owner
    set_schema do
        primary_key :id
        text :name
    end
end

Environment.create_table!

