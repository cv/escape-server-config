
class Owner < Sequel::Model(:owners)
    set_schema do
        primary_key :id
        text :name
        text :email
    end
end

init_model(Owner)

if DB[:owners].where(:name => 'nobody').empty?
    Owner.new(:name => 'nobody', :email => 'nobody@nowhere.com').save
end

