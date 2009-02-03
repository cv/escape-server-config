
class AppsEnvironments < Sequel::Model
    set_schema do
        integer :app_id
        integer :environment_id
    end
end

EscData.init_model(AppsEnvironments)

class AppsKeys < Sequel::Model
    set_schema do
        integer :app_id
        integer :key_id
    end
end

EscData.init_model(AppsKeys)

class OwnerAppEnv < Sequel::Model
    set_primary_key [:app_id, :environment_id]
    set_schema do
        integer :app_id
        integer :environment_id
        integer :owner_id
    end
end

EscData.init_model(OwnerAppEnv)

