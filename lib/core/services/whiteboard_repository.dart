import '../models/whiteboard/whiteboard_models.dart';
import '../storage/project_storage.dart';

class WhiteboardRepository {
  WhiteboardRepository(this._storage);

  final ProjectStorage _storage;

  WhiteboardDocument loadDocument() {
    return _storage.readWhiteboardDocument() ?? WhiteboardDocument.initial();
  }

  Future<void> saveDocument(WhiteboardDocument document) {
    return _storage.writeWhiteboardDocument(document);
  }
}
