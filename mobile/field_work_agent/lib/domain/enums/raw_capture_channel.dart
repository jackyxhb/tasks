enum RawCaptureChannel {
  manualText,
  wechatText,
  smsText,
  audio,
  manualForm,
  unknown,
}

extension RawCaptureChannelCodec on RawCaptureChannel {
  String get storageValue {
    switch (this) {
      case RawCaptureChannel.manualText:
        return 'manual_text';
      case RawCaptureChannel.wechatText:
        return 'wechat_text';
      case RawCaptureChannel.smsText:
        return 'sms_text';
      case RawCaptureChannel.audio:
        return 'audio';
      case RawCaptureChannel.manualForm:
        return 'manual_form';
      case RawCaptureChannel.unknown:
        return 'unknown';
    }
  }
}

RawCaptureChannel rawCaptureChannelFromStorage(String value) {
  for (final channel in RawCaptureChannel.values) {
    if (channel.storageValue == value) {
      return channel;
    }
  }
  return RawCaptureChannel.unknown;
}