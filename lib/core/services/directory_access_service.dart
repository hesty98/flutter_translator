import 'dart:async';
import 'dart:io';

import 'package:macos_secure_bookmarks/macos_secure_bookmarks.dart';

import '../models/project_record.dart';

class DirectoryAccessService {
  DirectoryAccessService() : _secureBookmarks = SecureBookmarks();

  final SecureBookmarks _secureBookmarks;

  bool get _supportsSecurityScopedBookmarks => Platform.isMacOS;

  Future<ProjectRecord> prepareProject(ProjectRecord project) async {
    if (!_supportsSecurityScopedBookmarks) {
      return project.copyWith(clearDirectoryBookmark: true);
    }

    if (project.directoryBookmark != null &&
        project.directoryBookmark!.isNotEmpty) {
      return project;
    }

    throw StateError(
      'No macOS bookmark stored for "${project.directoryPath}". '
      'Choose the folder with the folder picker to grant sandbox access.',
    );
  }

  Future<T> withProjectDirectoryAccess<T>(
    ProjectRecord project,
    Future<T> Function(Directory directory) action,
  ) async {
    try {
      if (_supportsSecurityScopedBookmarks &&
          project.directoryBookmark == null) {
        throw StateError(
          'No macOS bookmark stored for "${project.directoryPath}". '
          'Re-select the project folder in the editor to grant access.',
        );
      }

      final directory = await _resolveDirectory(project);
      var accessStarted = false;

      if (_supportsSecurityScopedBookmarks &&
          project.directoryBookmark != null) {
        accessStarted = await _secureBookmarks
            .startAccessingSecurityScopedResource(directory);
        if (!accessStarted) {
          throw StateError(
            'macOS denied security-scoped access for "${project.directoryPath}". '
            'Re-select the project folder in the editor to refresh access.',
          );
        }
      }

      try {
        return await action(directory);
      } finally {
        if (accessStarted) {
          await _secureBookmarks.stopAccessingSecurityScopedResource(directory);
        }
      }
    } on PathAccessException catch (error) {
      throw StateError(
        'Directory access denied for "${project.directoryPath}". '
        'Re-select the project folder in the editor to grant macOS access. '
        'Original error: $error',
      );
    }
  }

  Future<Directory> _resolveDirectory(ProjectRecord project) async {
    if (!_supportsSecurityScopedBookmarks ||
        project.directoryBookmark == null) {
      return Directory(project.directoryPath);
    }

    final entity = await _secureBookmarks.resolveBookmark(
      project.directoryBookmark!,
      isDirectory: true,
    );
    if (entity is Directory) {
      return entity;
    }
    return Directory(entity.path);
  }
}
