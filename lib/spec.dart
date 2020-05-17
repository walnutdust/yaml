import 'dart:io';

import 'mod.dart';

class Spec {
  dynamic yaml;

  Spec.load({String fileName}) : this(File(fileName).readAsStringSync());

  Spec([String yamlString = '']) {
    yaml = loadYaml(yamlString);
  }

  String dump() => yaml.toString();

  /// Upgrades a dependency to the new version constraint.
  void upgrade(String dependencyName, String versionConstraint,
      {bool dev = false}) {
    if (dev) {
      yaml['dev-dependencies'][dependencyName] = versionConstraint;
    } else {
      yaml['dependencies'][dependencyName] = versionConstraint;
    }
  }

  /// Removes a dependency from the file.
  void removeDependency(String dependencyName, {bool dev = false}) {
    if (dev) {
      yaml['dev-dependencies'].remove(dependencyName);
    } else {
      yaml['dependencies'].remove(dependencyName);
    }
  }

  /// Adds a dependency to the file.
  void addDependency(String dependencyName, String versionConstraint,
      {bool dev = false}) {
    if (dev) {
      yaml['dev-dependencies'][dependencyName] = versionConstraint;
    } else {
      yaml['dependencies'][dependencyName] = versionConstraint;
    }
  }

  /// Adds a git depedency to the file.
  void addGitDependency(String dependencyName, String url,
      {String ref = '', String path = '', bool dev = false}) {
    var params = {
      'git': {'url': url}
    };

    if (ref.isNotEmpty) params['git']['ref'] = ref;
    if (path.isNotEmpty) params['git']['path'] = path;

    if (dev) {
      yaml['dev-dependencies'][dependencyName] = params;
    } else {
      yaml['dependencies'][dependencyName] = params;
    }
  }

  void versionBumpMajor() => versionBump(Version.major);
  void versionBumpMinor() => versionBump(Version.minor);
  void versionBumpPatch() => versionBump(Version.patch);

  /// Updates the version on the pubspec file, assuming semantic versioning.
  /// Taken from https://semver.org/
  /// <valid semver> ::= <version core>
  ///                  | <version core> "-" <pre-release>
  ///                  | <version core> "+" <build>
  ///                  | <version core> "-" <pre-release> "+" <build>
  ///
  /// <version core> ::= <major> "." <minor> "." <patch>
  void versionBump(Version versionType) {
    var semver = yaml['version'].toString();
    var splitSemver = semver.split('+');
    var versionPreRelease = splitSemver[0].split('-');
    var semverPreRelease = versionPreRelease[0];

    var versions =
        semverPreRelease.split('.').map((e) => int.parse(e)).toList();

    if (versions.length < 3 ||
        versionPreRelease.length > 2 ||
        splitSemver.length > 2) {
      throw Exception('Versioning does not conform to semver');
    }

    switch (versionType) {
      case Version.major:
        versions[0]++;
        break;
      case Version.minor:
        versions[1]++;
        break;
      case Version.patch:
        versions[2]++;
        break;
    }

    var result = versions.join('.');

    if (versionPreRelease.length > 1) {
      result += '-${versionPreRelease[1]}';
    }

    if (splitSemver.length > 1) {
      result += '+${splitSemver[1]}';
    }

    yaml['version'] = result;
  }

  @override
  dynamic operator [](Object key) {
    return yaml[key];
  }

  @override
  void operator []=(key, value) {
    yaml[key] = value;
  }
}

/// The types of Version modifiers.
enum Version { major, minor, patch }
