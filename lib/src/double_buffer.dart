class DoubleBuffer {
  StringBuffer processed = StringBuffer();
  StringBuffer raw = StringBuffer();

  DoubleBuffer();

  void writeCharCode(int processedCode, [int rawCode]) {
    processed.writeCharCode(processedCode);
    if (rawCode == null) {
      raw.writeCharCode(processedCode);
    } else {
      raw.writeCharCode(rawCode);
    }
  }

  void write(Object processedObject, [Object rawObject]) {
    processed.write(processedObject);
    if (rawObject == null) {
      raw.write(processedObject);
    } else {
      raw.write(rawObject);
    }
  }
}
