# Plainday for iPhone

This is Plainday as a real iPhone app: the same pastel dashboard you use on claude.ai, plus things only an app can do:

- **Notifications:** reminders and events with a date buzz your phone at their time. Reminders with no time go off at 9:00 AM, and all-day events at 8:00 AM.
- **Widgets:** Home Screen widgets (small, medium and large) and Lock Screen widgets (under the clock, a circle, or a line of text next to the date).
- **Photos as stickers:** "Add your own" opens your photo library or camera.

Everything is saved on your phone. The app doesn't sync with the claude.ai version.

---

## Share it as a website (easiest way for friends to try it)

The `docs` folder is Plainday as its own website. GitHub Pages hosts it free, and friends just open a link. On iPhone they can tap **Share → Add to Home Screen** to get the Plainday icon, and it opens full-screen like an app.

1. Upload this whole folder to a **public** GitHub repository named `plainday` (see Option A, step 1 below). Free GitHub Pages only works on public repos.
2. In the repo, open **Settings → Pages**.
3. Under **Build and deployment**, set **Source** to *Deploy from a branch*. Pick branch **main** and folder **/docs**, then click **Save**.
4. Wait a minute or two and refresh. GitHub shows your link at the top of the Pages screen, something like `https://yourname.github.io/plainday/`.
5. Send that link to your friends.

Each friend's lists are saved on their own phone or computer, and nobody can see anyone else's. To update the site, replace `docs/index.html` in the repo; friends get the new version next time they open it.

---

## Option A: from a Windows PC (no Mac needed)

Windows can't run Apple's Xcode, so GitHub builds the app for you on one of its Macs. Then a free Windows tool called Sideloadly puts it on your iPhone.

### 1. Let GitHub build the app

1. Create a free account at **github.com**.
2. Click **+ → New repository**. Name it `plainday` and click **Create repository**. Public is free with no limits. Private works too but uses up your free build minutes faster.
3. On the new repo page, click **uploading an existing file**. Unzip this folder and drag **everything inside the `Plainday` folder** into the browser. That includes the `.github` folder, `Plainday.xcodeproj`, `Plainday` and `PlaindayWidget`. Click **Commit changes**.
   - The `.github` folder must be included. If your browser skipped it, upload `.github/workflows/build-ios.yml` on its own with **Add file → Create new file**, naming it exactly `.github/workflows/build-ios.yml` and pasting its contents.
4. Open the **Actions** tab. Choose **Build iPhone app**, then **Run workflow**. It takes about 5–10 minutes.
5. When it shows a green check, open the run and download **Plainday-ipa** at the bottom. Unzip it to get `Plainday.ipa`.

### 2. Put it on your iPhone with Sideloadly

1. Install **iTunes for Windows from apple.com**. Sideloadly needs Apple's version, not the Microsoft Store one. Then install **Sideloadly** from sideloadly.io.
2. Plug in your iPhone and tap **Trust** on the phone.
3. Open Sideloadly. Drag `Plainday.ipa` onto it, type your Apple ID and click **Start**. Sideloadly signs the app with your Apple ID; the password goes to Apple, not to Sideloadly.
4. On the iPhone, open **Settings → Privacy & Security → Developer Mode**, turn it on, and restart.
5. Open **Settings → General → VPN & Device Management**, tap your Apple ID and choose **Trust**.
6. Open Plainday and allow notifications.

With a free Apple ID the app stops opening after **7 days**. Plug in and press Start in Sideloadly again to renew it; your data stays. A free Apple ID can also only have 3 sideloaded apps at a time.

If Sideloadly fails because of the widget, look in its advanced options for a setting that removes app extensions, and try again. The app works without the widget.

---

## Option B: with a Mac

1. Install **Xcode** from the Mac App Store, then double-click **Plainday.xcodeproj**.
2. Click the blue **Plainday** icon in the sidebar, then **Build Settings**. Search for `BASE_BUNDLE_ID` and change `com.yourname.plainday` to something only you would use, like `com.jasmine.plainday`. Change it only here: the widget and the shared storage use it automatically.
3. For **each** target (Plainday and PlaindayWidget), go to **Signing & Capabilities → Team**, choose **Add an Account…**, sign in, and pick your team.
4. Plug in your iPhone, turn on **Developer Mode** (see Option A, step 2.4), pick your phone in Xcode's top bar and press **▶ Run**.
5. The first time, trust your Apple ID on the phone in **Settings → General → VPN & Device Management**.

If Xcode says your team **doesn't support App Groups**, you're on a free account. In both targets, remove the **App Groups** capability with the small ✕ under Signing & Capabilities. The app will run, but widgets will just say "Open Plainday" (see below).

---

## Adding the widgets

**Home Screen:** long-press an empty spot, tap **Edit → Add Widget**, search for **Plainday**, and choose small, medium or large.

**Lock Screen:** long-press the Lock Screen, tap **Customize → Lock Screen**, then tap the widget area under the clock (or the date line above it) and pick **Plainday**.

Each widget shows today's date, how many tasks are done, your next event and your reminders. It updates whenever you change something in the app, and on its own about every 30 minutes.

**Widgets need the paid Apple Developer Program ($99/year) to show your data.** The widget reads your day through an "App Group", which is shared storage between the app and the widget. Apple doesn't fully support App Groups on free accounts or sideloaded apps, so on a free setup the widget installs but shows "Open Plainday" instead of your tasks. The paid account also gives you **TestFlight**, which lets you and friends install Plainday with a link, renews every 90 days instead of every 7, and is the path to the App Store. From Windows, the GitHub workflow can later be extended to upload to TestFlight directly.

---

## Updating the app

The whole interface is `Plainday/index.html` (and `docs/index.html` for the website). Replace it with a newer version, then either upload it to GitHub again (it rebuilds automatically) or press Run in Xcode.

## What's in the folder

| File | What it does |
|---|---|
| `Plainday/index.html` | The app's whole interface |
| `Plainday/PlaindayApp.swift` | Starts the app and asks for notification permission |
| `Plainday/WebView.swift` | Shows the page full-screen |
| `Plainday/Native.swift` | Saves your data, schedules notifications, feeds the widgets |
| `PlaindayWidget/PlaindayWidget.swift` | The Home Screen and Lock Screen widgets |
| `.github/workflows/build-ios.yml` | Lets GitHub build the app for you (for Windows) |
| `Plainday/Assets.xcassets` | App icon |
| `docs/` | The website version for GitHub Pages |
