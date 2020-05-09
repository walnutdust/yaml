import 'dart:collection' as collection;
import 'dart:io';

import 'yaml.dart';

class Spec with collection.MapMixin {
  final YamlDocument _document;

  YamlMap contents;

  Spec.load({String fileName})
      : this(yamlString: File(fileName).readAsStringSync());

  Spec({String yamlString = ''}) : _document = loadYamlDocument(yamlString) {
    contents = (_document.contents as YamlMap);
  }

  /// Upgrades a dependency to the new version constraint.
  void upgrade(String dependencyName, String versionConstraint,
      {bool dev = false}) {
    if (dev) {
      contents['dev-dependencies'][dependencyName] = versionConstraint;
    } else {
      contents['dependencies'][dependencyName] = versionConstraint;
    }
  }

  /// Removes a dependency from the file.
  void removeDependency(String dependencyName, {bool dev = false}) {
    if (dev) {
      contents['dev-dependencies'].remove(dependencyName);
    } else {
      contents['dependencies'].remove(dependencyName);
    }
  }

  void addDependency(String dependencyName, String versionConstraint,
      {bool dev = false}) {
    if (dev) {
      contents['dev-dependencies'][dependencyName] = versionConstraint;
    } else {
      contents['dependencies'][dependencyName] = versionConstraint;
    }
  }

  void versionBumpMajor() => versionBump(Version.major);
  void versionBumpMinor() => versionBump(Version.minor);
  void versionBumpPatch() => versionBump(Version.patch);

  /// Updates the version on the pubsec file, assuming semantic versioning.
  /// https://semver.org/
  /// <valid semver> ::= <version core>
  ///                  | <version core> "-" <pre-release>
  ///                  | <version core> "+" <build>
  ///                  | <version core> "-" <pre-release> "+" <build>
  ///
  /// <version core> ::= <major> "." <minor> "." <patch>
  void versionBump(Version versionType) {
    if (!contents.containsKey('version')) {
      throw Exception('Unable to find version in document');
    }

    var semver = contents['version'].toString();
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

    contents['version'] = result;
  }

  String dump() {
    return _document.dump();
  }

  @override
  dynamic operator [](Object key) {
    return contents[key];
  }

  @override
  void operator []=(key, value) {
    contents[key] = value;
  }

  @override
  void clear() {
    contents.clear();
  }

  @override
  Iterable get keys => contents.keys;

  @override
  dynamic remove(Object key) {
    return contents.remove(key);
  }
}

/// The types of Version modifiers.
enum Version { major, minor, patch }
