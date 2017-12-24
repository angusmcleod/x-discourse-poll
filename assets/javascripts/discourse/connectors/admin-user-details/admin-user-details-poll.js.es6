import { iconHTML } from 'discourse-common/lib/icon-library';
import { ajax } from 'discourse/lib/ajax';

export default {
  setupComponent(attrs) {
    this.set('user', attrs.model);
  },

  actions: {
    deleteAllPollVotes() {
      const user = this.get('user'),
            message = I18n.messageFormat('admin.user.delete_all_poll_votes_confirm_MF', { "VOTES": user.get('poll_votes_count') }),
            buttons = [{
              "label": I18n.t("composer.cancel"),
              "class": "d-modal-cancel",
              "link":  true
            }, {
              "label": `${iconHTML('exclamation-triangle')} ` + I18n.t("admin.user.delete_all_poll_votes"),
              "class": "btn btn-danger",
              "callback": function() {
                ajax("/admin/users/" + user.get('id') + "/delete_all_poll_votes", {
                  type: 'PUT'
                }).then(() => user.set('poll_votes_count', 0));
              }
            }];
      bootbox.dialog(message, buttons, { "classes": "delete-all-poll-votes" });
    },
  }
};
