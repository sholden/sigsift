module Scanning
  module Tools
    class Goto < Base
      description "Navigate to a URL. Auto-waits for the DOM to be ready. " \
                  "Returns a brief confirmation; call get_text or get_links afterwards to inspect the page."

      param :url, type: :string, desc: "Absolute URL to navigate to", required: true

      def execute(url:)
        response = @session.page.goto(url, waitUntil: "domcontentloaded", timeout: 30_000)
        @session.navigation_breadcrumbs << "goto #{url}"
        status = response&.status || "unknown"
        content_type = (response&.headers || {})["content-type"].to_s

        if content_type.include?("application/pdf")
          return "navigated to a PDF (status=#{status}, content-type=#{content_type}). " \
                 "The DOM is not useful here — call get_pdf_text(url: \"#{url}\") to extract the document text."
        end

        if content_type.include?("application/vnd.openxmlformats-officedocument.wordprocessingml.document") ||
           content_type.include?("application/msword") ||
           url.downcase.end_with?(".docx", ".doc")
          return "navigated to a Word document (status=#{status}, content-type=#{content_type}). " \
                 "The DOM is not useful here — call get_docx_text(url: \"#{url}\") to extract the document text. " \
                 "Note: only .docx is supported, not legacy .doc binaries."
        end

        body_size = @session.page.content.length

        if body_size < 500 && @session.page.content.scan(/<script/i).count > 3
          "navigated (status=#{status}, body=#{body_size} chars). " \
          "Page looks like an unrendered SPA shell — heavy on script tags, light on content. " \
          "You may need to escalate if get_text yields nothing useful."
        else
          "navigated (status=#{status}, body=#{body_size} chars)"
        end
      rescue => e
        "navigation failed: #{e.message}"
      end
    end
  end
end
