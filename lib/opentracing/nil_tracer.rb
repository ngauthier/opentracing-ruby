module OpenTracing
  class NilTracer
    GUID = "nil_tracer_guid"

    def enabled?
      true
    end

    def guid
      GUID
    end

    def finish_span(span)
    end
  end
end
