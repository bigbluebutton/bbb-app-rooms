
class LocalUser
   @@no_of_users = 0

   def initialize(id, full_name = '', first_name = '', last_name = '', roles = [])
      @user_id = id
      @user_full_name = full_name
      @user_first_name = first_name
      @user_last_name = last_name
      @user_roles = roles
   end

   def id
     @user_id
   end

   def full_name
     @user_full_name
   end

   def first_name
     @user_first_name
   end

   def last_name
     @user_last_name
   end

   def roles
     @user_roles
   end

   def role?(role)
     @user_roles.each do |user_role|
       return true if user_role.match(/#{role}/i)
     end
     false
   end

end
