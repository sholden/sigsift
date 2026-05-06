require "docx"
require "base64"
require "stringio"

module Scanning
  module Tools
    class GetDocxText < Base
      description <<~DESC
        Download a Microsoft Word (.docx) document and extract its text content. Use this whenever
        you encounter a Word document — most commonly when goto() lands on a URL whose response is
        a .docx file, or when get_links() surfaces a link to one.

        Provide EITHER:
          - url: the URL to fetch (preferred — uses the same browser session, so cookies and
                 authentication carry over)
          - content_base64: raw .docx bytes encoded as base64 (rare — only useful if you've
                            obtained the bytes through some other mechanism)

        Returns the document's body text, paragraphs separated by blank lines. Truncates at
        max_chars (default 20,000) — if the document is larger, the tool reports how much was
        cut and you can re-call later sections via the start_paragraph / end_paragraph params.

        Note: This tool does NOT extract from .doc (legacy Word 97-2003 binary format). Only
        .docx is supported. If you encounter a .doc, escalate.
      DESC

      param :url, type: :string, desc: "URL to fetch and parse as a .docx", required: false
      param :content_base64, type: :string, desc: "Base64-encoded .docx bytes", required: false
      param :max_chars, type: :integer, desc: "Truncation limit for returned text (default 20000)", required: false
      param :start_paragraph, type: :integer, desc: "First paragraph to read (1-indexed)", required: false
      param :end_paragraph, type: :integer, desc: "Last paragraph to read (1-indexed, inclusive)", required: false

      def execute(url: nil, content_base64: nil, max_chars: 20_000, start_paragraph: nil, end_paragraph: nil)
        bytes = obtain_bytes(url: url, content_base64: content_base64)
        return bytes if bytes.is_a?(ErrorResult)

        unless looks_like_docx?(bytes)
          return "URL did not return a .docx file (first bytes: #{bytes[0, 16].inspect}). " \
                 "Use get_text() for HTML, get_pdf_text() for PDFs, or escalate."
        end

        doc = Docx::Document.new(StringIO.new(bytes))
        all_paragraphs = doc.paragraphs.map(&:to_s)
        sliced = slice_paragraphs(all_paragraphs, start_paragraph, end_paragraph)

        text = sliced.reject(&:empty?).join("\n\n")
        return "DOCX appears to have no extractable text (#{all_paragraphs.length} paragraphs, all empty)." if text.strip.empty?

        limit = (max_chars || 20_000).to_i.clamp(500, 100_000)
        if text.length > limit
          remaining = text.length - limit
          "[#{all_paragraphs.length} total paragraphs, #{text.length} chars in selected range]\n\n" \
          "#{text[0, limit]}\n\n[truncated; #{remaining} more chars. " \
          "Call again with start_paragraph/end_paragraph to read a specific section.]"
        else
          "[#{all_paragraphs.length} paragraphs, #{text.length} chars]\n\n#{text}"
        end
      rescue => e
        "get_docx_text failed: #{e.class.name}: #{e.message}"
      end

      private

      ErrorResult = Class.new(String)

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

        response = @session.page.context.request.get(url, timeout: 30_000)
        unless response.ok?
          return ErrorResult.new("fetch failed: HTTP #{response.status} #{response.status_text}")
        end
        response.body
      rescue => e
        ErrorResult.new("fetch failed: #{e.class.name}: #{e.message}")
      end

      # .docx files are ZIP archives — they start with the ZIP local-file-header magic "PK\x03\x04".
      def looks_like_docx?(bytes)
        bytes[0, 4] == "PK\x03\x04".b
      end

      def slice_paragraphs(paragraphs, start_idx, end_idx)
        return paragraphs if start_idx.nil? && end_idx.nil?
        first = (start_idx || 1).to_i.clamp(1, paragraphs.length)
        last  = (end_idx || paragraphs.length).to_i.clamp(first, paragraphs.length)
        paragraphs[(first - 1)..(last - 1)] || []
      end
    end
  end
end
