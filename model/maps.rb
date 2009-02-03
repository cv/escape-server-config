
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
    set_schema do
        primary_key :id
        integer :app_id
        integer :environment_id
        integer :owner_id
    end

    validates_uniqueness_of([:app_id, :environment_id])
end

EscData.init_model(OwnerAppEnv)

