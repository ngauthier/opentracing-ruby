module OpenTracing
  class NilTracer
    def enabled?
      true
    end

    def guid
      GUID
    end

    def finish_span(span)
    end

    private
    GUID = "nil_tracer_guid"
  end
end
