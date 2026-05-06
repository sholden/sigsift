require "pdf-reader"
require "base64"
require "stringio"

module Scanning
  module Tools
    class GetPdfText < Base
      description <<~DESC
        Download a PDF and extract its text content. Use this whenever you encounter a PDF —
        most commonly when goto() lands on a URL whose response is application/pdf, or when
        get_links() surfaces a link to a PDF you want to read.

        Provide EITHER:
          - url: the URL to fetch (preferred — uses the same browser session, so cookies
                 and authentication carry over)
          - content_base64: raw PDF bytes encoded as base64 (rare — only useful if you've
                            obtained the bytes through some other mechanism)

        Optional pagination: pass start_page and end_page (1-indexed, inclusive) to read a
        specific section of a long PDF instead of the default first 20,000 chars from page 1.
        Returns extracted text, or an explanation if the PDF is scanned/image-only and
        text extraction yielded little — in which case escalate.
      DESC

      param :url, type: :string, desc: "URL to fetch and parse as a PDF", required: false
      param :content_base64, type: :string, desc: "Base64-encoded PDF bytes", required: false
      param :max_chars, type: :integer, desc: "Truncation limit for returned text (default 20000)", required: false
      param :start_page, type: :integer, desc: "First page to read (1-indexed)", required: false
      param :end_page, type: :integer, desc: "Last page to read (1-indexed, inclusive)", required: false

      def execute(url: nil, content_base64: nil, max_chars: 20_000, start_page: nil, end_page: nil)
        bytes = obtain_bytes(url: url, content_base64: content_base64)
        return bytes if bytes.is_a?(ErrorResult)

        unless bytes[0, 4] == "%PDF"
          return "URL did not return a PDF (first bytes: #{bytes[0, 16].inspect}). " \
                 "Use get_text() instead, or escalate."
        end

        reader = PDF::Reader.new(StringIO.new(bytes))
        pages = reader.pages
        sliced = slice_pages(pages, start_page, end_page)

        text = sliced.map.with_index do |page, idx|
          page_num = (start_page || 1) + idx
          "[page #{page_num}]\n#{(page.text || "").strip}"
        end.join("\n\n")

        if text.strip.length < 200
          "PDF appears scanned/image-only — text extraction yielded only #{text.strip.length} chars. " \
          "OCR is not supported in this version. Escalate if this PDF is the primary content."
        elsif text.length > (max_chars || 20_000)
          limit = (max_chars || 20_000).to_i.clamp(500, 100_000)
          remaining = text.length - limit
          "#{text[0, limit]}\n\n[truncated; #{remaining} more chars across #{pages.length} total pages. " \
          "Call again with start_page/end_page to read a specific section.]"
        else
          "[#{pages.length} pages, #{text.length} chars]\n\n#{text}"
        end
      rescue PDF::Reader::MalformedPDFError => e
        "PDF appears malformed: #{e.message}"
      rescue => e
        "get_pdf_text failed: #{e.class.name}: #{e.message}"
      end

      private

      ErrorResult = Class.new(String) # marker so #execute can short-circuit

      def obtain_bytes(url:, content_base64:)
        if url.present?
          fetch_via_browser_context(url)
        elsif content_base64.present?
          decoded = Base64.decode64(content_base64.to_s)
          decoded.empty? ? ErrorResult.new("content_base64 decoded to empty bytes") : decoded
        else
          ErrorResult.new("either url or content_base64 must be provided")
        end
      end

      def fetch_via_browser_context(url)
        return ErrorResult.new("no browser session available") unless @session&.page

        # Use the page's APIRequestContext so cookies/headers from the live session are reused.
        response = @session.page.context.request.get(url, timeout: 30_000)
        unless response.ok?
          return ErrorResult.new("fetch failed: HTTP #{response.status} #{response.status_text}")
        end
        response.body
      rescue => e
        ErrorResult.new("fetch failed: #{e.class.name}: #{e.message}")
      end

      def slice_pages(pages, start_page, end_page)
        first = (start_page || 1).to_i.clamp(1, pages.length)
        last  = (end_page || pages.length).to_i.clamp(first, pages.length)
        pages[(first - 1)..(last - 1)] || []
      end
    end
  end
end
