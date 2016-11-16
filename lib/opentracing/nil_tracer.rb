module OpenTracing
  class NilTracer
    GUID = "nil_tracer_guid"

    def enabled?
      true
    end

    def guid
      GUID
    end

    def start_span(operation_name, child_of: nil, start_time: nil, tags: nil)
    end

    def finish_span(span)
    end
  end
end
