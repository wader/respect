require 'formula'

class Respect < Formula
  head 'https://github.com/path/to/respect.git', :branch => 'master'
  homepage 'https://github.com/path/to/respect'

  def install
    system "xcodebuild", "-project", "Respect.xcodeproj",
                         "-target", "Respect",
                         "-configuration", "Release",
                         "install",
                         "SYMROOT=build",
                         "DSTROOT=build",
                         "INSTALL_PATH=/bin"
    bin.install "build/bin/Respect"
  end
end
