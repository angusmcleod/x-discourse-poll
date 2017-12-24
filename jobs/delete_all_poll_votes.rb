module ::Jobs
  class DeleteAllPollVotes < Jobs::Base
    def execute(args)
      user = User.find(args[:user_id])
      poll_votes = user.poll_votes

      if poll_votes.any?
        voter_decrement = []

        poll_votes.each do |pv|

          ## remove votes
          votes_row = PostCustomField.find_by(name: 'polls-votes', post_id: pv[:post_id])
          votes = ::JSON.parse(votes_row.value)

          votes.delete(args[:user_id].to_s)

          votes_row.value = votes.to_json
          votes_row.save

          ## update poll counts
          polls_row = PostCustomField.find_by(name: 'polls', post_id: pv[:post_id])
          polls = ::JSON.parse(polls_row.value)

          polls[pv[:poll_id]]["options"].each do |op|
            if op["id"] === pv[:option_id]
              op["votes"] -= 1
            end
          end

          if !voter_decrement.include?("#{pv[:post_id]}_#{pv[:poll_id]}")
            # ensures that voter decrement only happens once for each poll
            polls[pv[:poll_id]]["voters"] -= 1
            voter_decrement.push("#{pv[:post_id]}_#{pv[:poll_id]}")
          end

          polls_row.value = polls.to_json
          polls_row.save
        end

        staff = User.find(args[:staff_user_id])
        StaffActionLogger.new(staff).log_poll_votes_deletion(poll_votes, user_id: user.id)
      end
    end
  end
end
