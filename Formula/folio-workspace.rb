# SPDX-License-Identifier: Apache-2.0
# Generated from reviewed release hashes; authentication never appears in this file.
require_relative "../lib/github_private_release_download_strategy"

class FolioWorkspace < Formula
  desc "Local planning workspace with optional Switchboard execution"
  homepage "https://github.com/qubicsdata/folio-distribution"
  version "1.1.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/qubicsdata/folio-distribution/releases/download/v1.1.0/folio-1.1.0-darwin-arm64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "9d5c753c2055ecdcacd0d8a490c130f8874aff516d61c111187445d643341470"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-distribution/releases/download/v1.1.0/folio-1.1.0-darwin-x64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "b4697c89fa283d0370ae0075be035782f03d5bf92d8337b0aa81616a2453d1b0"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/qubicsdata/folio-distribution/releases/download/v1.1.0/folio-1.1.0-linux-arm64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "2b81e2a501497fe2c7fbcb28a701faf2fca0015b5351a434bf0680e461cc0064"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-distribution/releases/download/v1.1.0/folio-1.1.0-linux-x64.tar.gz", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
      sha256 "84a10d68dcdc09e6b633c7e1b861c9a2b96043334b020ea236e095ea0be189b5"
    end
  end

  bottle do
    root_url "https://github.com/qubicsdata/folio-distribution/releases/download/v1.1.0", using: QubicsdataGitHubPrivateReleaseDownloadStrategy
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "74257045ae1f30b07c4056d9e98a0c7b28756732966845728cebcc59b82dddd1"
    sha256 cellar: :any_skip_relocation, golden_gate: "3f2a19232adb2033e4b1290cfaa743494180402fbe0efc81ad843f839c12e8ce"
    sha256 cellar: :any_skip_relocation, arm64_linux: "6d31c94aabb5095cad8b9116e0d8a50a98d66636ba1f526dddc5293341a03118"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "5ae0931a27af575197c22b6c10404941d1c406021ae8c35edd855c147a944fa5"
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
    assert_match "folio 1.1.0", shell_output("#{bin}/folio --version")
    status = JSON.parse(shell_output("#{bin}/folio --data-dir #{testpath}/workspace status"))
    assert_equal true, status.fetch("ok")
    assert_equal "1.1.0", status.fetch("data").fetch("version")
    system bin/"folio", "--data-dir", testpath/"workspace", "init", testpath, "--client", "Homebrew test"
    assert_path_exists testpath/"workspace/registry.json"
    assert_path_exists testpath/".task-manager/project.json"
  end
end
