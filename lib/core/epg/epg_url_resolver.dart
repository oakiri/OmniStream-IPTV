class EpgUrlResolver {
  /// Derives Xtream XMLTV URL from a typical M3U get.php URL.
  ///
  /// Example:
  ///   https://host:port/get.php?username=...&password=...&type=m3u_plus&output=ts
  /// -> https://host:port/xmltv.php?username=...&password=...
  ///
  /// Returns null if the playlistUrl isn't a get.php URL.
  static Uri? deriveXtreamXmltv(String playlistUrl) {
    final raw = playlistUrl.trim();
    if (raw.isEmpty) return null;

    final uri = Uri.tryParse(raw);
    if (uri == null) return null;

    final path = uri.path;
    if (!path.contains('get.php')) return null;

    // Replace last segment get.php with xmltv.php (keeping query params).
    final newPath = path.replaceAll('get.php', 'xmltv.php');

    // Some providers require only username/password; but keeping extra params does not usually break.
    // Still, we keep the same query to be safe.
    return uri.replace(path: newPath);
  }
}
