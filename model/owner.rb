
class Owner < Sequel::Model(:owners)
    set_schema do
        primary_key :id
        text :name
        text :email
        text :password
    end
    
    validates_uniqueness_of :name
    validates_uniqueness_of :email
end

EscData.init_model(Owner)

