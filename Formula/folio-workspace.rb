# SPDX-License-Identifier: Apache-2.0
# Generated from reviewed release hashes; authentication never appears in this file.

class FolioWorkspace < Formula
  desc "Local planning workspace with optional Switchboard execution"
  homepage "https://github.com/qubicsdata/folio-releases"
  version "1.1.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-darwin-arm64.tar.gz"
      sha256 "e59cce3dbd38b2bfab0890a5a724d2ab0b2a4cd8f956ef7ae385812b593a0187"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-darwin-x64.tar.gz"
      sha256 "c5a97307f706fc1031af1ff70e8b811d47d47f1d8a9f3d504c56cc7259f92dec"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-linux-arm64.tar.gz"
      sha256 "c39de1c3744bf4a1c1245c8216a1e3299501aa911585f0da6e236255788aabca"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1/folio-1.1.1-linux-x64.tar.gz"
      sha256 "12acdd8006777986f48af69779d900d1da114f79afa7d0683ac9babe3a40c011"
    end
  end

  bottle do
    root_url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.1"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "240b73e607353e7d090b15e262977069f60169c1a46b2dca0cbaec58b953717d"
    sha256 cellar: :any_skip_relocation, arm64_linux: "a21642369eeeced21fa9814424a3bda43b297ffcbf98f56a6cef34c5e6f5a0f1"
    sha256 cellar: :any_skip_relocation, golden_gate: "211e699f9d1e56c4cd23e58e9b4c6adbabc7415c6fdbaa41397f606c3010481b"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "cb7ea32dd52d70c8d3683fc07143f709323d0bfafd003746446e873ddaa89ea3"
  end

  def install
    odie "No verified Homebrew bottle is available for this platform. Download the matching standalone archive from the private GitHub release and use its installer."
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
