enum RawCaptureParseStatus {
  newCapture,
  parsed,
  reviewed,
  failed,
}

extension RawCaptureParseStatusCodec on RawCaptureParseStatus {
  String get storageValue {
    switch (this) {
      case RawCaptureParseStatus.newCapture:
        return 'new';
      case RawCaptureParseStatus.parsed:
        return 'parsed';
      case RawCaptureParseStatus.reviewed:
        return 'reviewed';
      case RawCaptureParseStatus.failed:
        return 'failed';
    }
  }
}

RawCaptureParseStatus rawCaptureParseStatusFromStorage(String value) {
  switch (value) {
    case 'parsed':
      return RawCaptureParseStatus.parsed;
    case 'reviewed':
      return RawCaptureParseStatus.reviewed;
    case 'failed':
      return RawCaptureParseStatus.failed;
    default:
      return RawCaptureParseStatus.newCapture;
  }
}