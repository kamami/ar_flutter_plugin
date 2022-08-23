// automatically generated by the FlatBuffers compiler, do not modify

package com.google.ar.sceneform.lullmodel;

import java.nio.*;

import java.util.*;
import com.google.flatbuffers.*;

@SuppressWarnings("unused")
/**
 * The range of indices associated with a single draw call.
 */
public final class ModelIndexRange extends Struct {
  public void __init(int _i, ByteBuffer _bb) { bb_pos = _i; bb = _bb; }
  public ModelIndexRange __assign(int _i, ByteBuffer _bb) { __init(_i, _bb); return this; }

  public long start() { return (long)bb.getInt(bb_pos + 0) & 0xFFFFFFFFL; }
  public long end() { return (long)bb.getInt(bb_pos + 4) & 0xFFFFFFFFL; }

  public static int createModelIndexRange(FlatBufferBuilder builder, long start, long end) {
    builder.prep(4, 8);
    builder.putInt((int)end);
    builder.putInt((int)start);
    return builder.offset();
  }
}

