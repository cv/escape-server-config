
class Key < Sequel::Model(:keys)
    set_schema do
        primary_key :id
        text :name

        foreign_key :app_id, :table => :apps
    end

end

init_model(Key)

