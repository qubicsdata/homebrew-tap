# SPDX-License-Identifier: Apache-2.0
# Generated from reviewed release hashes; authentication never appears in this file.

class FolioWorkspace < Formula
  desc "Local planning workspace with optional Switchboard execution"
  homepage "https://github.com/qubicsdata/folio-releases"
  version "1.1.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.2/folio-1.1.2-darwin-arm64.tar.gz"
      sha256 "d446e69604ed1e3a3c09184f64c0fa94c93692dcc672d2b314582d0e9f42a830"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.2/folio-1.1.2-darwin-x64.tar.gz"
      sha256 "3203afb0109b18eaf2ee12b1454677ae99529535df5e567d92d0fc310eb2fb0a"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.2/folio-1.1.2-linux-arm64.tar.gz"
      sha256 "f337a030379383e293bb1dfa096d2b08997b46dab0d55b03c987bd305e6cccc0"
    end
    on_intel do
      url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.2/folio-1.1.2-linux-x64.tar.gz"
      sha256 "2487a35ae6e91b27d321545412dcae983e8c7e94fe6f5a008bc574c689dc38e8"
    end
  end

  bottle do
    root_url "https://github.com/qubicsdata/folio-releases/releases/download/v1.1.2"
    sha256 cellar: :any_skip_relocation, arm64_golden_gate: "76bbca090b036428584b83e61d9d07532a1d2ab20b4215f4ac258a92f3361177"
    sha256 cellar: :any_skip_relocation, golden_gate: "0c82ece74ba39ef5d2ed1d87ed77c6e03707e667b74fc24a65b265dd9b539f3a"
    sha256 cellar: :any_skip_relocation, arm64_linux: "719caf9f03931bcaffd24ad23e921622f55c6c278d46217ee7a37d797ce8d973"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "1e2689a9dedd482e196f6dc26b5e7c1337871d4c8795b8a5198a546327c1eaa5"
  end

  def install
    odie "No verified Homebrew bottle is available for this platform. Download the matching standalone archive from the GitHub release and use its installer."
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
    assert_match "folio 1.1.2", shell_output("#{bin}/folio --version")
    status = JSON.parse(shell_output("#{bin}/folio --data-dir #{testpath}/workspace status"))
    assert_equal true, status.fetch("ok")
    assert_equal "1.1.2", status.fetch("data").fetch("version")
    system bin/"folio", "--data-dir", testpath/"workspace", "init", testpath, "--client", "Homebrew test"
    assert_path_exists testpath/"workspace/registry.json"
    assert_path_exists testpath/".task-manager/project.json"
    # Exercise the installed owner-authenticated server, not just direct store mode.
    pid = spawn(bin/"folio-server", "--data-dir", (testpath/"workspace").to_s,
                "--port", "0", "--no-sync", out: File::NULL, err: File::NULL)
    begin
      discovery = testpath/"workspace/.server.json"
      100.times do
        break if discovery.exist?
        sleep 0.1
      end
      assert_path_exists discovery
      auth_check = <<~PY
        import json,sys
        from pathlib import Path
        from urllib.request import Request,urlopen
        from urllib.error import HTTPError
        path=Path(sys.argv[1])
        assert path.stat().st_mode & 0o777 == 0o600
        info=json.loads(path.read_text())
        url='http://127.0.0.1:'+str(info['port'])+'/api/state'
        try:
            urlopen(url,timeout=5)
        except HTTPError as error:
            assert error.code == 403
        else:
            raise AssertionError('Local API must require owner authentication')
        with urlopen(Request(url,headers={'X-Workspace-Token':info['owner_token']}),timeout=5) as response:
            state=json.load(response)
            assert 'token' not in state and info['owner_token'] not in json.dumps(state)
      PY
      system libexec/"python/bin/python3", "-I", "-B", "-c", auth_check, discovery.to_s
      system bin/"folio", "--data-dir", testpath/"workspace", "server-stop"
    ensure
      Process.kill("TERM", pid) rescue Errno::ESRCH
      Process.wait(pid) rescue Errno::ECHILD
    end
  end
end
