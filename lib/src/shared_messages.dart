import 'dart:typed_data';

import 'package:buffer/buffer.dart';

import 'package:postgres/src/client_messages.dart';
import 'package:postgres/src/server_messages.dart';

/// An abstraction for all client and server replication messages
///
/// For more details, see [Streaming Replication Protocol][]
///
/// [Streaming Replication Protocol]: https://www.postgresql.org/docs/current/protocol-replication.html
abstract class ReplicationMessage {
  static const int primaryKeepAliveIdentifier = 107; // k
  static const int xLogDataIdentifier = 119; // w
  static const int hotStandbyFeedbackIdentifier = 104; // h
  static const int standbyStatusUpdateIdentifier = 114; // r
}

/// Messages that are shared between both the server and the client
///
/// For more details, see [Message Formats][]
///
/// [Message Formats]: https://www.postgresql.org/docs/current/protocol-message-formats.html
abstract class SharedMessages extends ClientMessage implements ServerMessage {
  static const int copyDoneIdentifier = 99; // c
  static const int copyDataIdentifier = 100; // d
}

/// A COPY data message.
class CopyDataMessage extends SharedMessages {
  /// Data that forms part of a COPY data stream. Messages sent from the backend
  /// will always correspond to single data rows, but messages sent by frontends
  /// might divide the data stream arbitrarily.
  final Uint8List bytes;

  /// Length of message contents in bytes, including self (i.e. int32).
  int get length => bytes.length + 4;

  CopyDataMessage(this.bytes);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(SharedMessages.copyDataIdentifier);
    buffer.writeInt32(length);
    buffer.write(bytes);
  }
}

/// A COPY-complete indicator.
class CopyDoneMessage extends SharedMessages {
  ///  Length of message contents in bytes, including self.
  late final int length;

  CopyDoneMessage(this.length);

  @override
  void applyToBuffer(ByteDataWriter buffer) {
    buffer.writeUint8(SharedMessages.copyDoneIdentifier);
    buffer.writeInt32(length);
  }
}
