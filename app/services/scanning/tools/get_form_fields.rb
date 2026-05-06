module Scanning
  module Tools
    class GetFormFields < Base
      description "List input/select/textarea elements within a form, with their names, types, and current values. " \
                  "Use before fill() to learn what to populate."

      param :selector, type: :string, desc: "CSS selector for the form (default: 'form')", required: false

      def execute(selector: nil)
        scope = selector.presence || "form"

        fields = @session.page.evaluate(<<~JS, arg: { selector: scope })
          ({ selector }) => {
            const form = document.querySelector(selector);
            if (!form) return null;
            const out = [];
            form.querySelectorAll("input, select, textarea").forEach(el => {
              if (el.type === "hidden") return;
              out.push({
                tag: el.tagName.toLowerCase(),
                type: el.type || null,
                name: el.name || null,
                id: el.id || null,
                value: (el.value || "").slice(0, 200),
                placeholder: el.placeholder || null,
                required: el.required || false
              });
            });
            return out;
          }
        JS

        return "form not found at selector: #{scope}" if fields.nil?
        return "no visible fields in form" if fields.empty?

        fields.map do |f|
          parts = ["#{f["tag"]}"]
          parts << "type=#{f["type"]}" if f["type"]
          parts << "name=#{f["name"]}" if f["name"]
          parts << "id=#{f["id"]}" if f["id"] && f["name"].nil?
          parts << "value=#{f["value"].inspect}" if f["value"].present?
          parts << "placeholder=#{f["placeholder"].inspect}" if f["placeholder"]
          parts << "required" if f["required"]
          parts.join(" ")
        end.join("\n")
      rescue => e
        "get_form_fields failed: #{e.message}"
      end
    end
  end
end
