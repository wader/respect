require 'formula'

class Respect < Formula
  head 'https://github.com/wader/respect.git', :branch => 'master'
  homepage 'https://github.com/wader/respect'

  def install
    system "xcodebuild", "-project", "Respect.xcodeproj",
                         "-target", "respect",
                         "-configuration", "Release",
                         "install",
                         "SYMROOT=build",
                         "DSTROOT=build",
                         "INSTALL_PATH=/bin"
    bin.install "build/bin/respect"
  end
end
