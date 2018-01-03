import { withPluginApi } from 'discourse/lib/plugin-api';

export default {
  name: 'x-discourse-poll-edits',
  initialize(container) {
    const user = container.lookup('current-user:main');

    if (user && user.staff) {
      withPluginApi('0.8.12', api => {
        api.modifyClass('model:admin-user', {
          deleteAllPollVotesExplanation: function() {
            if (!this.get('can_delete_all_poll_votes')) {
              if (this.get('deleteForbidden') && this.get('staff')) {
                return I18n.t('admin.user.delete_poll_votes_forbidden_because_staff');
              }
              if (!this.get('admin') && !Discourse.SiteSettings.poll_allow_moderators_to_delete_votes) {
                return I18n.t('admin.user.delete_poll_votes_admin_only');
              }
              return null;
            } else {
              return null;
            }
          }.property('can_delete_all_poll_votes', 'deleteForbidden'),
        });
      });
    }
  }
};
