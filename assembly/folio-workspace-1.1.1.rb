# SPDX-License-Identifier: Apache-2.0
# Generated from reviewed release hashes; authentication never appears in this file.
require_relative "../lib/github_private_release_download_strategy"

class FolioWorkspace < Formula
  desc "Local planning workspace with optional Switchboard execution"
  homepage "https://github.com/qubicsdata/folio-releases"
  version "1.1.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-darwin-arm64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "e59cce3dbd38b2bfab0890a5a724d2ab0b2a4cd8f956ef7ae385812b593a0187"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-darwin-x64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "c5a97307f706fc1031af1ff70e8b811d47d47f1d8a9f3d504c56cc7259f92dec"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-linux-arm64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "c39de1c3744bf4a1c1245c8216a1e3299501aa911585f0da6e236255788aabca"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-linux-x64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "12acdd8006777986f48af69779d900d1da114f79afa7d0683ac9babe3a40c011"
    end
  end

  def install
    libexec.install Dir["*"]
    system libexec/"python/bin/python3", "-I", "-B", libexec/"install-folio-standalone.py",
           "--verify-only"
    bin.install_symlink libexec/"bin/folio", libexec/"bin/folio-server"
  end

  service do
    run [opt_bin/"folio-server"]
    environment_variables PATH: std_service_path_env
    keep_alive false
    working_dir var
    log_path var/"log/folio.log"
    error_log_path var/"log/folio.log"
  end

  test do
    system libexec/"python/bin/python3", "-I", "-B", libexec/"install-folio-standalone.py", "--verify-only"
    assert_match "folio 1.1.1", shell_output("#{bin}/folio --version")
    status = JSON.parse(shell_output("#{bin}/folio --data-dir #{testpath}/workspace status"))
    assert_equal true, status.fetch("ok")
    assert_equal "1.1.1", status.fetch("data").fetch("version")
    system bin/"folio", "--data-dir", testpath/"workspace", "init", testpath, "--client", "Homebrew test"
    assert_path_exists testpath/"workspace/registry.json"
    assert_path_exists testpath/".task-manager/project.json"
  end
end
