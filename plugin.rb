# name: x-discourse-poll
# about: Extension of the Discourse Poll plugin
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/x-discourse-poll

after_initialize do
  class ::User
    def poll_votes
      @poll_votes ||= collect_poll_votes
    end

    def collect_poll_votes
      poll_votes = []
      PostCustomField.where(name: 'polls-votes').each do |pv|
        value = ::JSON.parse(pv.value)
        value.each do |user_id, votes|
          if user_id.to_i == self.id
            votes.each do |poll_id, options|
              options.each do |option_id|
                poll_votes.push(
                  post_id: pv.post_id,
                  poll_id: poll_id,
                  option_id: option_id
                )
              end
            end
          end
        end
      end
      poll_votes
    end

    def delete_all_poll_votes!(guardian)
      raise Discourse::InvalidAccess unless guardian.can_delete_all_poll_votes? self
      Jobs.enqueue(:delete_all_poll_votes, user_id: self.id, staff_user_id: guardian.user.id)
    end
  end

  require_dependency 'guardian'
  class ::Guardian
    def can_delete_all_poll_votes?(user)
      (is_admin? || is_staff? && SiteSetting.poll_allow_moderators_to_delete_votes) &&
      user &&
      !user.staff?
    end
  end

  load File.expand_path('../jobs/delete_all_poll_votes.rb', __FILE__)

  require_dependency 'admin_constraint'
  Discourse::Application.routes.append do
    namespace :admin, constraints: StaffConstraint.new do
      resources :users, id: RouteFormat.username do
        put "delete_all_poll_votes"
      end
    end
  end

  require_dependency 'admin/users_controller'
  class Admin::UsersController
    def delete_all_poll_votes
      @user = User.find_by(id: params[:user_id])
      @user.delete_all_poll_votes!(guardian)
      render body: nil
    end
  end

  UserHistory.actions[:delete_poll_votes] = 200
  UserHistory.staff_actions.push(:delete_poll_votes)

  require_dependency 'staff_action_logger'
  class ::StaffActionLogger
    def log_poll_votes_deletion(poll_votes, opts = {})
      raise Discourse::InvalidParameters.new(:poll_votes) unless poll_votes
      UserHistory.create(params(opts).merge(action: UserHistory.actions[:delete_poll_votes],
                                            target_user_id: opts[:user_id],
                                            details: poll_votes.join("\n")))
    end
  end

  add_to_serializer(:admin_detailed_user, :poll_votes_count) { object.poll_votes.count }
  add_to_serializer(:admin_detailed_user, :can_delete_all_poll_votes) { scope.can_delete_all_poll_votes?(object) }
end
