# SPDX-License-Identifier: Apache-2.0
# Copy to lib/github_private_release_download_strategy.rb in qubicsdata/homebrew-tap.
# Homebrew supports custom CurlDownloadStrategy classes through `using:`.
require "download_strategy"
require "utils/github"
require "uri"

class QubicsdataGitHubPrivateReleaseDownloadStrategy < CurlDownloadStrategy
  def initialize(url, name, version, **meta)
    match = %r{\Ahttps://github\.com/([A-Za-z0-9-]+)/([A-Za-z0-9._-]+)/releases/download/([A-Za-z0-9._-]+)/([A-Za-z0-9._-]+)\z}.match(url)
    raise CurlDownloadStrategyError.new(url, "Expected a GitHub release URL without credentials or query parameters.") unless match

    @owner, @repo, @tag, @filename = match.captures
    super
  end

  private

  # Avoid an unauthenticated HEAD request to the private browser download URL.
  # The normal Homebrew cache, locking and formula SHA-256 checks still apply.
  def resolve_url_basename_time_file_size(url, timeout: nil)
    [url, @filename, nil, nil, "application/octet-stream", false]
  end

  def _fetch(url:, resolved_url:, timeout:)
    token = GitHub::API.credentials
    if token.nil? || token.strip.empty? || token.match?(/[\r\n\x00]/)
      raise CurlDownloadStrategyError.new(url, "Authenticate with gh auth login or set HOMEBREW_GITHUB_API_TOKEN, with Contents: read access to #{@owner}/#{@repo}.")
    end

    release = GitHub::API.open_rest("https://api.github.com/repos/#{@owner}/#{@repo}/releases/tags/#{@tag}")
    assets = release.fetch("assets", []).select { |asset| asset["name"] == @filename && asset["state"] == "uploaded" }
    unless release["tag_name"] == @tag && assets.length == 1 && assets.first["id"].is_a?(Integer) && assets.first["id"].positive?
      raise CurlDownloadStrategyError.new(url, "The release does not contain exactly one uploaded asset named #{@filename}.")
    end

    # Authentication is a header, never part of a URL or persisted formula.
    # curl drops Authorization on cross-host redirects; do not use --location-trusted.
    # Homebrew redacts the token from diagnostic output via `secrets:`.
    curl_download "--header", "Accept: application/octet-stream",
                  "--header", "Authorization: Bearer #{token}",
                  "--proto", "=https", "--proto-redir", "=https",
                  "https://api.github.com/repos/#{@owner}/#{@repo}/releases/assets/#{assets.first.fetch('id')}",
                  to: temporary_path, timeout: timeout, secrets: [token]
  end
end
