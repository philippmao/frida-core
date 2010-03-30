namespace Zed {
	public class View.Login : Object {
		public Gtk.Widget widget {
			get {
				return table;
			}
		}

		public Gtk.Entry username_entry {
			get;
			private set;
		}

		public Gtk.Entry password_entry {
			get;
			private set;
		}

		public Gtk.Button login_button {
			get;
			private set;
		}

		public bool login_in_progress {
			get {
				return (login_button.get_flags () & Gtk.WidgetFlags.SENSITIVE) != 0;
			}

			set {
				username_entry.sensitive = !value;
				password_entry.sensitive = !value;

				login_button.sensitive = !value;
			}
		}

		private Gtk.Table table;

		public Login () {
			try {
				var builder = new Gtk.Builder ();
				builder.add_from_string (Zed.Data.Ui.LOGIN_XML, -1);

				table = builder.get_object ("root_table") as Gtk.Table;

				username_entry = builder.get_object ("username_entry") as Gtk.Entry;
				password_entry = builder.get_object ("password_entry") as Gtk.Entry;
				password_entry.set_visibility (false);

				login_button = builder.get_object ("sign_in_button") as Gtk.Button;
			} catch (Error e) {
				warning (e.message);
			}
		}

		public void focus () {
			username_entry.grab_focus ();
			login_button.grab_default ();
		}
	}

	public class Presenter.Login : Object {
		public View.Login view {
			get;
			construct;
		}

		public Service.XmppClient client {
			private get;
			construct;
		}

		public Configuration configuration {
			private get;
			construct;
		}

		public signal void logged_in ();
		public signal void logged_out ();

		public Login (View.Login view, Service.XmppClient client, Configuration configuration) {
			Object (view: view, client: client, configuration: configuration);

			Configuration.Account? default_account = configuration.get_default_account ();
			if (default_account != null) {
				view.username_entry.text = default_account.name;
				view.password_entry.text = default_account.password;
			}

			connect_signals ();
		}

		private void connect_signals () {
			view.login_button.clicked.connect ((button) => {
				var jid = view.username_entry.text;
				var password = view.password_entry.text;

				if (jid != "") {
					view.login_in_progress = true;

					login (jid, password);
				}
			});

			client.notify["session"].connect (() => {
				if (client.session != null) {
					logged_in ();
				} else {
					view.login_in_progress = false;
					logged_out ();
				}
			});
		}

		private async void login (string jid, string password) {
			var succeeded = yield client.login (jid, password);
			if (succeeded) {
				var account = configuration.get_account (jid);
				account.password = password;
				configuration.set_default_account (account);
			}
		}
	}
}

