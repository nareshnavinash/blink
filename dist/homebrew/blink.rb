cask "blink" do
  version "0.1.0"
  sha256 "" # TODO: fill after build

  url "https://github.com/blinkapp/blink/releases/download/v#{version}/Blink-#{version}-macos.dmg"
  name "Blink"
  desc "Smart break reminders for healthy screen habits"
  homepage "https://blinkapp.dev"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "blink_app.app", target: "Blink.app"

  zap trash: [
    "~/Library/Preferences/com.blinkapp.blink.plist",
    "~/Library/Application Support/com.blinkapp.blink",
  ]
end
