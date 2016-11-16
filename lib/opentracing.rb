require "concurrent"
require "opentracing/version"
require "opentracing/span_context"
require "opentracing/span"
require "opentracing/nil_tracer"

module OpenTracing
  # Convert a time to microseconds
  def self.micros(time)
    (time.to_f * 1E6).floor
  end

  # Returns a random guid. Note: this intentionally does not use SecureRandom,
  # which is slower and cryptographically secure randomness is not required here.
  def self.guid
    @_rng ||= Random.new
    @_rng.bytes(8).unpack('H*')[0]
  end
end
